-- Script pentru a dezactiva confirmarea email-ului în Supabase
-- Rulează acest script în Supabase SQL Editor

-- PAS 1: Verifică configurația actuală
SELECT 
    key,
    value
FROM auth.config 
WHERE key IN ('SITE_URL', 'DISABLE_SIGNUP', 'ENABLE_EMAIL_CONFIRMATIONS');

-- PAS 2: Dezactivează confirmarea email-ului (dacă este posibil prin SQL)
-- Nota: Această setare se face de obicei în Dashboard-ul Supabase
-- Mergi la Authentication > Settings > Email Auth > Confirm email

-- PAS 3: Verifică utilizatorii neconfirmați
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- PAS 4: Confirmă manual utilizatorii neconfirmați (opțional)
-- ATENȚIE: Rulează doar dacă vrei să confirmi manual utilizatorii
-- UPDATE auth.users 
-- SET email_confirmed_at = NOW()
-- WHERE email_confirmed_at IS NULL;

-- PAS 5: Mesaj de confirmare
SELECT 'Verifică configurația email în Supabase Dashboard!' as status;
SELECT 'Mergi la Authentication > Settings > Email Auth' as instruction;
SELECT 'Dezactivează "Confirm email" pentru a permite login fără confirmare' as next_step;

-- Rulează acest script în Supabase SQL Editor

-- PAS 1: Verifică configurația actuală
SELECT 
    key,
    value
FROM auth.config 
WHERE key IN ('SITE_URL', 'DISABLE_SIGNUP', 'ENABLE_EMAIL_CONFIRMATIONS');

-- PAS 2: Dezactivează confirmarea email-ului (dacă este posibil prin SQL)
-- Nota: Această setare se face de obicei în Dashboard-ul Supabase
-- Mergi la Authentication > Settings > Email Auth > Confirm email

-- PAS 3: Verifică utilizatorii neconfirmați
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- PAS 4: Confirmă manual utilizatorii neconfirmați (opțional)
-- ATENȚIE: Rulează doar dacă vrei să confirmi manual utilizatorii
-- UPDATE auth.users 
-- SET email_confirmed_at = NOW()
-- WHERE email_confirmed_at IS NULL;

-- PAS 5: Mesaj de confirmare
SELECT 'Verifică configurația email în Supabase Dashboard!' as status;
SELECT 'Mergi la Authentication > Settings > Email Auth' as instruction;
SELECT 'Dezactivează "Confirm email" pentru a permite login fără confirmare' as next_step;

