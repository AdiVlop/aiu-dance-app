-- Script simplu pentru a rezolva problema RLS
-- Rulează acest script în Supabase SQL Editor

-- 1. Dezactivează temporar RLS pentru profiles
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 2. Verifică că RLS este dezactivat
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles';

-- 3. Mesaj de confirmare
SELECT 'RLS dezactivat pentru profiles table!' as status;
SELECT 'Acum poți să creezi profiluri fără probleme!' as message;

-- Rulează acest script în Supabase SQL Editor

-- 1. Dezactivează temporar RLS pentru profiles
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 2. Verifică că RLS este dezactivat
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles';

-- 3. Mesaj de confirmare
SELECT 'RLS dezactivat pentru profiles table!' as status;
SELECT 'Acum poți să creezi profiluri fără probleme!' as message;

