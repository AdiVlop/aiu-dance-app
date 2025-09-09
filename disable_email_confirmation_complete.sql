-- Script pentru a dezactiva email confirmation în Supabase
-- Acest script documentează pașii necesari în Supabase Dashboard

-- IMPORTANT: Acest script NU se rulează în SQL Editor!
-- Este doar pentru documentare.

-- ========================================
-- PAȘI PENTRU SUPABASE DASHBOARD:
-- ========================================

-- PAS 1: Deschide Supabase Dashboard
-- PAS 2: Mergi la "Authentication" → "Settings" → "Email Auth"
-- PAS 3: DEZACTIVEAZĂ "Confirm email" (debifează căsuța)
-- PAS 4: Setează Site URL: http://localhost:3000
-- PAS 5: Setează Redirect URLs: http://localhost:3000/auth/callback
-- PAS 6: Salvează modificările

-- ========================================
-- ALTERNATIV: Configurare prin SQL (dacă este posibil)
-- ========================================

-- Verifică configurația actuală
SELECT 
    key,
    value
FROM auth.config 
WHERE key IN ('SITE_URL', 'DISABLE_SIGNUP', 'ENABLE_EMAIL_CONFIRMATIONS');

-- Mesaj final
SELECT 'După configurare, utilizatorii se vor putea înregistra și conecta imediat!' as final_message;

-- Acest script documentează pașii necesari în Supabase Dashboard

-- IMPORTANT: Acest script NU se rulează în SQL Editor!
-- Este doar pentru documentare.

-- ========================================
-- PAȘI PENTRU SUPABASE DASHBOARD:
-- ========================================

-- PAS 1: Deschide Supabase Dashboard
-- PAS 2: Mergi la "Authentication" → "Settings" → "Email Auth"
-- PAS 3: DEZACTIVEAZĂ "Confirm email" (debifează căsuța)
-- PAS 4: Setează Site URL: http://localhost:3000
-- PAS 5: Setează Redirect URLs: http://localhost:3000/auth/callback
-- PAS 6: Salvează modificările

-- ========================================
-- ALTERNATIV: Configurare prin SQL (dacă este posibil)
-- ========================================

-- Verifică configurația actuală
SELECT 
    key,
    value
FROM auth.config 
WHERE key IN ('SITE_URL', 'DISABLE_SIGNUP', 'ENABLE_EMAIL_CONFIRMATIONS');

-- Mesaj final
SELECT 'După configurare, utilizatorii se vor putea înregistra și conecta imediat!' as final_message;

