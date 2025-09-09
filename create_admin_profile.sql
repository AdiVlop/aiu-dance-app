-- Script pentru a crea profilul admin în Supabase
-- Execută acest script în Supabase Dashboard > SQL Editor

-- 1. Verifică dacă există deja profilul admin
SELECT * FROM profiles WHERE email = 'adrian@payai-x.com';

-- 2. Creează profilul admin dacă nu există
INSERT INTO profiles (
  id,
  email,
  full_name,
  role,
  is_active,
  created_at,
  updated_at
) VALUES (
  '9195288e-d88b-4178-b970-b13a7ed445cf', -- ID-ul din auth.users
  'adrian@payai-x.com',
  'Admin',
  'admin',
  true,
  NOW(),
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- 3. Verifică că profilul a fost creat/actualizat
SELECT * FROM profiles WHERE email = 'adrian@payai-x.com';
