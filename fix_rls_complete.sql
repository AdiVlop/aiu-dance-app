-- Script complet pentru a rezolva problemele RLS și email confirmation
-- Rulează acest script în Supabase SQL Editor

-- PAS 1: Verifică politicile existente
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- PAS 2: Șterge toate politicile existente pentru profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Anyone can create profile" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;

-- PAS 3: Dezactivează temporar RLS pentru a permite operațiuni
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- PAS 4: Verifică dacă există utilizatori neconfirmați
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    confirmation_sent_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- PAS 5: Confirma manual utilizatorii neconfirmați (opțional)
-- UPDATE auth.users 
-- SET email_confirmed_at = NOW(), confirmed_at = NOW()
-- WHERE email_confirmed_at IS NULL;

-- PAS 6: Reactivează RLS cu politicile corecte
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- PAS 7: Creează politicile noi
CREATE POLICY "Enable insert for all users" ON profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable read access for all users" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Enable update for users based on email" ON profiles
    FOR UPDATE USING (auth.jwt() ->> 'email' = email);

CREATE POLICY "Enable delete for users based on email" ON profiles
    FOR DELETE USING (auth.jwt() ->> 'email' = email);

-- PAS 8: Verifică politicile noi
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- PAS 9: Mesaj de confirmare
SELECT 'RLS policies updated successfully!' as status;
SELECT 'Email confirmation should now work properly!' as message;

-- Rulează acest script în Supabase SQL Editor

-- PAS 1: Verifică politicile existente
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- PAS 2: Șterge toate politicile existente pentru profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Anyone can create profile" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;

-- PAS 3: Dezactivează temporar RLS pentru a permite operațiuni
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- PAS 4: Verifică dacă există utilizatori neconfirmați
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    confirmation_sent_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- PAS 5: Confirma manual utilizatorii neconfirmați (opțional)
-- UPDATE auth.users 
-- SET email_confirmed_at = NOW(), confirmed_at = NOW()
-- WHERE email_confirmed_at IS NULL;

-- PAS 6: Reactivează RLS cu politicile corecte
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- PAS 7: Creează politicile noi
CREATE POLICY "Enable insert for all users" ON profiles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable read access for all users" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Enable update for users based on email" ON profiles
    FOR UPDATE USING (auth.jwt() ->> 'email' = email);

CREATE POLICY "Enable delete for users based on email" ON profiles
    FOR DELETE USING (auth.jwt() ->> 'email' = email);

-- PAS 8: Verifică politicile noi
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- PAS 9: Mesaj de confirmare
SELECT 'RLS policies updated successfully!' as status;
SELECT 'Email confirmation should now work properly!' as message;

