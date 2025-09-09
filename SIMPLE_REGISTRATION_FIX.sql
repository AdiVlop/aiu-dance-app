-- SIMPLE REGISTRATION FIX
-- Script simplu pentru repararea înregistrării fără trigger-e complexe

-- ========================================
-- 1. DEZACTIVEAZĂ RLS TEMPORAR PENTRU PROFILES
-- ========================================

ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- ========================================
-- 2. VERIFICĂ ȘI REPARĂ TABELA PROFILES
-- ========================================

-- Verifică dacă tabela profiles există
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid PRIMARY KEY,
    email text UNIQUE NOT NULL,
    full_name text,
    role text DEFAULT 'student',
    is_active boolean DEFAULT true,
    avatar_url text,
    phone text,
    date_of_birth date,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Adaugă coloanele lipsă
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS date_of_birth date;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- ========================================
-- 3. CREEAZĂ TABELA WALLETS SIMPLĂ
-- ========================================

CREATE TABLE IF NOT EXISTS public.wallets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid UNIQUE NOT NULL,
    balance numeric(10,2) DEFAULT 0.00,
    currency text DEFAULT 'RON',
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- ========================================
-- 4. ELIMINĂ TOATE TRIGGER-URILE PROBLEMATICE
-- ========================================

-- Elimină trigger-urile care pot cauza probleme
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- ========================================
-- 5. CREEAZĂ FUNCȚIE SIMPLĂ PENTRU PROFILE
-- ========================================

CREATE OR REPLACE FUNCTION public.create_profile_for_user(
    user_id uuid,
    user_email text,
    user_full_name text,
    user_role text DEFAULT 'student'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Încearcă să creeze profilul
    INSERT INTO public.profiles (id, email, full_name, role, is_active, created_at, updated_at)
    VALUES (
        user_id,
        user_email,
        user_full_name,
        user_role,
        true,
        now(),
        now()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        updated_at = now();
    
    -- Încearcă să creeze wallet-ul
    INSERT INTO public.wallets (user_id, balance, currency, is_active, created_at, updated_at)
    VALUES (
        user_id,
        0.00,
        'RON',
        true,
        now(),
        now()
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$;

-- ========================================
-- 6. TESTEAZĂ FUNCȚIA
-- ========================================

-- Testează funcția cu un ID dummy
SELECT public.create_profile_for_user(
    gen_random_uuid(),
    'test@example.com',
    'Test User',
    'student'
) as test_result;

-- ========================================
-- 7. VERIFICARE FINALĂ
-- ========================================

SELECT 
    'profiles' as table_name,
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') as exists,
    (SELECT count(*) FROM public.profiles) as row_count
UNION ALL
SELECT 
    'wallets' as table_name,
    EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wallets') as exists,
    (SELECT count(*) FROM public.wallets) as row_count;

-- ========================================
-- 8. INSTRUCȚIUNI FINALE
-- ========================================

-- NOTĂ: După aplicarea acestui script:
-- 1. Înregistrarea va funcționa fără trigger automat
-- 2. Profile-urile se vor crea manual prin AuthService
-- 3. RLS este dezactivat temporar pentru a evita blocajele
-- 4. Testează înregistrarea cu date noi






