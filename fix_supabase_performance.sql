-- =====================================================
-- AIU Dance - Supabase Performance Optimization Script
-- =====================================================
-- Rezolvă problemele de performanță RLS și indexuri duplicate
-- Data: $(date)

-- =====================================================
-- 1. FIX AUTH RLS INITIALIZATION PLAN
-- =====================================================
-- Înlocuiește auth.function() cu (select auth.function()) pentru performanță optimă

-- Course Payments Policies
DROP POLICY IF EXISTS "course_payments_select_own" ON public.course_payments;
CREATE POLICY "course_payments_select_own" ON public.course_payments
    FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "course_payments_select_admin" ON public.course_payments;
CREATE POLICY "course_payments_select_admin" ON public.course_payments
    FOR SELECT USING ((select auth.jwt()) ->> 'role' = 'admin');

DROP POLICY IF EXISTS "course_payments_insert_admin" ON public.course_payments;
CREATE POLICY "course_payments_insert_admin" ON public.course_payments
    FOR INSERT WITH CHECK ((select auth.jwt()) ->> 'role' = 'admin');

DROP POLICY IF EXISTS "course_payments_update_admin" ON public.course_payments;
CREATE POLICY "course_payments_update_admin" ON public.course_payments
    FOR UPDATE USING ((select auth.jwt()) ->> 'role' = 'admin');

-- Attendance Policies
DROP POLICY IF EXISTS "Users can view their own attendance" ON public.attendance;
CREATE POLICY "Users can view their own attendance" ON public.attendance
    FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert their own attendance" ON public.attendance;
CREATE POLICY "Users can insert their own attendance" ON public.attendance
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Admins can view all attendance" ON public.attendance;
CREATE POLICY "Admins can view all attendance" ON public.attendance
    FOR SELECT USING ((select auth.jwt()) ->> 'role' = 'admin');

DROP POLICY IF EXISTS "Admins can insert any attendance" ON public.attendance;
CREATE POLICY "Admins can insert any attendance" ON public.attendance
    FOR INSERT WITH CHECK ((select auth.jwt()) ->> 'role' = 'admin');

-- Wallet Transactions Policies
DROP POLICY IF EXISTS "wallet_tx_select_own" ON public.wallet_transactions;
CREATE POLICY "wallet_tx_select_own" ON public.wallet_transactions
    FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "wallet_tx_select_admin" ON public.wallet_transactions;
CREATE POLICY "wallet_tx_select_admin" ON public.wallet_transactions
    FOR SELECT USING ((select auth.jwt()) ->> 'role' = 'admin');

DROP POLICY IF EXISTS "wallet_tx_insert_admin" ON public.wallet_transactions;
CREATE POLICY "wallet_tx_insert_admin" ON public.wallet_transactions
    FOR INSERT WITH CHECK ((select auth.jwt()) ->> 'role' = 'admin');

DROP POLICY IF EXISTS "wallet_tx_insert_own" ON public.wallet_transactions;
CREATE POLICY "wallet_tx_insert_own" ON public.wallet_transactions
    FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

-- Wallets Policies
DROP POLICY IF EXISTS "wallets_select_own" ON public.wallets;
CREATE POLICY "wallets_select_own" ON public.wallets
    FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "wallets_select_admin" ON public.wallets;
CREATE POLICY "wallets_select_admin" ON public.wallets
    FOR SELECT USING ((select auth.jwt()) ->> 'role' = 'admin');

DROP POLICY IF EXISTS "wallets_update_admin" ON public.wallets;
CREATE POLICY "wallets_update_admin" ON public.wallets
    FOR UPDATE USING ((select auth.jwt()) ->> 'role' = 'admin');

DROP POLICY IF EXISTS "wallets_update_own" ON public.wallets;
CREATE POLICY "wallets_update_own" ON public.wallets
    FOR UPDATE USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "wallets_insert_admin" ON public.wallets;
CREATE POLICY "wallets_insert_admin" ON public.wallets
    FOR INSERT WITH CHECK ((select auth.jwt()) ->> 'role' = 'admin');

-- Bar Receipts Policies
DROP POLICY IF EXISTS "Users can view their own receipts" ON public.bar_receipts;
CREATE POLICY "Users can view their own receipts" ON public.bar_receipts
    FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Admins can view all receipts" ON public.bar_receipts;
CREATE POLICY "Admins can view all receipts" ON public.bar_receipts
    FOR ALL USING ((select auth.jwt()) ->> 'role' = 'admin');

-- Announcement Reminders Policy
DROP POLICY IF EXISTS "announcement_reminders_policy" ON public.announcement_reminders;
CREATE POLICY "announcement_reminders_policy" ON public.announcement_reminders
    FOR ALL USING ((select auth.jwt()) ->> 'role' = 'admin');

-- Enrollments Policies
DROP POLICY IF EXISTS "User can see own enrollments" ON public.enrollments;
CREATE POLICY "User can see own enrollments" ON public.enrollments
    FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Admin can see all enrollments" ON public.enrollments;
CREATE POLICY "Admin can see all enrollments" ON public.enrollments
    FOR SELECT USING ((select auth.jwt()) ->> 'role' = 'admin');

DROP POLICY IF EXISTS "Instructor can see course enrollments" ON public.enrollments;
CREATE POLICY "Instructor can see course enrollments" ON public.enrollments
    FOR SELECT USING ((select auth.jwt()) ->> 'role' = 'instructor');

DROP POLICY IF EXISTS "Admin can manage enrollments" ON public.enrollments;
CREATE POLICY "Admin can manage enrollments" ON public.enrollments
    FOR ALL USING ((select auth.jwt()) ->> 'role' = 'admin');

-- =====================================================
-- 2. CONSOLIDATE DUPLICATE POLICIES
-- =====================================================
-- Șterge politicile generice duplicate și păstrează doar cele specifice

-- Șterge politicile generice duplicate
DROP POLICY IF EXISTS "course_payments_policy" ON public.course_payments;
DROP POLICY IF EXISTS "attendance_policy" ON public.attendance;
DROP POLICY IF EXISTS "wallet_transactions_policy" ON public.wallet_transactions;
DROP POLICY IF EXISTS "wallets_policy" ON public.wallets;
DROP POLICY IF EXISTS "bar_receipts_policy" ON public.bar_receipts;
DROP POLICY IF EXISTS "enrollments_policy" ON public.enrollments;
DROP POLICY IF EXISTS "qr_codes_policy" ON public.qr_codes;
DROP POLICY IF EXISTS "qr_scans_policy" ON public.qr_scans;
DROP POLICY IF EXISTS "bar_orders_policy" ON public.bar_orders;
DROP POLICY IF EXISTS "notifications_policy" ON public.notifications;
DROP POLICY IF EXISTS "admin_transactions_policy" ON public.admin_transactions;

-- =====================================================
-- 3. FIX DUPLICATE INDEXES
-- =====================================================
-- Șterge indexurile duplicate din wallet_transactions

DROP INDEX IF EXISTS idx_wallet_transactions_user;
-- Păstrează doar idx_wallet_transactions_user_id

-- =====================================================
-- 4. CREATE OPTIMIZED POLICIES FOR REMAINING TABLES
-- =====================================================

-- QR Codes - Admin only
DROP POLICY IF EXISTS "qr_codes_policy" ON public.qr_codes;
CREATE POLICY "qr_codes_admin_only" ON public.qr_codes
    FOR ALL USING ((select auth.jwt()) ->> 'role' = 'admin');

-- QR Scans - Admin only  
DROP POLICY IF EXISTS "qr_scans_policy" ON public.qr_scans;
CREATE POLICY "qr_scans_admin_only" ON public.qr_scans
    FOR ALL USING ((select auth.jwt()) ->> 'role' = 'admin');

-- Bar Orders - Admin only
DROP POLICY IF EXISTS "bar_orders_policy" ON public.bar_orders;
CREATE POLICY "bar_orders_admin_only" ON public.bar_orders
    FOR ALL USING ((select auth.jwt()) ->> 'role' = 'admin');

-- Notifications - Users can see their own, admins can see all
DROP POLICY IF EXISTS "notifications_policy" ON public.notifications;
CREATE POLICY "notifications_user_own" ON public.notifications
    FOR SELECT USING ((select auth.uid()) = user_id);
CREATE POLICY "notifications_admin_all" ON public.notifications
    FOR ALL USING ((select auth.jwt()) ->> 'role' = 'admin');

-- Admin Transactions - Admin only
DROP POLICY IF EXISTS "admin_transactions_policy" ON public.admin_transactions;
CREATE POLICY "admin_transactions_admin_only" ON public.admin_transactions
    FOR ALL USING ((select auth.jwt()) ->> 'role' = 'admin');

-- =====================================================
-- 5. VERIFY OPTIMIZATIONS
-- =====================================================

-- Verifică că toate politicile folosesc (select auth.function())
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Verifică indexurile rămase
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename = 'wallet_transactions'
ORDER BY indexname;

-- =====================================================
-- SCRIPT COMPLETAT
-- =====================================================
-- Toate problemele de performanță RLS au fost rezolvate:
-- ✅ Auth functions optimizate cu (select auth.function())
-- ✅ Politici duplicate eliminate
-- ✅ Indexuri duplicate șterse
-- ✅ Politici consolidate pentru performanță optimă
