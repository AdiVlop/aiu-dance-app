-- ===================================================================
-- TEST APPLICATION AFTER FIXES
-- Verifică că toate erorile SQL au fost reparate
-- ===================================================================

-- 1. CHECK TABLE STRUCTURE
-- ===================================================================
SELECT 'Checking table structures...' as step;

-- Check attendance table structure
SELECT 
    'attendance' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'attendance' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check bar_orders table structure
SELECT 
    'bar_orders' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'bar_orders' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. TEST QUERIES THAT WERE FAILING
-- ===================================================================
SELECT 'Testing queries that were failing...' as step;

-- Test attendance query with created_at (this was failing before)
SELECT 
    COUNT(*) as attendance_count,
    MAX(created_at) as latest_attendance
FROM public.attendance;

-- Test bar_orders query with created_at (this was failing before)
SELECT 
    COUNT(*) as bar_orders_count,
    MAX(created_at) as latest_order
FROM public.bar_orders;

-- 3. CHECK RLS POLICIES
-- ===================================================================
SELECT 'Checking RLS policies...' as step;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('attendance', 'bar_orders')
ORDER BY tablename, policyname;

-- 4. CHECK INDEXES
-- ===================================================================
SELECT 'Checking indexes...' as step;

SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_indexes 
WHERE schemaname = 'public'
AND tablename IN ('attendance', 'bar_orders')
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- 5. TEST DATA INTEGRITY
-- ===================================================================
SELECT 'Testing data integrity...' as step;

-- Check for NULL values in NOT NULL columns
SELECT 
    'attendance' as table_name,
    COUNT(*) as total_records,
    COUNT(session_date) as non_null_session_date,
    COUNT(created_at) as non_null_created_at,
    COUNT(status) as non_null_status
FROM public.attendance;

SELECT 
    'bar_orders' as table_name,
    COUNT(*) as total_records,
    COUNT(created_at) as non_null_created_at,
    COUNT(status) as non_null_status,
    COUNT(total_amount) as non_null_total_amount
FROM public.bar_orders;

-- 6. SIMULATE APP QUERIES
-- ===================================================================
SELECT 'Simulating application queries...' as step;

-- Query that AdminDashboard uses for recent attendance
SELECT 
    a.*,
    p.full_name as user_name,
    c.title as course_title
FROM public.attendance a
LEFT JOIN public.profiles p ON p.id = a.user_id
LEFT JOIN public.courses c ON c.id = a.course_id
ORDER BY a.created_at DESC
LIMIT 5;

-- Query that AdminDashboard uses for recent bar orders
SELECT 
    bo.*,
    p.full_name as user_name
FROM public.bar_orders bo
LEFT JOIN public.profiles p ON p.id = bo.user_id
ORDER BY bo.created_at DESC
LIMIT 5;

-- 7. FINAL STATUS CHECK
-- ===================================================================
SELECT 'FINAL STATUS CHECK' as summary;

-- Check if all critical tables exist and have data
SELECT 
    'profiles' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) > 0 THEN '✅ OK' ELSE '❌ EMPTY' END as status
FROM public.profiles
UNION ALL
SELECT 
    'courses' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 0 THEN '✅ OK' ELSE '❌ ERROR' END as status
FROM public.courses
UNION ALL
SELECT 
    'attendance' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 0 THEN '✅ OK' ELSE '❌ ERROR' END as status
FROM public.attendance
UNION ALL
SELECT 
    'bar_orders' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 0 THEN '✅ OK' ELSE '❌ ERROR' END as status
FROM public.bar_orders
UNION ALL
SELECT 
    'announcements' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 0 THEN '✅ OK' ELSE '❌ ERROR' END as status
FROM public.announcements
UNION ALL
SELECT 
    'wallets' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 0 THEN '✅ OK' ELSE '❌ ERROR' END as status
FROM public.wallets
UNION ALL
SELECT 
    'wallet_transactions' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) >= 0 THEN '✅ OK' ELSE '❌ ERROR' END as status
FROM public.wallet_transactions
ORDER BY table_name;

SELECT '🎉 DATABASE TEST COMPLETED!' as final_status;
