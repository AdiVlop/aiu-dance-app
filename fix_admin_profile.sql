-- Script pentru a fixa profilul admin cu ID-ul specificat
-- Execută acest script în Supabase Dashboard > SQL Editor

-- 1. Verifică dacă există utilizatorul în auth.users
SELECT id, email, user_metadata FROM auth.users WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf';

-- 2. Verifică dacă există profilul în profiles
SELECT * FROM profiles WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf';

-- 3. Creează sau actualizează profilul admin
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
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  role = 'admin',
  is_active = true,
  updated_at = NOW();

-- 4. Verifică că profilul a fost creat/actualizat
SELECT * FROM profiles WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf';

-- 5. Verifică constraint-ul pentru roluri
SELECT conname, consrc FROM pg_constraint WHERE conname = 'profiles_role_check';
