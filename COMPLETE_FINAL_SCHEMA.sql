-- ===============================================
-- COMPLETE FINAL SCHEMA - AIU DANCE
-- Rezolvă toate erorile de schema în Supabase
-- ===============================================

-- 1. TABELA NOTIFICATIONS (cu coloana 'read')
DROP TABLE IF EXISTS public.notifications CASCADE;
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    read BOOLEAN DEFAULT false,
    type TEXT DEFAULT 'info',
    metadata JSONB,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- 2. TABELA COURSE_PAYMENTS (sistem plăți)
DROP TABLE IF EXISTS public.course_payments CASCADE;
CREATE TABLE public.course_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    method TEXT NOT NULL CHECK (method IN ('cash', 'wallet', 'revolut', 'rate', 'bank')),
    authorized BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'declined', 'partial', 'authorized')),
    amount NUMERIC NOT NULL,
    proof_url TEXT,
    admin_note TEXT,
    authorized_by UUID REFERENCES public.profiles(id),
    authorized_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABELA QR_SCANS (cu user_id corect)
DROP TABLE IF EXISTS public.qr_scans CASCADE;
CREATE TABLE public.qr_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    qr_code_id UUID REFERENCES public.qr_codes(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    scan_data JSONB,
    scanned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. ADAUGĂ COLOANE LIPSĂ LA TABELE EXISTENTE

-- Enrollments
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'enrollments' AND column_name = 'created_at') THEN
        ALTER TABLE public.enrollments ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'enrollments' AND column_name = 'payment_method') THEN
        ALTER TABLE public.enrollments ADD COLUMN payment_method TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'enrollments' AND column_name = 'payment_status') THEN
        ALTER TABLE public.enrollments ADD COLUMN payment_status TEXT DEFAULT 'pending';
    END IF;
END $$;

-- Courses
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'price') THEN
        ALTER TABLE public.courses ADD COLUMN price NUMERIC DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'is_active') THEN
        ALTER TABLE public.courses ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
END $$;

-- QR Codes
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'type') THEN
        ALTER TABLE public.qr_codes ADD COLUMN type TEXT DEFAULT 'general';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'data') THEN
        ALTER TABLE public.qr_codes ADD COLUMN data JSONB;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'title') THEN
        ALTER TABLE public.qr_codes ADD COLUMN title TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'description') THEN
        ALTER TABLE public.qr_codes ADD COLUMN description TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'updated_at') THEN
        ALTER TABLE public.qr_codes ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'course_id') THEN
        ALTER TABLE public.qr_codes ADD COLUMN course_id UUID REFERENCES public.courses(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'expires_at') THEN
        ALTER TABLE public.qr_codes ADD COLUMN expires_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Wallet Transactions
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'wallet_transactions' AND column_name = 'metadata') THEN
        ALTER TABLE public.wallet_transactions ADD COLUMN metadata JSONB;
    END IF;
END $$;

-- 5. ACTIVEAZĂ RLS PENTRU TOATE TABELELE
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;

-- 6. CREEAZĂ INDEXURI PENTRU PERFORMANȚĂ
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);
CREATE INDEX IF NOT EXISTS idx_course_payments_user_id ON public.course_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_course_payments_status ON public.course_payments(status);
CREATE INDEX IF NOT EXISTS idx_qr_scans_user_id ON public.qr_scans(user_id);
CREATE INDEX IF NOT EXISTS idx_qr_scans_qr_code_id ON public.qr_scans(qr_code_id);

-- 7. POLICIES RLS PENTRU NOTIFICATIONS
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can view own notifications') THEN
        CREATE POLICY "Users can view own notifications" ON public.notifications
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can update own notifications') THEN
        CREATE POLICY "Users can update own notifications" ON public.notifications
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Admins can manage all notifications') THEN
        CREATE POLICY "Admins can manage all notifications" ON public.notifications
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND (role = 'admin' OR role = 'instructor')
                )
            );
    END IF;
END $$;

-- 8. POLICIES RLS PENTRU COURSE_PAYMENTS
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_payments' AND policyname = 'Users can view own payments') THEN
        CREATE POLICY "Users can view own payments" ON public.course_payments
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_payments' AND policyname = 'Users can create own payments') THEN
        CREATE POLICY "Users can create own payments" ON public.course_payments
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_payments' AND policyname = 'Admins can manage all payments') THEN
        CREATE POLICY "Admins can manage all payments" ON public.course_payments
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND (role = 'admin' OR role = 'instructor')
                )
            );
    END IF;
END $$;

-- 9. POLICIES RLS PENTRU QR_SCANS
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'qr_scans' AND policyname = 'Users can view own scans') THEN
        CREATE POLICY "Users can view own scans" ON public.qr_scans
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'qr_scans' AND policyname = 'Users can create own scans') THEN
        CREATE POLICY "Users can create own scans" ON public.qr_scans
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'qr_scans' AND policyname = 'Admins can manage all scans') THEN
        CREATE POLICY "Admins can manage all scans" ON public.qr_scans
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND (role = 'admin' OR role = 'instructor')
                )
            );
    END IF;
END $$;

-- 10. INSEREAZĂ DATE DEMO

-- Notifications demo
INSERT INTO public.notifications (user_id, title, body, type, read)
SELECT 
    p.id,
    'Bine ai venit în AIU Dance!',
    'Explorează cursurile disponibile și înscrie-te la cel care îți place.',
    'info',
    false
FROM public.profiles p
WHERE p.email = 'adrian@payai-x.com'
ON CONFLICT DO NOTHING;

-- Course payments demo
INSERT INTO public.course_payments (user_id, course_id, method, status, amount)
SELECT 
    p.id,
    c.id,
    'cash',
    'paid',
    67.0
FROM public.profiles p
CROSS JOIN public.courses c
WHERE p.email = 'adrian@payai-x.com' 
AND c.title LIKE '%Dans%'
LIMIT 1
ON CONFLICT DO NOTHING;

-- QR codes demo cu coloana 'code'
INSERT INTO public.qr_codes (code, title, type, data, is_active)
VALUES 
    ('QR_ATTENDANCE_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Prezență Curs', 'attendance', 
     jsonb_build_object('purpose', 'attendance', 'location', 'Sala 1'), true),
    ('QR_DEMO_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Demo', 'general', 
     jsonb_build_object('demo', true, 'created_at', NOW()), true)
ON CONFLICT DO NOTHING;

-- QR scans demo
INSERT INTO public.qr_scans (qr_code_id, user_id, scan_data)
SELECT 
    qr.id,
    p.id,
    jsonb_build_object('scan_time', NOW(), 'method', 'demo')
FROM public.qr_codes qr
CROSS JOIN public.profiles p
WHERE p.email = 'adrian@payai-x.com'
AND qr.title = 'QR Demo'
LIMIT 1
ON CONFLICT DO NOTHING;

-- 11. VERIFICĂ REZULTATELE
SELECT 
    'Schema completă aplicată cu succes!' as status,
    (SELECT COUNT(*) FROM public.notifications) as notifications_count,
    (SELECT COUNT(*) FROM public.course_payments) as payments_count,
    (SELECT COUNT(*) FROM public.qr_scans) as scans_count;

-- 12. AFIȘEAZĂ STRUCTURA FINALĂ
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('notifications', 'course_payments', 'qr_scans', 'enrollments', 'qr_codes')
ORDER BY table_name, ordinal_position;
