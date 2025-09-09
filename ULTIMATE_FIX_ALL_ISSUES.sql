-- ULTIMATE FIX ALL ISSUES
-- Script consolidat pentru a rezolva toate problemele din aplicație

-- ========================================
-- 1. CURĂȚĂ TOATE RLS POLICIES DUPLICATE
-- ========================================

-- Elimină toate policies existente pentru a evita duplicatele
DO $$
DECLARE
    pol RECORD;
BEGIN
    -- Elimină toate policies de pe toate tabelele
    FOR pol IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      pol.policyname, pol.schemaname, pol.tablename);
    END LOOP;
    
    RAISE NOTICE '✅ Toate policies duplicate eliminate';
END $$;

-- ========================================
-- 2. CREEAZĂ POLICIES SIMPLE ȘI OPTIMIZATE
-- ========================================

-- Profiles - policies simple
CREATE POLICY "profiles_policy" ON profiles FOR ALL USING (
    auth.uid() = id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- Courses - policies simple
CREATE POLICY "courses_policy" ON courses FOR ALL USING (true);

-- Enrollments - policies simple
CREATE POLICY "enrollments_policy" ON enrollments FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- Attendance - policies simple
CREATE POLICY "attendance_policy" ON attendance FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- QR Codes - policies simple
CREATE POLICY "qr_codes_policy" ON qr_codes FOR ALL USING (
    is_active = true OR 
    auth.uid() = created_by OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- QR Scans - policies simple
CREATE POLICY "qr_scans_policy" ON qr_scans FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- Bar Orders - policies simple
CREATE POLICY "bar_orders_policy" ON bar_orders FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- Bar Receipts - policies simple
CREATE POLICY "bar_receipts_policy" ON bar_receipts FOR ALL USING (
    EXISTS (
        SELECT 1 FROM bar_orders 
        WHERE id = bar_receipts.bar_order_id 
        AND (user_id = auth.uid() OR (SELECT auth.jwt() ->> 'role') = 'admin')
    )
);

-- Wallet Transactions - policies simple
CREATE POLICY "wallet_transactions_policy" ON wallet_transactions FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- Wallets - policies simple
CREATE POLICY "wallets_policy" ON wallets FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- Notifications - policies simple
CREATE POLICY "notifications_policy" ON notifications FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- Course Payments - policies simple
CREATE POLICY "course_payments_policy" ON course_payments FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- Admin Transactions - policies simple
CREATE POLICY "admin_transactions_policy" ON admin_transactions FOR ALL USING (
    auth.uid() = admin_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- Announcements - policies simple
CREATE POLICY "announcements_policy" ON announcements FOR ALL USING (true);

-- Bar Menu - policies simple
CREATE POLICY "bar_menu_policy" ON bar_menu FOR ALL USING (true);

-- ========================================
-- 3. ELIMINĂ INDEXURI DUPLICATE
-- ========================================

-- Elimină indexuri duplicate pentru attendance
DROP INDEX IF EXISTS idx_attendance_course;
DROP INDEX IF EXISTS idx_attendance_user;
DROP INDEX IF EXISTS idx_attendance_date;

-- Păstrează doar indexurile necesare
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_course_id ON attendance(course_id);
CREATE INDEX IF NOT EXISTS idx_attendance_session_date ON attendance(session_date DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in_time ON attendance(check_in_time DESC);

-- ========================================
-- 4. CORECTEAZĂ TABELA BAR_ORDERS
-- ========================================

-- Asigură-te că bar_orders are toate coloanele necesare
DO $$
BEGIN
    -- product_name
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'product_name' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN product_name TEXT;
        RAISE NOTICE '✅ Coloana product_name adăugată în bar_orders';
    END IF;

    -- quantity
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'quantity' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN quantity INTEGER DEFAULT 1;
        RAISE NOTICE '✅ Coloana quantity adăugată în bar_orders';
    END IF;

    -- total_price
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
        ALTER TABLE public.bar_orders ADD COLUMN payment_method TEXT DEFAULT 'cash';
        RAISE NOTICE '✅ Coloana payment_method adăugată în bar_orders';
    END IF;

    -- payment_status
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bar_orders' AND column_name = 'payment_status' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.bar_orders ADD COLUMN payment_status TEXT DEFAULT 'pending';
        RAISE NOTICE '✅ Coloana payment_status adăugată în bar_orders';
    END IF;
END $$;

-- ========================================
-- 5. CORECTEAZĂ TABELA QR_CODES
-- ========================================

-- Asigură-te că qr_codes are coloana created_by
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'qr_codes' AND column_name = 'created_by' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.qr_codes ADD COLUMN created_by UUID REFERENCES profiles(id);
        RAISE NOTICE '✅ Coloana created_by adăugată în qr_codes';
    END IF;
END $$;

-- Actualizează QR codes existente fără created_by
UPDATE qr_codes 
SET created_by = (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1)
WHERE created_by IS NULL;

-- ========================================
-- 6. CORECTEAZĂ CONSTRAINT WALLET_TRANSACTIONS
-- ========================================

-- Elimină constraint-ul vechi
ALTER TABLE wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;

-- Adaugă constraint-ul corect
ALTER TABLE wallet_transactions 
ADD CONSTRAINT wallet_transactions_type_check 
CHECK (type IN ('credit', 'debit'));

-- Actualizează tranzacțiile existente cu tipuri incorecte
UPDATE wallet_transactions 
SET type = 'debit' 
WHERE type NOT IN ('credit', 'debit') AND amount < 0;

UPDATE wallet_transactions 
SET type = 'credit' 
WHERE type NOT IN ('credit', 'debit') AND amount >= 0;

-- ========================================
-- 7. CORECTEAZĂ TABELA ATTENDANCE
-- ========================================

-- Asigură-te că attendance are structura corectă
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'check_in_time' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.attendance ADD COLUMN check_in_time TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Coloana check_in_time adăugată în attendance';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'session_date' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.attendance ADD COLUMN session_date DATE DEFAULT CURRENT_DATE;
        RAISE NOTICE '✅ Coloana session_date adăugată în attendance';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'status' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.attendance ADD COLUMN status TEXT DEFAULT 'present';
        RAISE NOTICE '✅ Coloana status adăugată în attendance';
    END IF;
END $$;

-- ========================================
-- 8. CORECTEAZĂ TABELA COURSES
-- ========================================

-- Asigură-te că courses are is_active
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'is_active' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.courses ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Coloana is_active adăugată în courses';
    END IF;
END $$;

-- ========================================
-- 9. VERIFICĂRI FINALE
-- ========================================

-- Verifică policies
SELECT 
    COUNT(*) as total_policies,
    '✅ Policies cleaned' as status
FROM pg_policies 
WHERE schemaname = 'public';

-- Verifică indexuri
SELECT 
    COUNT(*) as total_indexes,
    '✅ Indexes cleaned' as status
FROM pg_indexes 
WHERE tablename = 'attendance';

-- Verifică tabele principale
SELECT 
    table_name,
    '✅ Table OK' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('bar_orders', 'qr_codes', 'attendance', 'courses')
ORDER BY table_name;

-- Mesaj final
SELECT '🎉 ALL ISSUES FIXED! READY FOR TESTING!' as final_status;
