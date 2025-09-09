-- INSTANT FIX - Repară rapid pentru a face funcțional butonul QR Plată
-- Aplică acest script în Supabase SQL Editor

-- 1. Creează tabela qr_scans (cauza erorii principale)
CREATE TABLE IF NOT EXISTS public.qr_scans (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    qr_code_id uuid REFERENCES public.qr_codes(id) ON DELETE CASCADE,
    scanned_by uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    scan_result text DEFAULT 'success',
    scan_data jsonb DEFAULT '{}',
    scanned_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now()
);

-- 2. Adaugă coloana completed_at în bar_orders
ALTER TABLE public.bar_orders ADD COLUMN IF NOT EXISTS completed_at timestamp with time zone;

-- 3. Actualizează constraint-ul status
ALTER TABLE public.bar_orders DROP CONSTRAINT IF EXISTS bar_orders_status_check;
ALTER TABLE public.bar_orders ADD CONSTRAINT bar_orders_status_check 
CHECK (status IN ('pending', 'confirmed', 'delivered', 'cancelled', 'completed'));

-- 4. Adaugă coloanele pentru plată
ALTER TABLE public.bar_orders ADD COLUMN IF NOT EXISTS payment_status text DEFAULT 'pending';
ALTER TABLE public.bar_orders ADD COLUMN IF NOT EXISTS payment_method text DEFAULT 'cash';
ALTER TABLE public.bar_orders ADD COLUMN IF NOT EXISTS qr_code_id uuid REFERENCES public.qr_codes(id);
ALTER TABLE public.bar_orders ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}';

-- 5. Activează RLS pentru qr_scans
ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;

-- 6. Creează policy simplă pentru qr_scans
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'qr_scans' AND policyname = 'qr_scans_policy') THEN
        CREATE POLICY "qr_scans_policy" ON public.qr_scans FOR ALL USING (
            auth.uid() = scanned_by OR 
            (SELECT auth.jwt() ->> 'role') = 'admin'
        );
    END IF;
END $$;

-- 7. Setează o comandă la status 'confirmed' pentru testare
UPDATE public.bar_orders 
SET 
    status = 'confirmed',
    payment_status = 'pending',
    payment_method = 'qr',
    metadata = '{}'::jsonb
WHERE id = (
    SELECT id FROM public.bar_orders 
    ORDER BY created_at DESC 
    LIMIT 1
);

-- 8. Actualizează toate comenzile cu valorile default
UPDATE public.bar_orders 
SET 
    payment_status = COALESCE(payment_status, 'pending'),
    payment_method = COALESCE(payment_method, 'cash'),
    metadata = COALESCE(metadata, '{}'::jsonb)
WHERE payment_status IS NULL OR payment_method IS NULL OR metadata IS NULL;

-- VERIFICARE FINALĂ
SELECT 
    'qr_scans' as table_name,
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'qr_scans') as exists,
    (SELECT count(*) FROM public.bar_orders WHERE status = 'confirmed') as confirmed_orders
UNION ALL
SELECT 
    'completed_at' as table_name,
    EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bar_orders' AND column_name = 'completed_at') as exists,
    0 as confirmed_orders;
