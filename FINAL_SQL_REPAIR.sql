-- ===================================================================
-- FINAL SQL REPAIR - AIU DANCE APP
-- Repară toate erorile SQL într-un singur script simplu
-- ===================================================================

-- 1. CREATE OR FIX ATTENDANCE TABLE
-- ===================================================================

DROP TABLE IF EXISTS public.attendance CASCADE;

CREATE TABLE public.attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES public.courses(id) ON DELETE SET NULL,
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'present',
    notes TEXT,
    qr_code_used TEXT,
    check_in_time TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. CREATE OR FIX BAR_ORDERS TABLE
-- ===================================================================

DROP TABLE IF EXISTS public.bar_orders CASCADE;

CREATE TABLE public.bar_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    items JSONB DEFAULT '[]'::jsonb,
    total_amount DECIMAL(10,2) DEFAULT 0.00,
    status TEXT DEFAULT 'pending',
    payment_method TEXT DEFAULT 'wallet',
    qr_code TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CREATE BAR_PRODUCTS TABLE
-- ===================================================================

DROP TABLE IF EXISTS public.bar_products CASCADE;

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

-- 4. CREATE QR_CODES TABLE
-- ===================================================================

DROP TABLE IF EXISTS public.qr_codes CASCADE;

CREATE TABLE public.qr_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL DEFAULT 'general',
    reference_id UUID,
    data JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. CREATE QR_SCANS TABLE
-- ===================================================================

DROP TABLE IF EXISTS public.qr_scans CASCADE;

CREATE TABLE public.qr_scans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    qr_code_id UUID REFERENCES public.qr_codes(id) ON DELETE CASCADE,
    scanned_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    scan_result TEXT DEFAULT 'success',
    scan_data JSONB DEFAULT '{}'::jsonb,
    location TEXT,
    device_info TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ENABLE RLS ON ALL TABLES
-- ===================================================================

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bar_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bar_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;

-- 7. CREATE SIMPLE RLS POLICIES
-- ===================================================================

-- Attendance policies
CREATE POLICY "attendance_access" ON public.attendance
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        (
            user_id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE id = auth.uid() AND role IN ('admin', 'instructor')
            )
        )
    );

-- Bar orders policies
CREATE POLICY "bar_orders_access" ON public.bar_orders
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        (
            user_id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE id = auth.uid() AND role = 'admin'
            )
        )
    );

-- Bar products policies
CREATE POLICY "bar_products_read" ON public.bar_products
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "bar_products_write" ON public.bar_products
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- QR codes policies
CREATE POLICY "qr_codes_access" ON public.qr_codes
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        (
            created_by = auth.uid() OR
            EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE id = auth.uid() AND role IN ('admin', 'instructor')
            )
        )
    );

-- QR scans policies
CREATE POLICY "qr_scans_access" ON public.qr_scans
    FOR ALL USING (
        auth.role() = 'authenticated' AND
        (
            scanned_by = auth.uid() OR
            EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE id = auth.uid() AND role IN ('admin', 'instructor')
            )
        )
    );

-- 8. CREATE INDEXES FOR PERFORMANCE
-- ===================================================================

-- Attendance indexes
CREATE INDEX idx_attendance_user_id ON public.attendance(user_id);
CREATE INDEX idx_attendance_course_id ON public.attendance(course_id);
CREATE INDEX idx_attendance_session_date ON public.attendance(session_date);
CREATE INDEX idx_attendance_created_at ON public.attendance(created_at);

-- Bar orders indexes
CREATE INDEX idx_bar_orders_user_id ON public.bar_orders(user_id);
CREATE INDEX idx_bar_orders_status ON public.bar_orders(status);
CREATE INDEX idx_bar_orders_created_at ON public.bar_orders(created_at);

-- Bar products indexes
CREATE INDEX idx_bar_products_category ON public.bar_products(category);
CREATE INDEX idx_bar_products_is_available ON public.bar_products(is_available);

-- QR codes indexes
CREATE INDEX idx_qr_codes_code ON public.qr_codes(code);
CREATE INDEX idx_qr_codes_type ON public.qr_codes(type);
CREATE INDEX idx_qr_codes_is_active ON public.qr_codes(is_active);

-- QR scans indexes
CREATE INDEX idx_qr_scans_qr_code_id ON public.qr_scans(qr_code_id);
CREATE INDEX idx_qr_scans_scanned_by ON public.qr_scans(scanned_by);
CREATE INDEX idx_qr_scans_created_at ON public.qr_scans(created_at);

-- 9. INSERT DEMO DATA
-- ===================================================================

-- Insert demo bar products
INSERT INTO public.bar_products (name, description, price, category, stock_quantity, is_available) VALUES
('Coca Cola', 'Bautura racoritoare 330ml', 5.00, 'bauturi', 50, true),
('Apa Minerala', 'Apa minerala naturala 500ml', 3.00, 'bauturi', 100, true),
('Red Bull', 'Bautura energizanta 250ml', 8.00, 'bauturi', 30, true),
('Sandwich Sunca', 'Sandwich cu sunca si cascaval', 12.00, 'mancare', 20, true),
('Cafea Espresso', 'Cafea espresso italiana', 6.00, 'bauturi', 999, true),
('Bere Heineken', 'Bere premium 330ml', 10.00, 'alcool', 40, true),
('Chips Lays', 'Chipsuri clasice 150g', 7.00, 'snacks', 25, true),
('Smoothie Fructe', 'Smoothie natural cu fructe', 15.00, 'bauturi', 15, true);

-- Insert demo QR codes (only if admin user exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.profiles WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf') THEN
        INSERT INTO public.qr_codes (code, type, data, is_active, created_by) VALUES
        ('QR_ATTENDANCE_DEMO_001', 'attendance', '{"purpose": "general_attendance", "location": "Sala de dans AIU"}', true, '9195288e-d88b-4178-b970-b13a7ed445cf'),
        ('QR_BAR_ORDER_DEMO_001', 'bar_order', '{"purpose": "bar_ordering", "location": "Bar AIU Dance"}', true, '9195288e-d88b-4178-b970-b13a7ed445cf');
    END IF;
END $$;

-- Insert demo bar order (only if admin user exists and products exist)
DO $$
DECLARE
    product_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM public.profiles WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf') THEN
        SELECT id INTO product_id FROM public.bar_products WHERE name = 'Coca Cola' LIMIT 1;
        
        IF product_id IS NOT NULL THEN
            INSERT INTO public.bar_orders (
                user_id, 
                items, 
                total_amount, 
                status, 
                payment_method,
                qr_code,
                created_at
            ) VALUES (
                '9195288e-d88b-4178-b970-b13a7ed445cf',
                jsonb_build_array(
                    jsonb_build_object(
                        'product_id', product_id,
                        'name', 'Coca Cola',
                        'price', 5.00,
                        'quantity', 2
                    )
                ),
                10.00,
                'completed',
                'wallet',
                'QR_ORDER_' || gen_random_uuid()::text,
                NOW() - INTERVAL '2 hours'
            );
        END IF;
    END IF;
END $$;

-- Insert demo attendance (only if admin user and course exist)
DO $$
DECLARE
    course_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM public.profiles WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf') THEN
        SELECT id INTO course_id FROM public.courses LIMIT 1;
        
        IF course_id IS NOT NULL THEN
            INSERT INTO public.attendance (
                user_id,
                course_id,
                session_date,
                status,
                notes,
                qr_code_used,
                created_at
            ) VALUES (
                '9195288e-d88b-4178-b970-b13a7ed445cf',
                course_id,
                CURRENT_DATE,
                'present',
                'Demo attendance via QR',
                'QR_ATTENDANCE_DEMO_001',
                NOW() - INTERVAL '1 day'
            );
        END IF;
    END IF;
END $$;

-- 10. CREATE FUNCTIONS FOR QR FUNCTIONALITY
-- ===================================================================

-- Function to generate QR code
CREATE OR REPLACE FUNCTION generate_qr_code(
    p_type TEXT DEFAULT 'general',
    p_reference_id UUID DEFAULT NULL,
    p_data JSONB DEFAULT '{}'::jsonb,
    p_expires_hours INTEGER DEFAULT 24
) RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
BEGIN
    new_code := 'QR_' || UPPER(p_type) || '_' || gen_random_uuid()::text;
    
    INSERT INTO public.qr_codes (
        code, 
        type, 
        reference_id, 
        data, 
        is_active, 
        expires_at, 
        created_by
    ) VALUES (
        new_code,
        p_type,
        p_reference_id,
        p_data,
        true,
        NOW() + (p_expires_hours || ' hours')::INTERVAL,
        auth.uid()
    );
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate and scan QR code
CREATE OR REPLACE FUNCTION scan_qr_code(
    p_code TEXT,
    p_scan_data JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB AS $$
DECLARE
    qr_record RECORD;
    scan_result TEXT := 'success';
    result_data JSONB;
BEGIN
    -- Find QR code
    SELECT * INTO qr_record 
    FROM public.qr_codes 
    WHERE code = p_code;
    
    IF NOT FOUND THEN
        scan_result := 'invalid';
        result_data := '{"error": "QR code not found"}'::jsonb;
    ELSIF NOT qr_record.is_active THEN
        scan_result := 'inactive';
        result_data := '{"error": "QR code is inactive"}'::jsonb;
    ELSIF qr_record.expires_at IS NOT NULL AND qr_record.expires_at < NOW() THEN
        scan_result := 'expired';
        result_data := '{"error": "QR code has expired"}'::jsonb;
    ELSE
        result_data := jsonb_build_object(
            'qr_id', qr_record.id,
            'type', qr_record.type,
            'reference_id', qr_record.reference_id,
            'data', qr_record.data
        );
    END IF;
    
    -- Record the scan
    INSERT INTO public.qr_scans (
        qr_code_id,
        scanned_by,
        scan_result,
        scan_data
    ) VALUES (
        qr_record.id,
        auth.uid(),
        scan_result,
        p_scan_data
    );
    
    RETURN jsonb_build_object(
        'result', scan_result,
        'data', result_data
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. GRANT PERMISSIONS
-- ===================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.attendance TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bar_orders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bar_products TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.qr_codes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.qr_scans TO authenticated;

GRANT EXECUTE ON FUNCTION generate_qr_code TO authenticated;
GRANT EXECUTE ON FUNCTION scan_qr_code TO authenticated;

-- 12. FINAL VERIFICATION
-- ===================================================================

-- Check table structures
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as column_count
FROM (
    VALUES 
    ('attendance'),
    ('bar_orders'), 
    ('bar_products'),
    ('qr_codes'),
    ('qr_scans')
) AS t(table_name);

-- Check data counts
SELECT 
    'attendance' as table_name, COUNT(*) as records FROM public.attendance
UNION ALL
SELECT 
    'bar_orders' as table_name, COUNT(*) as records FROM public.bar_orders
UNION ALL
SELECT 
    'bar_products' as table_name, COUNT(*) as records FROM public.bar_products
UNION ALL
SELECT 
    'qr_codes' as table_name, COUNT(*) as records FROM public.qr_codes
UNION ALL
SELECT 
    'qr_scans' as table_name, COUNT(*) as records FROM public.qr_scans;

-- Final success message
SELECT 
    '🎉 FINAL SQL REPAIR COMPLETED SUCCESSFULLY!' as status,
    'All tables recreated with correct structure and demo data!' as message;

-- ===================================================================
-- SUMMARY OF FIXES APPLIED:
-- ✅ Recreated attendance table with ALL required columns
-- ✅ Recreated bar_orders table with ALL required columns  
-- ✅ Created bar_products table for QR Bar functionality
-- ✅ Created qr_codes table with proper structure
-- ✅ Created qr_scans table for scan tracking
-- ✅ Added proper RLS policies for security
-- ✅ Created performance indexes
-- ✅ Added demo data for testing
-- ✅ Created QR generation and scanning functions
-- ✅ Granted all necessary permissions
-- ===================================================================
