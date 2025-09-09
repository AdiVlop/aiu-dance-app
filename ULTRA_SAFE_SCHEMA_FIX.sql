-- ULTRA SAFE SCHEMA FIX pentru AIU Dance
-- Execută în Supabase Dashboard → SQL Editor

-- 1. Creează tabela enrollments dacă nu există (simplificată)
CREATE TABLE IF NOT EXISTS public.enrollments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'cancelled', 'completed')),
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

-- 2. Creează tabela attendance dacă nu există
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    session_date DATE DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'present' CHECK (status IN ('present', 'absent', 'late', 'excused')),
    check_in_time TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, course_id, session_date)
);

-- 3. Creează tabela qr_scans dacă nu există
CREATE TABLE IF NOT EXISTS public.qr_scans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    qr_code_id UUID REFERENCES public.qr_codes(id) ON DELETE CASCADE,
    scanned_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    scan_result TEXT DEFAULT 'success',
    scan_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Adaugă coloane în qr_codes dacă nu există
DO $$
BEGIN
    -- type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'type' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN type TEXT DEFAULT 'general';
    END IF;
    
    -- data
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'data' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN data JSONB DEFAULT '{}'::jsonb;
    END IF;
    
    -- title
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'title' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN title TEXT;
    END IF;
    
    -- course_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'course_id' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE;
    END IF;
    
    -- expires_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'expires_at' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN expires_at TIMESTAMPTZ;
    END IF;
END $$;

-- 5. Adaugă coloane în courses dacă nu există
DO $$
BEGIN
    -- price
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'price' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN price DECIMAL(10,2) DEFAULT 0.00;
    END IF;
    
    -- is_active
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'is_active' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- description
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'description' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN description TEXT;
    END IF;
END $$;

-- 6. Adaugă coloane în wallet_transactions dacă nu există
DO $$
BEGIN
    -- metadata
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'wallet_transactions' AND column_name = 'metadata' AND table_schema = 'public') THEN
        ALTER TABLE public.wallet_transactions ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
    END IF;
    
    -- description
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'wallet_transactions' AND column_name = 'description' AND table_schema = 'public') THEN
        ALTER TABLE public.wallet_transactions ADD COLUMN description TEXT;
    END IF;
END $$;

-- 7. Enable RLS pentru tabelele noi
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;

-- 8. Creează policies
DO $$
BEGIN
    -- enrollments policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'enrollments' AND policyname = 'enrollments_policy') THEN
        CREATE POLICY "enrollments_policy" ON public.enrollments FOR ALL USING (
            auth.uid() = user_id OR 
            EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'instructor'))
        );
    END IF;
    
    -- attendance policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'attendance' AND policyname = 'attendance_policy') THEN
        CREATE POLICY "attendance_policy" ON public.attendance FOR ALL USING (
            auth.uid() = user_id OR 
            EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'instructor'))
        );
    END IF;
    
    -- qr_scans policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'qr_scans' AND policyname = 'qr_scans_policy') THEN
        CREATE POLICY "qr_scans_policy" ON public.qr_scans FOR ALL USING (auth.role() = 'authenticated');
    END IF;
END $$;

-- 9. Creează index-uri
CREATE INDEX IF NOT EXISTS idx_enrollments_user_course ON public.enrollments(user_id, course_id);
CREATE INDEX IF NOT EXISTS idx_attendance_user_course_date ON public.attendance(user_id, course_id, session_date);
CREATE INDEX IF NOT EXISTS idx_qr_codes_type ON public.qr_codes(type);
CREATE INDEX IF NOT EXISTS idx_qr_scans_qr_code ON public.qr_scans(qr_code_id);

-- 10. Actualizează cursurile existente cu prețuri (fără referință la instructor)
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

-- 11. Inserează date demo pentru enrollments (simplu)
INSERT INTO public.enrollments (user_id, course_id, status) 
SELECT 
    p.id as user_id,
    c.id as course_id,
    'active' as status
FROM public.profiles p, public.courses c 
WHERE p.role IN ('student', 'user') AND c.title ILIKE '%hip hop%'
LIMIT 3
ON CONFLICT (user_id, course_id) DO NOTHING;

-- 12. Inserează date demo pentru qr_codes (simplu)
INSERT INTO public.qr_codes (code, title, type, data, is_active) VALUES 
('ATTENDANCE_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Attendance Demo', 'attendance', '{"purpose": "attendance", "location": "Sala 1"}'::jsonb, true),
('BAR_MENU_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Bar Menu', 'bar_order', '{"purpose": "bar_menu", "table": "1"}'::jsonb, true)
ON CONFLICT (code) DO NOTHING;

-- 13. Verifică rezultatul final
SELECT 'enrollments' as table_name, count(*) as records FROM public.enrollments
UNION ALL
SELECT 'attendance' as table_name, count(*) as records FROM public.attendance
UNION ALL
SELECT 'qr_codes' as table_name, count(*) as records FROM public.qr_codes
UNION ALL
SELECT 'qr_scans' as table_name, count(*) as records FROM public.qr_scans
UNION ALL
SELECT 'courses_with_price' as table_name, count(*) as records FROM public.courses WHERE price > 0;

-- 14. Afișează cursurile cu prețuri (fără referință la instructor)
SELECT 
    title,
    category,
    price,
    is_active,
    COALESCE(LEFT(description, 50), 'Descriere nedisponibilă') as short_description
FROM public.courses 
WHERE is_active = true
ORDER BY price DESC
LIMIT 10;
