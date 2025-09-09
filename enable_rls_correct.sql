-- Script pentru a reactiva RLS cu politicile corecte
-- Rulează acest script în Supabase SQL Editor DUPĂ ce ai testat înregistrarea

-- 1. Șterge toate politicile existente
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Anyone can create profile" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON profiles;

-- 2. Reactivează RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 3. Creează politicile corecte
CREATE POLICY "Enable insert for all users" ON profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable read access for all users" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Enable update for users based on email" ON profiles
    FOR UPDATE USING (auth.jwt() ->> 'email' = email);

CREATE POLICY "Enable delete for users based on email" ON profiles
    FOR DELETE USING (auth.jwt() ->> 'email' = email);

-- 4. Verifică politicile
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 5. Mesaj de confirmare
SELECT 'RLS reactivat cu politicile corecte!' as status;

-- Rulează acest script în Supabase SQL Editor DUPĂ ce ai testat înregistrarea

-- 1. Șterge toate politicile existente
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Anyone can create profile" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON profiles;

-- 2. Reactivează RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 3. Creează politicile corecte
CREATE POLICY "Enable insert for all users" ON profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable read access for all users" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Enable update for users based on email" ON profiles
    FOR UPDATE USING (auth.jwt() ->> 'email' = email);

CREATE POLICY "Enable delete for users based on email" ON profiles
    FOR DELETE USING (auth.jwt() ->> 'email' = email);

-- 4. Verifică politicile
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 5. Mesaj de confirmare
SELECT 'RLS reactivat cu politicile corecte!' as status;

