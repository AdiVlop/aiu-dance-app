-- COURSE PAYMENT & QR ATTENDANCE SCHEMA pentru AIU Dance
-- Execută în Supabase Dashboard → SQL Editor

-- 1. Creează tabela enrollments dacă nu există
CREATE TABLE IF NOT EXISTS public.enrollments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'cancelled', 'completed')),
    paid BOOLEAN DEFAULT false,
    payment_intent_id TEXT,
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

-- 2. Creează tabela attendance dacă nu există (pentru QR prezență)
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    session_date DATE DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'present' CHECK (status IN ('present', 'absent', 'late', 'excused')),
    check_in_time TIMESTAMPTZ,
    check_out_time TIMESTAMPTZ,
    notes TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, course_id, session_date)
);

-- 3. Actualizează tabela wallet_transactions pentru plăți cursuri
DO $$
BEGIN
    -- Adaugă coloana metadata dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'wallet_transactions' AND column_name = 'metadata' AND table_schema = 'public') THEN
        ALTER TABLE public.wallet_transactions ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
    END IF;
    
    -- Adaugă coloana description dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'wallet_transactions' AND column_name = 'description' AND table_schema = 'public') THEN
        ALTER TABLE public.wallet_transactions ADD COLUMN description TEXT;
    END IF;
END $$;

-- 4. Actualizează tabela courses pentru prețuri
DO $$
BEGIN
    -- Adaugă coloana price dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'price' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN price DECIMAL(10,2) DEFAULT 0.00;
    END IF;
    
    -- Adaugă coloana is_active dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'is_active' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- Adaugă coloana description dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'description' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN description TEXT;
    END IF;
END $$;

-- 5. Actualizează tabela qr_codes pentru prezență
DO $$
BEGIN
    -- Adaugă coloana course_id dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'course_id' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE;
    END IF;
    
    -- Adaugă coloana expires_at dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'expires_at' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN expires_at TIMESTAMPTZ;
    END IF;
END $$;

-- 6. Enable RLS pentru tabelele noi
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- 7. Creează policies pentru enrollments
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'enrollments' AND policyname = 'enrollments_policy') THEN
        CREATE POLICY "enrollments_policy" ON public.enrollments FOR ALL USING (
            auth.uid() = user_id OR 
            EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'instructor'))
        );
    END IF;
END $$;

-- 8. Creează policies pentru attendance
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'attendance' AND policyname = 'attendance_policy') THEN
        CREATE POLICY "attendance_policy" ON public.attendance FOR ALL USING (
            auth.uid() = user_id OR 
            EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'instructor'))
        );
    END IF;
END $$;

-- 9. Creează index-uri pentru performanță
CREATE INDEX IF NOT EXISTS idx_enrollments_user_course ON public.enrollments(user_id, course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON public.enrollments(status);
CREATE INDEX IF NOT EXISTS idx_attendance_user_course_date ON public.attendance(user_id, course_id, session_date);
CREATE INDEX IF NOT EXISTS idx_attendance_session_date ON public.attendance(session_date);
CREATE INDEX IF NOT EXISTS idx_qr_codes_course ON public.qr_codes(course_id);
CREATE INDEX IF NOT EXISTS idx_qr_codes_expires ON public.qr_codes(expires_at);

-- 10. Actualizează cursurile existente cu prețuri demo
UPDATE public.courses 
SET 
    price = CASE 
        WHEN title ILIKE '%hip hop%' THEN 150.00
        WHEN title ILIKE '%salsa%' THEN 120.00
        WHEN title ILIKE '%bachata%' THEN 120.00
        WHEN title ILIKE '%contemporary%' THEN 180.00
        WHEN title ILIKE '%jazz%' THEN 160.00
        WHEN title ILIKE '%ballet%' THEN 200.00
        ELSE 100.00
    END,
    description = CASE 
        WHEN description IS NULL OR description = '' THEN 'Curs de dans pentru toate nivelurile. Vino să înveți pași noi într-o atmosferă prietenoasă!'
        ELSE description
    END,
    is_active = true
WHERE price IS NULL OR price = 0;

-- 11. Inserează date demo pentru enrollments
INSERT INTO public.enrollments (user_id, course_id, status) 
SELECT 
    p.id as user_id,
    c.id as course_id,
    'active' as status
FROM public.profiles p, public.courses c 
WHERE p.role = 'student' AND c.title ILIKE '%hip hop%'
LIMIT 3
ON CONFLICT (user_id, course_id) DO NOTHING;

-- 12. Inserează date demo pentru attendance
INSERT INTO public.attendance (user_id, course_id, session_date, status, check_in_time) 
SELECT 
    e.user_id,
    e.course_id,
    CURRENT_DATE,
    'present',
    NOW() - INTERVAL '2 hours'
FROM public.enrollments e
WHERE e.status = 'active'
LIMIT 5
ON CONFLICT (user_id, course_id, session_date) DO NOTHING;

-- 13. Verifică structura finală
SELECT 'enrollments' as table_name, count(*) as records FROM public.enrollments
UNION ALL
SELECT 'attendance' as table_name, count(*) as records FROM public.attendance
UNION ALL
SELECT 'courses_with_price' as table_name, count(*) as records FROM public.courses WHERE price > 0;

-- 14. Afișează cursurile cu prețuri
SELECT 
    title,
    category,
    instructor,
    price,
    is_active,
    description
FROM public.courses 
WHERE is_active = true
ORDER BY price DESC;
