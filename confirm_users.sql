-- Script pentru a confirma manual utilizatorii neconfirmați
-- Rulează acest script în Supabase SQL Editor

-- 1. Verifică utilizatorii neconfirmați
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    confirmation_sent_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- 2. Confirmă manual utilizatorii neconfirmați
UPDATE auth.users 
SET 
    email_confirmed_at = NOW(),
    confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- 3. Verifică rezultatul
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users 
WHERE email_confirmed_at IS NOT NULL
ORDER BY created_at DESC;

-- 4. Mesaj de confirmare
SELECT 'Utilizatorii neconfirmați au fost confirmați manual!' as status;

-- Rulează acest script în Supabase SQL Editor

-- 1. Verifică utilizatorii neconfirmați
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    confirmation_sent_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- 2. Confirmă manual utilizatorii neconfirmați
UPDATE auth.users 
SET 
    email_confirmed_at = NOW(),
    confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- 3. Verifică rezultatul
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users 
WHERE email_confirmed_at IS NOT NULL
ORDER BY created_at DESC;

-- 4. Mesaj de confirmare
SELECT 'Utilizatorii neconfirmați au fost confirmați manual!' as status;

