-- 🧪 ULTRA SIMPLE TEST - DOAR CE ESENȚIAL
-- =========================================
-- Execută acest script în Supabase Dashboard > SQL Editor

-- 1. Disable RLS pentru toate tabelele
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE courses DISABLE ROW LEVEL SECURITY;
ALTER TABLE wallets DISABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance DISABLE ROW LEVEL SECURITY;

-- 2. Creează admin profile dacă nu există
INSERT INTO profiles (
    id, 
    email, 
    full_name, 
    role, 
    is_active, 
    created_at, 
    updated_at
) VALUES (
    '9195288e-d88b-4178-b970-b13a7ed445cf',
    'adrian@payai-x.com',
    'Admin',
    'admin',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    role = 'admin',
    is_active = true,
    updated_at = NOW();

-- 3. Verifică că admin profile există
SELECT id, email, role, is_active FROM profiles WHERE email = 'adrian@payai-x.com';

-- ✅ GATA! Acum aplicația ar trebui să funcționeze!
