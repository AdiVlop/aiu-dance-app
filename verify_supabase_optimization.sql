-- =====================================================
-- AIU Dance - Supabase Performance Verification Script
-- =====================================================
-- Verifică că optimizările RLS au fost aplicate corect

-- =====================================================
-- 1. VERIFICĂ AUTH FUNCTION OPTIMIZATIONS
-- =====================================================

-- Verifică că toate politicile folosesc (select auth.function()) în loc de auth.function()
SELECT 
    'RLS Policy Check' as check_type,
    schemaname,
    tablename,
    policyname,
    CASE 
        WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' THEN '❌ NEEDS OPTIMIZATION'
        WHEN qual LIKE '%auth.jwt()%' AND qual NOT LIKE '%(select auth.jwt())%' THEN '❌ NEEDS OPTIMIZATION'
        WHEN qual LIKE '%(select auth.uid())%' OR qual LIKE '%(select auth.jwt())%' THEN '✅ OPTIMIZED'
        ELSE 'ℹ️ NO AUTH FUNCTIONS'
    END as optimization_status,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 2. VERIFICĂ DUPLICATE POLICIES
-- =====================================================

-- Verifică politicile duplicate pentru același rol și acțiune
SELECT 
    'Duplicate Policies Check' as check_type,
    tablename,
    roles,
    cmd as action,
    COUNT(*) as policy_count,
    STRING_AGG(policyname, ', ') as policy_names,
    CASE 
        WHEN COUNT(*) > 1 THEN '❌ DUPLICATE POLICIES FOUND'
        ELSE '✅ NO DUPLICATES'
    END as status
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename, roles, cmd
HAVING COUNT(*) > 1
ORDER BY tablename, roles, cmd;

-- =====================================================
-- 3. VERIFICĂ DUPLICATE INDEXES
-- =====================================================

-- Verifică indexurile duplicate
SELECT 
    'Duplicate Indexes Check' as check_type,
    tablename,
    indexname,
    indexdef,
    CASE 
        WHEN tablename = 'wallet_transactions' AND indexname = 'idx_wallet_transactions_user' THEN '❌ SHOULD BE DROPPED'
        ELSE '✅ OK'
    END as status
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- =====================================================
-- 4. PERFORMANCE SUMMARY
-- =====================================================

-- Rezumat performanță
SELECT 
    'Performance Summary' as check_type,
    'Total Tables with RLS' as metric,
    COUNT(DISTINCT tablename) as value
FROM pg_policies 
WHERE schemaname = 'public'

UNION ALL

SELECT 
    'Performance Summary' as check_type,
    'Total RLS Policies' as metric,
    COUNT(*) as value
FROM pg_policies 
WHERE schemaname = 'public'

UNION ALL

SELECT 
    'Performance Summary' as check_type,
    'Optimized Auth Functions' as metric,
    COUNT(*) as value
FROM pg_policies 
WHERE schemaname = 'public'
AND (qual LIKE '%(select auth.uid())%' OR qual LIKE '%(select auth.jwt())%')

UNION ALL

SELECT 
    'Performance Summary' as check_type,
    'Tables with Multiple Policies' as metric,
    COUNT(DISTINCT tablename) as value
FROM (
    SELECT tablename, roles, cmd, COUNT(*) as policy_count
    FROM pg_policies 
    WHERE schemaname = 'public'
    GROUP BY tablename, roles, cmd
    HAVING COUNT(*) > 1
) duplicates;

-- =====================================================
-- 5. RECOMMENDATIONS
-- =====================================================

SELECT 
    'Recommendations' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE schemaname = 'public' 
            AND (qual LIKE '%auth.uid()%' OR qual LIKE '%auth.jwt()%')
            AND qual NOT LIKE '%(select auth.uid())%' 
            AND qual NOT LIKE '%(select auth.jwt())%'
        ) THEN '❌ Run fix_supabase_performance.sql to optimize auth functions'
        ELSE '✅ All auth functions are optimized'
    END as recommendation

UNION ALL

SELECT 
    'Recommendations' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT tablename, roles, cmd, COUNT(*) as policy_count
            FROM pg_policies 
            WHERE schemaname = 'public'
            GROUP BY tablename, roles, cmd
            HAVING COUNT(*) > 1
        ) THEN '❌ Consolidate duplicate policies for better performance'
        ELSE '✅ No duplicate policies found'
    END as recommendation;
