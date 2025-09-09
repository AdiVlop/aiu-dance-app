-- COMPLETE BAR PAYMENT FIX
-- Script consolidat pentru repararea sistemului de plăți bar și QR

-- ========================================
-- 1. CREEAZĂ TABELA QR_SCANS
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
        
        RAISE NOTICE '✅ Tabela qr_scans creată cu succes';
    ELSE
        RAISE NOTICE '✅ Tabela qr_scans există deja';
    END IF;
END $$;

-- ========================================
-- 2. ADAUGĂ COLOANELE LIPSĂ ÎN BAR_ORDERS
-- ========================================

DO $$
BEGIN
    -- Adaugă completed_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'completed_at') THEN
        ALTER TABLE public.bar_orders ADD COLUMN completed_at timestamp with time zone;
        RAISE NOTICE '✅ Coloana completed_at adăugată în bar_orders';
    END IF;
    
    -- Adaugă payment_status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'payment_status') THEN
        ALTER TABLE public.bar_orders ADD COLUMN payment_status text DEFAULT 'pending';
        RAISE NOTICE '✅ Coloana payment_status adăugată în bar_orders';
    END IF;
    
    -- Adaugă qr_code_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'qr_code_id') THEN
        ALTER TABLE public.bar_orders ADD COLUMN qr_code_id uuid REFERENCES public.qr_codes(id);
        RAISE NOTICE '✅ Coloana qr_code_id adăugată în bar_orders';
    END IF;
    
    -- Adaugă payment_method
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'payment_method') THEN
        ALTER TABLE public.bar_orders ADD COLUMN payment_method text DEFAULT 'cash';
        RAISE NOTICE '✅ Coloana payment_method adăugată în bar_orders';
    END IF;
    
    -- Adaugă metadata
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bar_orders' AND column_name = 'metadata') THEN
        ALTER TABLE public.bar_orders ADD COLUMN metadata jsonb DEFAULT '{}';
        RAISE NOTICE '✅ Coloana metadata adăugată în bar_orders';
    END IF;
END $$;

-- ========================================
-- 3. CREEAZĂ INDEXURILE
-- ========================================

CREATE INDEX IF NOT EXISTS idx_qr_scans_qr_code_id ON public.qr_scans(qr_code_id);
CREATE INDEX IF NOT EXISTS idx_qr_scans_scanned_by ON public.qr_scans(scanned_by);
CREATE INDEX IF NOT EXISTS idx_qr_scans_scanned_at ON public.qr_scans(scanned_at DESC);
CREATE INDEX IF NOT EXISTS idx_bar_orders_payment_status ON public.bar_orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_bar_orders_qr_code_id ON public.bar_orders(qr_code_id);

-- ========================================
-- 4. ACTIVEAZĂ RLS ȘI CREEAZĂ POLICIES
-- ========================================

-- QR Scans policies
ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "qr_scans_policy" ON public.qr_scans;
CREATE POLICY "qr_scans_policy" ON public.qr_scans FOR ALL USING (
    auth.uid() = scanned_by OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- ========================================
-- 5. CREEAZĂ TABELA BAR_RECEIPTS PENTRU CHITANȚE
-- ========================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'bar_receipts') THEN
        
        CREATE TABLE public.bar_receipts (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            order_id uuid REFERENCES public.bar_orders(id) ON DELETE CASCADE,
            receipt_number text UNIQUE NOT NULL,
            customer_name text,
            customer_email text,
            items jsonb NOT NULL DEFAULT '[]',
            subtotal numeric(10,2) DEFAULT 0,
            tax_amount numeric(10,2) DEFAULT 0,
            total_amount numeric(10,2) NOT NULL,
            payment_method text DEFAULT 'cash',
            payment_status text DEFAULT 'paid',
            served_by uuid REFERENCES public.profiles(id),
            receipt_data jsonb DEFAULT '{}',
            printed_at timestamp with time zone,
            created_at timestamp with time zone DEFAULT now()
        );
        
        RAISE NOTICE '✅ Tabela bar_receipts creată cu succes';
    ELSE
        RAISE NOTICE '✅ Tabela bar_receipts există deja';
    END IF;
END $$;

-- Index pentru receipts
CREATE INDEX IF NOT EXISTS idx_bar_receipts_order_id ON public.bar_receipts(order_id);
CREATE INDEX IF NOT EXISTS idx_bar_receipts_receipt_number ON public.bar_receipts(receipt_number);
CREATE INDEX IF NOT EXISTS idx_bar_receipts_created_at ON public.bar_receipts(created_at DESC);

-- RLS pentru receipts
ALTER TABLE public.bar_receipts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bar_receipts_policy" ON public.bar_receipts;
CREATE POLICY "bar_receipts_policy" ON public.bar_receipts FOR ALL USING (
    (SELECT auth.jwt() ->> 'role') = 'admin' OR
    served_by = auth.uid()
);

-- ========================================
-- 6. FUNCȚIE PENTRU GENERAREA CHITANȚEI
-- ========================================

CREATE OR REPLACE FUNCTION generate_receipt_for_order(p_order_id uuid, p_served_by uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order record;
    v_receipt_number text;
    v_receipt_id uuid;
    v_result jsonb;
BEGIN
    -- Obține datele comenzii
    SELECT bo.*, p.full_name as customer_name, p.email as customer_email
    INTO v_order
    FROM bar_orders bo
    LEFT JOIN profiles p ON bo.user_id = p.id
    WHERE bo.id = p_order_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Comanda nu a fost găsită');
    END IF;
    
    -- Generează numărul chitanței
    v_receipt_number := 'REC' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(EXTRACT(EPOCH FROM NOW())::text, 10, '0');
    
    -- Creează chitanța
    INSERT INTO bar_receipts (
        order_id,
        receipt_number,
        customer_name,
        customer_email,
        items,
        total_amount,
        payment_method,
        payment_status,
        served_by,
        receipt_data
    ) VALUES (
        p_order_id,
        v_receipt_number,
        v_order.customer_name,
        v_order.customer_email,
        COALESCE(v_order.items, '[]'::jsonb),
        COALESCE(v_order.total_amount, v_order.total_price, 0),
        COALESCE(v_order.payment_method, 'qr'),
        'paid',
        p_served_by,
        jsonb_build_object(
            'order_date', v_order.created_at,
            'payment_date', NOW(),
            'location', 'Bar AIU Dance'
        )
    ) RETURNING id INTO v_receipt_id;
    
    -- Actualizează comanda ca fiind finalizată
    UPDATE bar_orders 
    SET 
        status = 'completed',
        payment_status = 'paid',
        completed_at = NOW()
    WHERE id = p_order_id;
    
    -- Returnează rezultatul
    SELECT jsonb_build_object(
        'success', true,
        'receipt_id', r.id,
        'receipt_number', r.receipt_number,
        'total_amount', r.total_amount,
        'customer_name', r.customer_name,
        'items', r.items,
        'created_at', r.created_at
    ) INTO v_result
    FROM bar_receipts r
    WHERE r.id = v_receipt_id;
    
    RETURN v_result;
END;
$$;

-- ========================================
-- 7. ACTUALIZEAZĂ DATE DEMO
-- ========================================

-- Actualizează comenzile existente cu coloanele noi
UPDATE public.bar_orders 
SET 
    payment_status = CASE 
        WHEN status = 'completed' THEN 'paid'
        WHEN status = 'confirmed' THEN 'pending'
        ELSE 'pending'
    END,
    payment_method = 'cash',
    metadata = '{}'::jsonb
WHERE payment_status IS NULL;

-- Adaugă câteva scanări demo
INSERT INTO public.qr_scans (qr_code_id, scanned_by, scan_result, scan_data)
SELECT 
    qc.id,
    p.id,
    'success',
    jsonb_build_object(
        'scan_type', 'payment',
        'amount', 25.50,
        'timestamp', now()
    )
FROM public.qr_codes qc
CROSS JOIN public.profiles p
WHERE qc.type = 'bar_payment' 
  AND p.role = 'student'
LIMIT 2
ON CONFLICT DO NOTHING;

-- ========================================
-- 8. VERIFICARE FINALĂ
-- ========================================

DO $$
DECLARE
    qr_scans_exists boolean;
    bar_receipts_exists boolean;
    columns_count integer;
BEGIN
    -- Verifică tabela qr_scans
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'qr_scans'
    ) INTO qr_scans_exists;
    
    -- Verifică tabela bar_receipts
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'bar_receipts'
    ) INTO bar_receipts_exists;
    
    -- Numără coloanele din bar_orders
    SELECT count(*) FROM information_schema.columns 
    WHERE table_name = 'bar_orders' INTO columns_count;
    
    RAISE NOTICE '✅ VERIFICARE FINALĂ:';
    RAISE NOTICE '   - Tabela qr_scans: %', qr_scans_exists;
    RAISE NOTICE '   - Tabela bar_receipts: %', bar_receipts_exists;
    RAISE NOTICE '   - Coloane bar_orders: %', columns_count;
    
    IF qr_scans_exists AND bar_receipts_exists AND columns_count >= 10 THEN
        RAISE NOTICE '🎉 Toate tabelele și coloanele sunt configurate corect!';
    ELSE
        RAISE NOTICE '❌ Probleme detectate în configurarea bazei de date';
    END IF;
END $$;

-- ========================================
-- FINAL
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Script COMPLETE_BAR_PAYMENT_FIX completat cu succes!';
END $$;
