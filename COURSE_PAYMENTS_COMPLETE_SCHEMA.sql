-- ===============================================
-- COURSE PAYMENTS COMPLETE SCHEMA
-- Sistem complet de plăți cursuri cu multiple metode
-- ===============================================

-- 1. Tabelă pentru plăți cursuri
CREATE TABLE IF NOT EXISTS public.course_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    method TEXT CHECK (method IN ('cash', 'wallet', 'revolut', 'rate')),
    authorized BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'partial', 'authorized', 'declined')),
    amount NUMERIC(10,2),
    proof_url TEXT,
    admin_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    authorized_by UUID REFERENCES public.profiles(id),
    authorized_at TIMESTAMP WITH TIME ZONE
);

-- 2. Tabelă pentru notificări
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    read BOOLEAN DEFAULT false,
    type TEXT DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error')),
    metadata JSONB,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- 3. Adaugă coloane lipsă la courses dacă nu există
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'price') THEN
        ALTER TABLE public.courses ADD COLUMN price NUMERIC(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'max_participants') THEN
        ALTER TABLE public.courses ADD COLUMN max_participants INTEGER DEFAULT 20;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'current_participants') THEN
        ALTER TABLE public.courses ADD COLUMN current_participants INTEGER DEFAULT 0;
    END IF;
END $$;

-- 4. Adaugă coloane lipsă la enrollments dacă nu există
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'enrollments' AND column_name = 'payment_method') THEN
        ALTER TABLE public.enrollments ADD COLUMN payment_method TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'enrollments' AND column_name = 'payment_status') THEN
        ALTER TABLE public.enrollments ADD COLUMN payment_status TEXT DEFAULT 'pending';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'enrollments' AND column_name = 'created_at') THEN
        ALTER TABLE public.enrollments ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 5. Indexuri pentru performanță
CREATE INDEX IF NOT EXISTS idx_course_payments_user_id ON public.course_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_course_payments_course_id ON public.course_payments(course_id);
CREATE INDEX IF NOT EXISTS idx_course_payments_status ON public.course_payments(status);
CREATE INDEX IF NOT EXISTS idx_course_payments_method ON public.course_payments(method);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);

-- 6. RLS Policies pentru course_payments
ALTER TABLE public.course_payments ENABLE ROW LEVEL SECURITY;

-- Users pot vedea doar propriile plăți
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_payments' AND policyname = 'Users can view own payments') THEN
        CREATE POLICY "Users can view own payments" ON public.course_payments
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

-- Users pot crea propriile plăți
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_payments' AND policyname = 'Users can create own payments') THEN
        CREATE POLICY "Users can create own payments" ON public.course_payments
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- Admins pot vedea toate plățile
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_payments' AND policyname = 'Admins can view all payments') THEN
        CREATE POLICY "Admins can view all payments" ON public.course_payments
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND (role = 'admin' OR role = 'instructor')
                )
            );
    END IF;
END $$;

-- Admins pot actualiza toate plățile
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_payments' AND policyname = 'Admins can update all payments') THEN
        CREATE POLICY "Admins can update all payments" ON public.course_payments
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND (role = 'admin' OR role = 'instructor')
                )
            );
    END IF;
END $$;

-- 7. RLS Policies pentru notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users pot vedea doar propriile notificări
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can view own notifications') THEN
        CREATE POLICY "Users can view own notifications" ON public.notifications
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

-- Users pot actualiza propriile notificări (mark as read)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can update own notifications') THEN
        CREATE POLICY "Users can update own notifications" ON public.notifications
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Admins pot crea notificări pentru oricine
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Admins can create notifications') THEN
        CREATE POLICY "Admins can create notifications" ON public.notifications
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND (role = 'admin' OR role = 'instructor')
                )
            );
    END IF;
END $$;

-- 8. Funcție pentru actualizarea updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 9. Trigger pentru updated_at pe course_payments
DROP TRIGGER IF EXISTS update_course_payments_updated_at ON public.course_payments;
CREATE TRIGGER update_course_payments_updated_at
    BEFORE UPDATE ON public.course_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 10. Funcție pentru crearea notificărilor automate
CREATE OR REPLACE FUNCTION create_enrollment_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Notificare pentru înscriere
    INSERT INTO public.notifications (user_id, title, body, type, metadata)
    VALUES (
        NEW.user_id,
        'Înscriere confirmată',
        'Ai fost înscris cu succes la cursul selectat.',
        'success',
        jsonb_build_object('course_id', NEW.course_id, 'enrollment_id', NEW.id)
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. Trigger pentru notificări la înscriere
DROP TRIGGER IF EXISTS enrollment_notification_trigger ON public.enrollments;
CREATE TRIGGER enrollment_notification_trigger
    AFTER INSERT ON public.enrollments
    FOR EACH ROW
    EXECUTE FUNCTION create_enrollment_notification();

-- 12. Funcție pentru notificări la autorizarea plăților în rate
CREATE OR REPLACE FUNCTION create_payment_authorization_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifică dacă s-a schimbat statusul de autorizare pentru plata în rate
    IF NEW.method = 'rate' AND NEW.authorized = true AND (OLD.authorized = false OR OLD.authorized IS NULL) THEN
        INSERT INTO public.notifications (user_id, title, body, type, metadata)
        VALUES (
            NEW.user_id,
            'Plată în rate aprobată',
            'Plata ta în rate a fost aprobată de administrator.',
            'success',
            jsonb_build_object('payment_id', NEW.id, 'course_id', NEW.course_id)
        );
    END IF;
    
    -- Verifică dacă plata a fost marcată ca plătită
    IF NEW.status = 'paid' AND OLD.status != 'paid' THEN
        INSERT INTO public.notifications (user_id, title, body, type, metadata)
        VALUES (
            NEW.user_id,
            'Plată confirmată',
            'Plata ta a fost confirmată cu succes.',
            'success',
            jsonb_build_object('payment_id', NEW.id, 'course_id', NEW.course_id, 'method', NEW.method)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 13. Trigger pentru notificări la actualizarea plăților
DROP TRIGGER IF EXISTS payment_authorization_notification_trigger ON public.course_payments;
CREATE TRIGGER payment_authorization_notification_trigger
    AFTER UPDATE ON public.course_payments
    FOR EACH ROW
    EXECUTE FUNCTION create_payment_authorization_notification();

-- 14. Date demo pentru testare
INSERT INTO public.course_payments (user_id, course_id, method, status, amount, authorized, admin_note)
SELECT 
    p.id,
    c.id,
    'cash',
    'paid',
    c.price,
    true,
    'Plată cash confirmată în sala de dans'
FROM public.profiles p, public.courses c
WHERE p.email = 'adrian@payai-x.com'
AND c.title ILIKE '%salsa%'
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO public.course_payments (user_id, course_id, method, status, amount, authorized)
SELECT 
    p.id,
    c.id,
    'rate',
    'pending',
    c.price,
    false
FROM public.profiles p, public.courses c
WHERE p.email = 'adrian@payai-x.com'
AND c.title ILIKE '%bachata%'
LIMIT 1
ON CONFLICT DO NOTHING;

-- 15. Notificări demo
INSERT INTO public.notifications (user_id, title, body, type)
SELECT 
    p.id,
    'Bine ai venit!',
    'Bine ai venit în aplicația AIU Dance! Explorează cursurile disponibile.',
    'info'
FROM public.profiles p
WHERE p.email = 'adrian@payai-x.com'
ON CONFLICT DO NOTHING;

-- 16. Actualizează prețurile cursurilor
UPDATE public.courses 
SET price = CASE 
    WHEN title ILIKE '%salsa%' THEN 120.00
    WHEN title ILIKE '%bachata%' THEN 100.00
    WHEN title ILIKE '%kizomba%' THEN 150.00
    WHEN title ILIKE '%tango%' THEN 180.00
    WHEN title ILIKE '%hip%hop%' THEN 80.00
    WHEN title ILIKE '%contemporary%' THEN 110.00
    ELSE 90.00
END
WHERE price IS NULL OR price = 0;

-- 17. Verificare finală - afișează statistici
SELECT 'course_payments' as table_name, count(*) as records FROM public.course_payments
UNION ALL
SELECT 'notifications' as table_name, count(*) as records FROM public.notifications
UNION ALL
SELECT 'courses_with_price' as table_name, count(*) as records FROM public.courses WHERE price > 0
UNION ALL
SELECT 'enrollments' as table_name, count(*) as records FROM public.enrollments;

-- 18. Afișează cursurile cu prețuri
SELECT 
    title,
    category,
    price,
    max_participants,
    current_participants,
    is_active
FROM public.courses 
WHERE is_active = true
ORDER BY price DESC
LIMIT 10;
