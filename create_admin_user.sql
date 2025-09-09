-- Script pentru crearea unui utilizator admin
-- Rulează acest script în Supabase SQL Editor

-- PAS 1: Verifică dacă există deja un utilizator admin
SELECT id, email, full_name, role FROM profiles WHERE role = 'admin';

-- PAS 2: Dacă nu există admin, creează unul
-- Înlocuiește 'your-email@example.com' cu email-ul tău real
INSERT INTO profiles (
    id,
    email,
    full_name,
    role,
    is_active,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'adriantraderd@gmail.com',  -- Înlocuiește cu email-ul tău
    'Administrator AIU Dance',
    'admin',
    true,
    NOW(),
    NOW()
) ON CONFLICT (email) DO UPDATE SET
    role = 'admin',
    updated_at = NOW();

-- PAS 3: Verifică că utilizatorul admin a fost creat
SELECT id, email, full_name, role, created_at FROM profiles WHERE role = 'admin';

-- PAS 4: Verifică toate rolurile din baza de date
SELECT DISTINCT role, COUNT(*) as count FROM profiles GROUP BY role;
