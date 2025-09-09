-- ACCURATE SUPABASE FIX
-- Script care verifica existenta tabelelor inainte de creare

-- 1. Verificare si creare tabel bar_products doar daca nu exista
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bar_products' AND table_schema = 'public') THEN
        CREATE TABLE public.bar_products (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            category TEXT DEFAULT 'bauturi',
            stock_quantity INTEGER DEFAULT 0,
            is_available BOOLEAN DEFAULT true,
            image_url TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        -- Enable RLS
        ALTER TABLE public.bar_products ENABLE ROW LEVEL SECURITY;
        
        -- Create policy
        CREATE POLICY "bar_products_policy" ON public.bar_products FOR ALL USING (true);
        
        -- Insert demo data
        INSERT INTO public.bar_products (name, description, price, category, stock_quantity) VALUES 
        ('Coca Cola', 'Bautura racoritoare 330ml', 5.00, 'bauturi', 50),
        ('Apa Minerala', 'Apa minerala naturala 500ml', 3.00, 'bauturi', 100),
        ('Sandwich Sunca', 'Sandwich cu sunca si cascaval', 12.00, 'mancare', 20);
        
        RAISE NOTICE 'Table bar_products created successfully';
    ELSE
        RAISE NOTICE 'Table bar_products already exists';
    END IF;
END $$;

-- 2. Verificare si creare tabel qr_scans doar daca nu exista
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'qr_scans' AND table_schema = 'public') THEN
        CREATE TABLE public.qr_scans (
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
        
        -- Create policy
        CREATE POLICY "qr_scans_policy" ON public.qr_scans FOR ALL USING (auth.role() = 'authenticated');
        
        RAISE NOTICE 'Table qr_scans created successfully';
    ELSE
        RAISE NOTICE 'Table qr_scans already exists';
    END IF;
END $$;

-- 3. Adaugare coloane lipsa la attendance
DO $$
BEGIN
    -- session_date
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance' AND column_name = 'session_date' AND table_schema = 'public') THEN
        ALTER TABLE public.attendance ADD COLUMN session_date DATE DEFAULT CURRENT_DATE;
        RAISE NOTICE 'Column session_date added to attendance';
    END IF;
    
    -- created_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance' AND column_name = 'created_at' AND table_schema = 'public') THEN
        ALTER TABLE public.attendance ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Column created_at added to attendance';
    END IF;
    
    -- updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance' AND column_name = 'updated_at' AND table_schema = 'public') THEN
        ALTER TABLE public.attendance ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Column updated_at added to attendance';
    END IF;
    
    -- status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance' AND column_name = 'status' AND table_schema = 'public') THEN
        ALTER TABLE public.attendance ADD COLUMN status TEXT DEFAULT 'present';
        RAISE NOTICE 'Column status added to attendance';
    END IF;
    
    -- notes
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance' AND column_name = 'notes' AND table_schema = 'public') THEN
        ALTER TABLE public.attendance ADD COLUMN notes TEXT;
        RAISE NOTICE 'Column notes added to attendance';
    END IF;
END $$;

-- 4. Adaugare coloane lipsa la bar_orders
DO $$
BEGIN
    -- created_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bar_orders' AND column_name = 'created_at' AND table_schema = 'public') THEN
        ALTER TABLE public.bar_orders ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Column created_at added to bar_orders';
    END IF;
    
    -- updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bar_orders' AND column_name = 'updated_at' AND table_schema = 'public') THEN
        ALTER TABLE public.bar_orders ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Column updated_at added to bar_orders';
    END IF;
    
    -- status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bar_orders' AND column_name = 'status' AND table_schema = 'public') THEN
        ALTER TABLE public.bar_orders ADD COLUMN status TEXT DEFAULT 'pending';
        RAISE NOTICE 'Column status added to bar_orders';
    END IF;
    
    -- total_amount
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bar_orders' AND column_name = 'total_amount' AND table_schema = 'public') THEN
        ALTER TABLE public.bar_orders ADD COLUMN total_amount DECIMAL(10,2) DEFAULT 0.00;
        RAISE NOTICE 'Column total_amount added to bar_orders';
    END IF;
    
    -- items
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bar_orders' AND column_name = 'items' AND table_schema = 'public') THEN
        ALTER TABLE public.bar_orders ADD COLUMN items JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Column items added to bar_orders';
    END IF;
END $$;

-- 5. Verificare si adaugare coloane lipsa la qr_codes (daca exista tabela)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'qr_codes' AND table_schema = 'public') THEN
        -- code
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'code' AND table_schema = 'public') THEN
            ALTER TABLE public.qr_codes ADD COLUMN code TEXT UNIQUE;
            RAISE NOTICE 'Column code added to qr_codes';
        END IF;
        
        -- type
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'type' AND table_schema = 'public') THEN
            ALTER TABLE public.qr_codes ADD COLUMN type TEXT DEFAULT 'general';
            RAISE NOTICE 'Column type added to qr_codes';
        END IF;
        
        -- data
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'data' AND table_schema = 'public') THEN
            ALTER TABLE public.qr_codes ADD COLUMN data JSONB DEFAULT '{}'::jsonb;
            RAISE NOTICE 'Column data added to qr_codes';
        END IF;
        
        -- is_active
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'is_active' AND table_schema = 'public') THEN
            ALTER TABLE public.qr_codes ADD COLUMN is_active BOOLEAN DEFAULT true;
            RAISE NOTICE 'Column is_active added to qr_codes';
        END IF;
        
        -- created_at
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'qr_codes' AND column_name = 'created_at' AND table_schema = 'public') THEN
            ALTER TABLE public.qr_codes ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
            RAISE NOTICE 'Column created_at added to qr_codes';
        END IF;
        
        -- Enable RLS if not enabled
        ALTER TABLE public.qr_codes ENABLE ROW LEVEL SECURITY;
        
        -- Create policy if not exists
        DO $policy$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'qr_codes' AND policyname = 'qr_codes_policy') THEN
                CREATE POLICY "qr_codes_policy" ON public.qr_codes FOR ALL USING (auth.role() = 'authenticated');
                RAISE NOTICE 'Policy qr_codes_policy created';
            END IF;
        END $policy$;
        
        -- Insert demo data if table is empty
        IF (SELECT COUNT(*) FROM public.qr_codes) = 0 THEN
            INSERT INTO public.qr_codes (code, type, data) VALUES 
            ('QR_DEMO_ATTENDANCE', 'attendance', '{"purpose": "attendance"}'::jsonb),
            ('QR_DEMO_BAR', 'bar_order', '{"purpose": "bar_order"}'::jsonb);
            RAISE NOTICE 'Demo data inserted into qr_codes';
        END IF;
    END IF;
END $$;

-- 6. Actualizare date existente cu valori default
UPDATE public.attendance 
SET 
    session_date = COALESCE(session_date, CURRENT_DATE),
    created_at = COALESCE(created_at, NOW()),
    updated_at = COALESCE(updated_at, NOW()),
    status = COALESCE(status, 'present')
WHERE session_date IS NULL OR created_at IS NULL OR updated_at IS NULL OR status IS NULL;

UPDATE public.bar_orders 
SET 
    created_at = COALESCE(created_at, NOW()),
    updated_at = COALESCE(updated_at, NOW()),
    status = COALESCE(status, 'pending'),
    total_amount = COALESCE(total_amount, 0.00),
    items = COALESCE(items, '[]'::jsonb)
WHERE created_at IS NULL OR updated_at IS NULL OR status IS NULL OR total_amount IS NULL OR items IS NULL;

-- 7. Final success message
SELECT 
    'ACCURATE SUPABASE FIX COMPLETED!' as status,
    'All missing tables and columns have been created or verified!' as message;
