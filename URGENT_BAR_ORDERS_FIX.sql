-- URGENT BAR ORDERS FIX
-- Repară rapid erorile pentru a face butonul QR Plată vizibil

-- ========================================
-- 1. ADAUGĂ COLOANA COMPLETED_AT
-- ========================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'completed_at') THEN
        ALTER TABLE public.bar_orders ADD COLUMN completed_at timestamp with time zone;
        RAISE NOTICE '✅ Coloana completed_at adăugată';
    ELSE
        RAISE NOTICE '✅ Coloana completed_at există deja';
    END IF;
END $$;

-- ========================================
-- 2. ACTUALIZEAZĂ STATUS CONSTRAINT
-- ========================================

-- Elimină constraint-ul vechi dacă există
ALTER TABLE public.bar_orders DROP CONSTRAINT IF EXISTS bar_orders_status_check;

-- Adaugă constraint nou cu toate statusurile
ALTER TABLE public.bar_orders ADD CONSTRAINT bar_orders_status_check 
CHECK (status IN ('pending', 'confirmed', 'delivered', 'cancelled', 'completed'));

-- ========================================
-- 3. CREEAZĂ TABELA QR_SCANS RAPID
-- ========================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'qr_scans') THEN
        
        CREATE TABLE public.qr_scans (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            qr_code_id uuid REFERENCES public.qr_codes(id) ON DELETE CASCADE,
            scanned_by uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
            scan_result text DEFAULT 'success',
            scan_data jsonb DEFAULT '{}',
            scanned_at timestamp with time zone DEFAULT now(),
            created_at timestamp with time zone DEFAULT now()
        );
        
        -- Activează RLS
        ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;
        
        -- Creează policy simplă
        CREATE POLICY "qr_scans_policy" ON public.qr_scans FOR ALL USING (
            auth.uid() = scanned_by OR 
            (SELECT auth.jwt() ->> 'role') = 'admin'
        );
        
        RAISE NOTICE '✅ Tabela qr_scans creată cu succes';
    ELSE
        RAISE NOTICE '✅ Tabela qr_scans există deja';
    END IF;
END $$;

-- ========================================
-- 4. ADAUGĂ COLOANELE LIPSĂ ÎN BAR_ORDERS
-- ========================================

DO $$
BEGIN
    -- payment_status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'payment_status') THEN
        ALTER TABLE public.bar_orders ADD COLUMN payment_status text DEFAULT 'pending';
        RAISE NOTICE '✅ Coloana payment_status adăugată';
    END IF;
    
    -- qr_code_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'qr_code_id') THEN
        ALTER TABLE public.bar_orders ADD COLUMN qr_code_id uuid REFERENCES public.qr_codes(id);
        RAISE NOTICE '✅ Coloana qr_code_id adăugată';
    END IF;
    
    -- payment_method
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'payment_method') THEN
        ALTER TABLE public.bar_orders ADD COLUMN payment_method text DEFAULT 'cash';
        RAISE NOTICE '✅ Coloana payment_method adăugată';
    END IF;
    
    -- metadata
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'metadata') THEN
        ALTER TABLE public.bar_orders ADD COLUMN metadata jsonb DEFAULT '{}';
        RAISE NOTICE '✅ Coloana metadata adăugată';
    END IF;
END $$;

-- ========================================
-- 5. ACTUALIZEAZĂ COMENZILE EXISTENTE
-- ========================================

-- Setează statusul unei comenzi la 'confirmed' pentru testare
UPDATE public.bar_orders 
SET 
    status = 'confirmed',
    payment_status = 'pending',
    payment_method = 'qr',
    metadata = '{}'::jsonb
WHERE id = (
    SELECT id FROM public.bar_orders 
    WHERE status = 'pending' 
    ORDER BY created_at DESC 
    LIMIT 1
);

-- Actualizează toate comenzile cu coloanele noi
UPDATE public.bar_orders 
SET 
    payment_status = COALESCE(payment_status, 'pending'),
    payment_method = COALESCE(payment_method, 'cash'),
    metadata = COALESCE(metadata, '{}'::jsonb)
WHERE payment_status IS NULL OR payment_method IS NULL OR metadata IS NULL;

-- ========================================
-- 6. VERIFICARE RAPIDĂ
-- ========================================

DO $$
DECLARE
    confirmed_orders integer;
    qr_scans_exists boolean;
    completed_at_exists boolean;
BEGIN
    -- Numără comenzile confirmed
    SELECT count(*) FROM public.bar_orders WHERE status = 'confirmed' INTO confirmed_orders;
    
    -- Verifică tabela qr_scans
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'qr_scans'
    ) INTO qr_scans_exists;
    
    -- Verifică coloana completed_at
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'completed_at'
    ) INTO completed_at_exists;
    
    RAISE NOTICE '✅ VERIFICARE RAPIDĂ:';
    RAISE NOTICE '   - Comenzi confirmed: %', confirmed_orders;
    RAISE NOTICE '   - Tabela qr_scans: %', qr_scans_exists;
    RAISE NOTICE '   - Coloana completed_at: %', completed_at_exists;
    
    IF confirmed_orders > 0 AND qr_scans_exists AND completed_at_exists THEN
        RAISE NOTICE '🎉 Butonul QR Plată ar trebui să apară acum!';
    ELSE
        RAISE NOTICE '❌ Încă sunt probleme de rezolvat';
    END IF;
END $$;

-- ========================================
-- FINAL
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Script URGENT_BAR_ORDERS_FIX completat!';
    RAISE NOTICE '📱 Reîncarcă aplicația pentru a vedea butonul QR Plată!';
END $$;






