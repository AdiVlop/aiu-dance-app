-- FINAL COMPLETE SCHEMA FIX pentru AIU Dance
-- Execută în Supabase Dashboard → SQL Editor

-- 1. Creează tabela enrollments dacă nu există (fără paid column)
CREATE TABLE IF NOT EXISTS public.enrollments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'cancelled', 'completed')),
    payment_intent_id TEXT,
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
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
    check_out_time TIMESTAMPTZ,
    notes TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    location TEXT,
    device_info TEXT
);

-- 4. Actualizează tabela wallet_transactions
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

-- 5. Actualizează tabela courses
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

-- 6. Actualizează tabela qr_codes
DO $$
BEGIN
    -- Adaugă coloana type dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'type' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN type TEXT DEFAULT 'general';
    END IF;
    
    -- Adaugă coloana data dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'data' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN data JSONB DEFAULT '{}'::jsonb;
    END IF;
    
    -- Adaugă coloana title dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'title' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN title TEXT;
    END IF;
    
    -- Adaugă coloana course_id dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'course_id' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE;
    END IF;
    
    -- Adaugă coloana expires_at dacă nu există
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'expires_at' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN expires_at TIMESTAMPTZ;
    END IF;
END $$;

-- 7. Enable RLS pentru tabelele noi
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;

-- 8. Creează policies pentru enrollments
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'enrollments' AND policyname = 'enrollments_policy') THEN
        CREATE POLICY "enrollments_policy" ON public.enrollments FOR ALL USING (
            auth.uid() = user_id OR 
            EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'instructor'))
        );
    END IF;
END $$;

-- 9. Creează policies pentru attendance
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'attendance' AND policyname = 'attendance_policy') THEN
        CREATE POLICY "attendance_policy" ON public.attendance FOR ALL USING (
            auth.uid() = user_id OR 
            EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'instructor'))
        );
    END IF;
END $$;

-- 10. Creează policies pentru qr_scans
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'qr_scans' AND policyname = 'qr_scans_policy') THEN
        CREATE POLICY "qr_scans_policy" ON public.qr_scans FOR ALL USING (auth.role() = 'authenticated');
    END IF;
END $$;

-- 11. Creează index-uri pentru performanță
CREATE INDEX IF NOT EXISTS idx_enrollments_user_course ON public.enrollments(user_id, course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON public.enrollments(status);
CREATE INDEX IF NOT EXISTS idx_attendance_user_course_date ON public.attendance(user_id, course_id, session_date);
CREATE INDEX IF NOT EXISTS idx_attendance_session_date ON public.attendance(session_date);
CREATE INDEX IF NOT EXISTS idx_qr_codes_course ON public.qr_codes(course_id);
CREATE INDEX IF NOT EXISTS idx_qr_codes_expires ON public.qr_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_qr_codes_type ON public.qr_codes(type);
CREATE INDEX IF NOT EXISTS idx_qr_scans_qr_code ON public.qr_scans(qr_code_id);

-- 12. Actualizează cursurile existente cu prețuri demo
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

-- 13. Inserează date demo pentru enrollments (fără paid column)
INSERT INTO public.enrollments (user_id, course_id, status) 
SELECT 
    p.id as user_id,
    c.id as course_id,
    'active' as status
FROM public.profiles p, public.courses c 
WHERE p.role = 'student' AND c.title ILIKE '%hip hop%'
LIMIT 3
ON CONFLICT (user_id, course_id) DO NOTHING;

-- 14. Inserează date demo pentru attendance
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

-- 15. Inserează date demo pentru qr_codes
INSERT INTO public.qr_codes (code, title, type, data, is_active) VALUES 
('ATTENDANCE_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Attendance Demo', 'attendance', '{"purpose": "attendance", "location": "Sala 1"}'::jsonb, true),
('BAR_MENU_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Bar Menu', 'bar_order', '{"purpose": "bar_menu", "table": "1"}'::jsonb, true),
('EVENT_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Event Check-in', 'event', '{"purpose": "event", "event_id": "demo"}'::jsonb, true)
ON CONFLICT (code) DO NOTHING;

-- 16. Inserează date demo pentru qr_scans
INSERT INTO public.qr_scans (qr_code_id, scanned_by, scan_result, scan_data) 
SELECT 
    qc.id,
    p.id,
    'success',
    jsonb_build_object(
        'scan_time', NOW()::text,
        'method', 'demo',
        'location', 'Sala 1'
    )
FROM public.qr_codes qc, public.profiles p 
WHERE p.role = 'admin' AND qc.type = 'attendance'
LIMIT 1
ON CONFLICT DO NOTHING;

-- 17. Verifică structura finală
SELECT 'enrollments' as table_name, count(*) as records FROM public.enrollments
UNION ALL
SELECT 'attendance' as table_name, count(*) as records FROM public.attendance
UNION ALL
SELECT 'qr_codes' as table_name, count(*) as records FROM public.qr_codes
UNION ALL
SELECT 'qr_scans' as table_name, count(*) as records FROM public.qr_scans
UNION ALL
SELECT 'courses_with_price' as table_name, count(*) as records FROM public.courses WHERE price > 0;

-- 18. Afișează cursurile cu prețuri
SELECT 
    title,
    category,
    COALESCE(instructor_id::text, 'N/A') as instructor_info,
    price,
    is_active,
    COALESCE(LEFT(description, 50), 'N/A') as short_description
FROM public.courses 
WHERE is_active = true
ORDER BY price DESC
LIMIT 10;
