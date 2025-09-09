-- Script pentru a fixa constraint-ul în Supabase
-- Execută acest script în Supabase Dashboard > SQL Editor

-- 1. Verifică constraint-ul existent
SELECT conname, consrc
FROM pg_constraint
WHERE conname = 'profiles_role_check';

-- 2. Șterge constraint-ul existent
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

-- 3. Adaugă noul constraint care permite toate rolurile
ALTER TABLE profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('admin', 'student', 'instructor'));

-- 4. Verifică că constraint-ul a fost adăugat
SELECT conname, consrc
FROM pg_constraint
WHERE conname = 'profiles_role_check';