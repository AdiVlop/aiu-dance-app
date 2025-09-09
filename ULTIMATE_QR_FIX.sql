-- ULTIMATE QR CODE FIX pentru AIU Dance
-- Execută acest script în Supabase Dashboard → SQL Editor

-- 1. Creează tabela qr_scans dacă nu există
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

-- Enable RLS pentru qr_scans
ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;

-- Policy pentru qr_scans
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'qr_scans' AND policyname = 'qr_scans_policy') THEN
        CREATE POLICY "qr_scans_policy" ON public.qr_scans FOR ALL USING (auth.role() = 'authenticated');
    END IF;
END $$;

-- 2. Adaugă coloanele lipsă în qr_codes
DO $$
BEGIN
    -- Coloana type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'type' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN type TEXT DEFAULT 'general';
        RAISE NOTICE 'Column type added to qr_codes';
    END IF;
    
    -- Coloana data
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'data' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN data JSONB DEFAULT '{}'::jsonb;
        RAISE NOTICE 'Column data added to qr_codes';
    END IF;
    
    -- Coloana title
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'title' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN title TEXT;
        RAISE NOTICE 'Column title added to qr_codes';
    END IF;
    
    -- Coloana description
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'description' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN description TEXT;
        RAISE NOTICE 'Column description added to qr_codes';
    END IF;
    
    -- Coloana updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'updated_at' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Column updated_at added to qr_codes';
    END IF;
END $$;

-- 3. Inserează date demo pentru qr_codes
INSERT INTO public.qr_codes (code, title, type, data, is_active) VALUES 
('ATTENDANCE_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Prezență Demo', 'attendance', '{"purpose": "attendance", "location": "Sala 1"}'::jsonb, true),
('BAR_MENU_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Meniu Bar', 'bar_order', '{"purpose": "bar_menu", "table": "1"}'::jsonb, true),
('EVENT_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Event Check-in', 'event', '{"purpose": "event", "event_id": "demo"}'::jsonb, true),
('COURSE_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Curs Demo', 'course', '{"purpose": "course", "course_id": "demo"}'::jsonb, true)
ON CONFLICT (code) DO NOTHING;

-- 4. Inserează date demo pentru qr_scans
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

-- 5. Actualizează qr_codes existente cu date demo
UPDATE public.qr_codes 
SET 
    type = CASE 
        WHEN type IS NULL OR type = '' THEN 'general'
        ELSE type 
    END,
    data = CASE 
        WHEN data IS NULL THEN '{"purpose": "general"}'::jsonb
        ELSE data 
    END,
    title = CASE 
        WHEN title IS NULL OR title = '' THEN 'QR Code Demo'
        ELSE title 
    END,
    updated_at = NOW()
WHERE type IS NULL OR data IS NULL OR title IS NULL;

-- 6. Creează index-uri pentru performanță
CREATE INDEX IF NOT EXISTS idx_qr_codes_type ON public.qr_codes(type);
CREATE INDEX IF NOT EXISTS idx_qr_codes_is_active ON public.qr_codes(is_active);
CREATE INDEX IF NOT EXISTS idx_qr_scans_qr_code_id ON public.qr_scans(qr_code_id);
CREATE INDEX IF NOT EXISTS idx_qr_scans_scanned_by ON public.qr_scans(scanned_by);
CREATE INDEX IF NOT EXISTS idx_qr_scans_created_at ON public.qr_scans(created_at);

-- 7. Verifică că totul este OK
SELECT 'QR Codes count: ' || COUNT(*)::text as status FROM public.qr_codes;
SELECT 'QR Scans count: ' || COUNT(*)::text as status FROM public.qr_scans;

-- 8. Afișează structura finală
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'qr_codes' 
AND table_schema = 'public'
ORDER BY ordinal_position;
