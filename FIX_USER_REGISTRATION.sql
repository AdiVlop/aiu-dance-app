-- FIX USER REGISTRATION
-- Script pentru repararea înregistrării utilizatorilor noi

-- ========================================
-- 1. VERIFICĂ ȘI REPARĂ TABELA PROFILES
-- ========================================

-- Verifică dacă tabela profiles există și are coloanele corecte
DO $$
BEGIN
    -- Verifică dacă tabela există
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        
        CREATE TABLE public.profiles (
            id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
            email text UNIQUE NOT NULL,
            full_name text,
            role text DEFAULT 'student' CHECK (role IN ('student', 'instructor', 'admin')),
            is_active boolean DEFAULT true,
            avatar_url text,
            phone text,
            date_of_birth date,
            created_at timestamp with time zone DEFAULT now(),
            updated_at timestamp with time zone DEFAULT now()
        );
        
        RAISE NOTICE '✅ Tabela profiles creată cu succes';
    ELSE
        RAISE NOTICE '✅ Tabela profiles există deja';
    END IF;
END $$;

-- Adaugă coloanele lipsă dacă nu există
DO $$
BEGIN
    -- is_active
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'is_active') THEN
        ALTER TABLE public.profiles ADD COLUMN is_active boolean DEFAULT true;
        RAISE NOTICE '✅ Coloana is_active adăugată';
    END IF;
    
    -- avatar_url
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'avatar_url') THEN
        ALTER TABLE public.profiles ADD COLUMN avatar_url text;
        RAISE NOTICE '✅ Coloana avatar_url adăugată';
    END IF;
    
    -- phone
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'phone') THEN
        ALTER TABLE public.profiles ADD COLUMN phone text;
        RAISE NOTICE '✅ Coloana phone adăugată';
    END IF;
    
    -- date_of_birth
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'date_of_birth') THEN
        ALTER TABLE public.profiles ADD COLUMN date_of_birth date;
        RAISE NOTICE '✅ Coloana date_of_birth adăugată';
    END IF;
    
    -- created_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'created_at') THEN
        ALTER TABLE public.profiles ADD COLUMN created_at timestamp with time zone DEFAULT now();
        RAISE NOTICE '✅ Coloana created_at adăugată';
    END IF;
    
    -- updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'updated_at') THEN
        ALTER TABLE public.profiles ADD COLUMN updated_at timestamp with time zone DEFAULT now();
        RAISE NOTICE '✅ Coloana updated_at adăugată';
    END IF;
END $$;

-- ========================================
-- 2. ACTIVEAZĂ RLS PENTRU PROFILES
-- ========================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Elimină policies existente pentru a evita conflictele
DROP POLICY IF EXISTS "profiles_policy" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- Creează policy simplă pentru profiles
CREATE POLICY "profiles_policy" ON public.profiles FOR ALL USING (
    auth.uid() = id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- ========================================
-- 3. CREEAZĂ TABELA WALLETS PENTRU UTILIZATORI NOI
-- ========================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'wallets') THEN
        
        CREATE TABLE public.wallets (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id uuid UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
            balance numeric(10,2) DEFAULT 0.00,
            currency text DEFAULT 'RON',
            is_active boolean DEFAULT true,
            created_at timestamp with time zone DEFAULT now(),
            updated_at timestamp with time zone DEFAULT now()
        );
        
        RAISE NOTICE '✅ Tabela wallets creată cu succes';
    ELSE
        RAISE NOTICE '✅ Tabela wallets există deja';
    END IF;
END $$;

-- RLS pentru wallets
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "wallets_policy" ON public.wallets;
CREATE POLICY "wallets_policy" ON public.wallets FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- ========================================
-- 4. CREEAZĂ FUNCȚIA PENTRU PROFILE AUTOMAT
-- ========================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Creează profile automat când se înregistrează un user
    INSERT INTO public.profiles (id, email, full_name, role, is_active, created_at, updated_at)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data ->> 'full_name', new.email),
        COALESCE(new.raw_user_meta_data ->> 'role', 'student'),
        true,
        now(),
        now()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
        updated_at = now();
    
    -- Creează wallet automat
    INSERT INTO public.wallets (user_id, balance, currency, is_active, created_at, updated_at)
    VALUES (
        new.id,
        0.00,
        'RON',
        true,
        now(),
        now()
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN new;
END;
$$;

-- ========================================
-- 5. CREEAZĂ TRIGGER PENTRU PROFILE AUTOMAT
-- ========================================

-- Elimină trigger-ul existent
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Creează trigger nou
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- 6. NOTĂ PENTRU CONFIGURAREA EMAIL
-- ========================================

-- NOTĂ: Pentru a dezactiva confirmarea email, mergi în Supabase Dashboard:
-- Authentication → Settings → Email confirmations → OFF
-- Authentication → Settings → Enable email confirmations → OFF

-- ========================================
-- 7. VERIFICARE FINALĂ
-- ========================================

DO $$
DECLARE
    profiles_exists boolean;
    wallets_exists boolean;
    trigger_exists boolean;
    profile_count integer;
BEGIN
    -- Verifică tabela profiles
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'profiles'
    ) INTO profiles_exists;
    
    -- Verifică tabela wallets
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'wallets'
    ) INTO wallets_exists;
    
    -- Verifică trigger-ul
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'on_auth_user_created'
    ) INTO trigger_exists;
    
    -- Numără profiles
    SELECT count(*) FROM public.profiles INTO profile_count;
    
    RAISE NOTICE '✅ VERIFICARE ÎNREGISTRARE:';
    RAISE NOTICE '   - Tabela profiles: %', profiles_exists;
    RAISE NOTICE '   - Tabela wallets: %', wallets_exists;
    RAISE NOTICE '   - Trigger automat: %', trigger_exists;
    RAISE NOTICE '   - Utilizatori existenți: %', profile_count;
    
    IF profiles_exists AND wallets_exists AND trigger_exists THEN
        RAISE NOTICE '🎉 Înregistrarea ar trebui să funcționeze acum!';
    ELSE
        RAISE NOTICE '❌ Încă sunt probleme cu înregistrarea';
    END IF;
END $$;

-- ========================================
-- FINAL
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Script FIX_USER_REGISTRATION completat!';
    RAISE NOTICE '📝 Acum poți testa înregistrarea utilizatorilor noi!';
END $$;
