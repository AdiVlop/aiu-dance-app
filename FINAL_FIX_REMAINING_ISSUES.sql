-- FINAL FIX pentru problemele rămase

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

-- Enable RLS
ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;

-- Policy pentru qr_scans
DROP POLICY IF EXISTS "qr_scans_policy" ON public.qr_scans;
CREATE POLICY "qr_scans_policy" ON public.qr_scans 
FOR ALL USING (auth.role() = 'authenticated');

-- 2. Adaugă coloana type în qr_codes dacă nu există
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'type' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN type TEXT DEFAULT 'general';
        RAISE NOTICE 'Column type added to qr_codes';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'data' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN data JSONB DEFAULT '{}'::jsonb;
        RAISE NOTICE 'Column data added to qr_codes';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'is_active' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Column is_active added to qr_codes';
    END IF;
END $$;

-- 3. Adaugă coloana title în qr_codes dacă nu există
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'title' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN title TEXT;
        RAISE NOTICE 'Column title added to qr_codes';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'description' AND table_schema = 'public') THEN
        ALTER TABLE public.qr_codes ADD COLUMN description TEXT;
        RAISE NOTICE 'Column description added to qr_codes';
    END IF;
END $$;

-- 4. Inserează date demo pentru qr_codes dacă nu există
INSERT INTO public.qr_codes (code, title, type, data, is_active) VALUES 
('ATTENDANCE_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Attendance Demo', 'attendance', '{"purpose": "attendance", "location": "Sala 1"}'::jsonb, true),
('BAR_MENU_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Bar Menu', 'bar_order', '{"purpose": "bar_menu", "table": "1"}'::jsonb, true),
('EVENT_' || EXTRACT(EPOCH FROM NOW())::text, 'QR Event Check-in', 'event', '{"purpose": "event", "event_id": "demo"}'::jsonb, true)
ON CONFLICT (code) DO NOTHING;

-- 5. Inserează date demo pentru qr_scans
INSERT INTO public.qr_scans (qr_code_id, scanned_by, scan_result, scan_data) 
SELECT 
    qc.id,
    p.id,
    'success',
    '{"timestamp": "2025-01-05T10:00:00Z", "device": "web"}'::jsonb
FROM public.qr_codes qc, public.profiles p 
WHERE qc.type = 'attendance' AND p.role = 'admin'
LIMIT 1
ON CONFLICT DO NOTHING;

-- SUCCESS MESSAGE
SELECT 
    'FINAL FIX COMPLETED!' as status,
    'All missing tables and columns created!' as message;
