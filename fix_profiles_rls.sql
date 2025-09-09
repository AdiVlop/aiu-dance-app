-- Script pentru a rezolva problema RLS cu tabela profiles
-- Rulează acest script în Supabase SQL Editor

-- PAS 1: Șterge politicile existente pentru profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

-- PAS 2: Creează politici noi pentru profiles
-- Permite utilizatorilor să își vadă propriul profil
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Permite utilizatorilor să își actualizeze propriul profil
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Permite oricui să creeze un profil nou (pentru înregistrare)
CREATE POLICY "Anyone can create profile" ON profiles
    FOR INSERT WITH CHECK (true);

-- Permite adminilor să vadă toate profilele
CREATE POLICY "Admins can view all profiles" ON profiles
    FOR ALL USING (is_user_admin(auth.uid()));

-- PAS 3: Verifică că politicile au fost create
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- PAS 4: Testează că RLS este activat
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles';

-- PAS 5: Mesaj de confirmare
SELECT 'Politicile RLS pentru tabela profiles au fost actualizate cu succes!' as status;

-- Rulează acest script în Supabase SQL Editor

-- PAS 1: Șterge politicile existente pentru profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

-- PAS 2: Creează politici noi pentru profiles
-- Permite utilizatorilor să își vadă propriul profil
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Permite utilizatorilor să își actualizeze propriul profil
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Permite oricui să creeze un profil nou (pentru înregistrare)
CREATE POLICY "Anyone can create profile" ON profiles
    FOR INSERT WITH CHECK (true);

-- Permite adminilor să vadă toate profilele
CREATE POLICY "Admins can view all profiles" ON profiles
    FOR ALL USING (is_user_admin(auth.uid()));

-- PAS 3: Verifică că politicile au fost create
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- PAS 4: Testează că RLS este activat
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles';

-- PAS 5: Mesaj de confirmare
SELECT 'Politicile RLS pentru tabela profiles au fost actualizate cu succes!' as status;

