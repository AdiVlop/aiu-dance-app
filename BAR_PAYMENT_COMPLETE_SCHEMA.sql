-- BAR PAYMENT COMPLETE SCHEMA
-- Schema completă pentru modulul bar cu plată și chitanță

-- ========================================
-- 1. ACTUALIZEAZĂ TABELA BAR_ORDERS
-- ========================================

-- Asigură-te că tabela bar_orders are structura corectă
CREATE TABLE IF NOT EXISTS bar_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    product_name TEXT,
    quantity INTEGER DEFAULT 1,
    total_price DECIMAL(10,2) DEFAULT 0.00,
    items JSONB DEFAULT '[]'::jsonb,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'delivered', 'cancelled', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Adaugă coloanele necesare pentru plăți
DO $$
BEGIN
    -- product_name (dacă nu există)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'product_name' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN product_name TEXT;
        RAISE NOTICE '✅ Coloana product_name adăugată în bar_orders';
    END IF;

    -- quantity (dacă nu există)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'quantity' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN quantity INTEGER DEFAULT 1;
        RAISE NOTICE '✅ Coloana quantity adăugată în bar_orders';
    END IF;

    -- total_price (dacă nu există)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'total_price' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN total_price DECIMAL(10,2) DEFAULT 0.00;
        RAISE NOTICE '✅ Coloana total_price adăugată în bar_orders';
    END IF;
    -- payment_method
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'payment_method' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN payment_method TEXT DEFAULT 'cash' CHECK (payment_method IN ('cash', 'wallet', 'revolut', 'qr'));
        RAISE NOTICE '✅ Coloana payment_method adăugată în bar_orders';
    END IF;

    -- payment_status
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'payment_status' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'cancelled'));
        RAISE NOTICE '✅ Coloana payment_status adăugată în bar_orders';
    END IF;

    -- receipt_url
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'receipt_url' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN receipt_url TEXT;
        RAISE NOTICE '✅ Coloana receipt_url adăugată în bar_orders';
    END IF;

    -- qr_code_id (pentru QR de plată)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'qr_code_id' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN qr_code_id UUID REFERENCES qr_codes(id);
        RAISE NOTICE '✅ Coloana qr_code_id adăugată în bar_orders';
    END IF;

    -- payment_completed_at
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'payment_completed_at' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN payment_completed_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Coloana payment_completed_at adăugată în bar_orders';
    END IF;

    -- metadata pentru informații suplimentare
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'metadata' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
        RAISE NOTICE '✅ Coloana metadata adăugată în bar_orders';
    END IF;
END $$;

-- ========================================
-- 2. CREEAZĂ TABELA BAR_RECEIPTS
-- ========================================

CREATE TABLE IF NOT EXISTS bar_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bar_order_id UUID NOT NULL REFERENCES bar_orders(id) ON DELETE CASCADE,
    receipt_number TEXT UNIQUE NOT NULL,
    customer_name TEXT,
    customer_email TEXT,
    items JSONB NOT NULL, -- Array cu produsele comandate
    subtotal NUMERIC(10,2) NOT NULL,
    tax_amount NUMERIC(10,2) DEFAULT 0,
    total_amount NUMERIC(10,2) NOT NULL,
    payment_method TEXT NOT NULL,
    payment_status TEXT DEFAULT 'paid',
    receipt_url TEXT, -- URL către PDF-ul chitanței
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comentarii pentru tabela bar_receipts
COMMENT ON TABLE bar_receipts IS 'Chitanțe pentru comenzile bar';
COMMENT ON COLUMN bar_receipts.receipt_number IS 'Numărul unic al chitanței (ex: BAR-2025-001)';
COMMENT ON COLUMN bar_receipts.items IS 'Array JSON cu produsele din comandă';

-- ========================================
-- 3. INDEXURI PENTRU PERFORMANȚĂ
-- ========================================

-- Indexuri pentru bar_orders
CREATE INDEX IF NOT EXISTS idx_bar_orders_payment_status ON bar_orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_bar_orders_payment_method ON bar_orders(payment_method);
CREATE INDEX IF NOT EXISTS idx_bar_orders_payment_completed ON bar_orders(payment_completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_bar_orders_user_status ON bar_orders(user_id, payment_status);

-- Indexuri pentru bar_receipts
CREATE INDEX IF NOT EXISTS idx_bar_receipts_order_id ON bar_receipts(bar_order_id);
CREATE INDEX IF NOT EXISTS idx_bar_receipts_number ON bar_receipts(receipt_number);
CREATE INDEX IF NOT EXISTS idx_bar_receipts_created_at ON bar_receipts(created_at DESC);

-- ========================================
-- 4. RLS POLICIES PENTRU BAR_RECEIPTS
-- ========================================

ALTER TABLE bar_receipts ENABLE ROW LEVEL SECURITY;

-- Policy pentru utilizatori: pot vedea propriile chitanțe
DROP POLICY IF EXISTS "Users can view their own receipts" ON bar_receipts;
CREATE POLICY "Users can view their own receipts" ON bar_receipts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM bar_orders 
            WHERE id = bar_receipts.bar_order_id 
            AND user_id = auth.uid()
        )
    );

-- Policy pentru administratori: pot vedea toate chitanțele
DROP POLICY IF EXISTS "Admins can view all receipts" ON bar_receipts;
CREATE POLICY "Admins can view all receipts" ON bar_receipts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ========================================
-- 5. FUNCȚII HELPER PENTRU CHITANȚE
-- ========================================

-- Funcție pentru generarea numărului de chitanță
CREATE OR REPLACE FUNCTION generate_receipt_number()
RETURNS TEXT AS $$
DECLARE
    year_part TEXT;
    sequence_num INTEGER;
    receipt_num TEXT;
BEGIN
    year_part := EXTRACT(YEAR FROM NOW())::TEXT;
    
    -- Găsește următorul număr în secvență pentru anul curent
    SELECT COALESCE(MAX(
        CAST(
            SUBSTRING(receipt_number FROM 'BAR-' || year_part || '-(\d+)')
            AS INTEGER
        )
    ), 0) + 1
    INTO sequence_num
    FROM bar_receipts
    WHERE receipt_number LIKE 'BAR-' || year_part || '-%';
    
    receipt_num := 'BAR-' || year_part || '-' || LPAD(sequence_num::TEXT, 3, '0');
    
    RETURN receipt_num;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funcție pentru crearea automată a chitanței după plată
CREATE OR REPLACE FUNCTION create_receipt_for_order()
RETURNS TRIGGER AS $$
DECLARE
    receipt_num TEXT;
    user_profile RECORD;
    order_items JSONB;
BEGIN
    -- Doar dacă statusul a fost schimbat la 'paid'
    IF NEW.payment_status = 'paid' AND (OLD.payment_status IS NULL OR OLD.payment_status != 'paid') THEN
        
        -- Generează numărul chitanței
        receipt_num := generate_receipt_number();
        
        -- Obține datele utilizatorului
        SELECT full_name, email INTO user_profile
        FROM profiles 
        WHERE id = NEW.user_id;
        
        -- Creează array-ul cu items
        order_items := jsonb_build_array(
            jsonb_build_object(
                'product_name', NEW.product_name,
                'quantity', NEW.quantity,
                'unit_price', NEW.total_price / NEW.quantity,
                'total_price', NEW.total_price
            )
        );
        
        -- Inserează chitanța
        INSERT INTO bar_receipts (
            bar_order_id,
            receipt_number,
            customer_name,
            customer_email,
            items,
            subtotal,
            total_amount,
            payment_method,
            payment_status
        ) VALUES (
            NEW.id,
            receipt_num,
            user_profile.full_name,
            user_profile.email,
            order_items,
            NEW.total_price,
            NEW.total_price,
            NEW.payment_method,
            'paid'
        );
        
        -- Actualizează comanda cu URL-ul chitanței
        NEW.receipt_url := '/receipts/' || receipt_num;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Creează trigger-ul pentru generarea automată a chitanțelor
DROP TRIGGER IF EXISTS create_receipt_after_payment ON bar_orders;
CREATE TRIGGER create_receipt_after_payment
    BEFORE UPDATE ON bar_orders
    FOR EACH ROW
    EXECUTE FUNCTION create_receipt_for_order();

-- ========================================
-- 6. ACTUALIZEAZĂ WALLET_TRANSACTIONS PENTRU BAR
-- ========================================

-- Asigură-te că wallet_transactions acceptă tipul 'bar_payment'
DO $$
BEGIN
    -- Verifică dacă constraint-ul permite 'bar_payment'
    -- Dacă nu, actualizează-l pentru a include tipurile necesare pentru bar
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conrelid = 'wallet_transactions'::regclass 
        AND contype = 'c' 
        AND pg_get_constraintdef(oid) LIKE '%credit%'
        AND pg_get_constraintdef(oid) LIKE '%debit%'
    ) THEN
        -- Constraint-ul există și folosește credit/debit
        RAISE NOTICE 'ℹ️  Wallet transactions folosește deja credit/debit';
    ELSE
        -- Adaugă sau actualizează constraint-ul
        ALTER TABLE wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;
        ALTER TABLE wallet_transactions 
        ADD CONSTRAINT wallet_transactions_type_check 
        CHECK (type IN ('credit', 'debit', 'wallet', 'topup', 'bar_payment', 'course_payment'));
        RAISE NOTICE '✅ Constraint actualizat pentru wallet_transactions';
    END IF;
END $$;

-- ========================================
-- 7. DATE DEMO PENTRU TESTARE
-- ========================================

-- Inserează comenzi demo cu plăți
INSERT INTO bar_orders (
    user_id, 
    product_name, 
    quantity, 
    total_price, 
    payment_method, 
    payment_status,
    items,
    created_at
)
SELECT 
    (SELECT id FROM profiles WHERE role != 'admin' LIMIT 1),
    'Cafea Americano',
    2,
    15.00,
    'wallet',
    'paid',
    jsonb_build_array(
        jsonb_build_object(
            'product_name', 'Cafea Americano',
            'quantity', 2,
            'unit_price', 7.50,
            'total_price', 15.00
        )
    ),
    NOW() - INTERVAL '1 hour'
WHERE NOT EXISTS (
    SELECT 1 FROM bar_orders WHERE product_name = 'Cafea Americano' AND payment_status = 'paid'
) AND EXISTS (
    SELECT 1 FROM profiles WHERE role != 'admin'
);

-- ========================================
-- 8. VERIFICĂRI FINALE
-- ========================================

-- Verifică coloanele bar_orders
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    '✅ OK' as status
FROM information_schema.columns 
WHERE table_name = 'bar_orders' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verifică tabela bar_receipts
SELECT 
    'bar_receipts' as table_name,
    COUNT(*) as record_count,
    '✅ Tabela gata' as status
FROM bar_receipts;

-- Verifică comenzile cu plăți
SELECT 
    product_name,
    payment_method,
    payment_status,
    receipt_url,
    '✅ Comandă cu plată' as status
FROM bar_orders 
WHERE payment_status = 'paid'
ORDER BY created_at DESC
LIMIT 5;

-- Mesaj final
SELECT '🎉 BAR PAYMENT SYSTEM SCHEMA READY!' as final_status;
