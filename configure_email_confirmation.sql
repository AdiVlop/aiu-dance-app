-- Script pentru a configura email confirmation în Supabase
-- Rulează acest script în Supabase SQL Editor

-- PAS 1: Verifică configurația actuală
SELECT 
    key,
    value
FROM auth.config 
WHERE key IN ('SITE_URL', 'DISABLE_SIGNUP', 'ENABLE_EMAIL_CONFIRMATIONS');

-- PAS 2: Verifică utilizatorii neconfirmați
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    confirmation_sent_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- PAS 3: Mesaj de instrucțiuni
SELECT 'CONFIGURARE SUPABASE DASHBOARD:' as instruction;
SELECT '1. Mergi la Authentication > Settings > Email Auth' as step1;
SELECT '2. Activează "Confirm email" (check the box)' as step2;
SELECT '3. Setează Site URL: http://localhost:3000' as step3;
SELECT '4. Setează Redirect URLs: http://localhost:3000/auth/callback' as step4;
SELECT '5. Salvează setările' as step5;

-- PAS 4: Verifică dacă există template-uri de email
SELECT 'Verifică template-urile de email în Authentication > Email Templates' as email_templates;

-- PAS 5: Mesaj final
SELECT 'După configurare, email-urile de confirmare vor funcționa!' as final_message;

-- Rulează acest script în Supabase SQL Editor

-- PAS 1: Verifică configurația actuală
SELECT 
    key,
    value
FROM auth.config 
WHERE key IN ('SITE_URL', 'DISABLE_SIGNUP', 'ENABLE_EMAIL_CONFIRMATIONS');

-- PAS 2: Verifică utilizatorii neconfirmați
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    confirmation_sent_at
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- PAS 3: Mesaj de instrucțiuni
SELECT 'CONFIGURARE SUPABASE DASHBOARD:' as instruction;
SELECT '1. Mergi la Authentication > Settings > Email Auth' as step1;
SELECT '2. Activează "Confirm email" (check the box)' as step2;
SELECT '3. Setează Site URL: http://localhost:3000' as step3;
SELECT '4. Setează Redirect URLs: http://localhost:3000/auth/callback' as step4;
SELECT '5. Salvează setările' as step5;

-- PAS 4: Verifică dacă există template-uri de email
SELECT 'Verifică template-urile de email în Authentication > Email Templates' as email_templates;

-- PAS 5: Mesaj final
SELECT 'După configurare, email-urile de confirmare vor funcționa!' as final_message;

