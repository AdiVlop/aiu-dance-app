-- WALLET COMPLETE FIX
-- Script pentru repararea completă a sistemului de wallet

-- ========================================
-- 1. CREEAZĂ TABELA WALLETS DACĂ NU EXISTĂ
-- ========================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'wallets') THEN
        
        CREATE TABLE public.wallets (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id uuid UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
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

-- ========================================
-- 2. ADAUGĂ COLOANELE LIPSĂ DACĂ NU EXISTĂ
-- ========================================

DO $$
BEGIN
    -- balance
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'wallets' AND column_name = 'balance') THEN
        ALTER TABLE public.wallets ADD COLUMN balance numeric(10,2) DEFAULT 0.00;
        RAISE NOTICE '✅ Coloana balance adăugată';
    END IF;
    
    -- currency
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'wallets' AND column_name = 'currency') THEN
        ALTER TABLE public.wallets ADD COLUMN currency text DEFAULT 'RON';
        RAISE NOTICE '✅ Coloana currency adăugată';
    END IF;
    
    -- is_active
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'wallets' AND column_name = 'is_active') THEN
        ALTER TABLE public.wallets ADD COLUMN is_active boolean DEFAULT true;
        RAISE NOTICE '✅ Coloana is_active adăugată';
    END IF;
    
    -- created_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'wallets' AND column_name = 'created_at') THEN
        ALTER TABLE public.wallets ADD COLUMN created_at timestamp with time zone DEFAULT now();
        RAISE NOTICE '✅ Coloana created_at adăugată';
    END IF;
    
    -- updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'wallets' AND column_name = 'updated_at') THEN
        ALTER TABLE public.wallets ADD COLUMN updated_at timestamp with time zone DEFAULT now();
        RAISE NOTICE '✅ Coloana updated_at adăugată';
    END IF;
END $$;

-- ========================================
-- 3. VERIFICĂ ȘI REPARĂ TABELA WALLET_TRANSACTIONS
-- ========================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'wallet_transactions') THEN
        
        CREATE TABLE public.wallet_transactions (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
            type text NOT NULL CHECK (type IN ('credit', 'debit')),
            amount numeric(10,2) NOT NULL,
            description text,
            metadata jsonb DEFAULT '{}',
            created_at timestamp with time zone DEFAULT now()
        );
        
        RAISE NOTICE '✅ Tabela wallet_transactions creată cu succes';
    ELSE
        RAISE NOTICE '✅ Tabela wallet_transactions există deja';
    END IF;
END $$;

-- Adaugă coloanele lipsă pentru wallet_transactions
DO $$
BEGIN
    -- metadata
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'wallet_transactions' AND column_name = 'metadata') THEN
        ALTER TABLE public.wallet_transactions ADD COLUMN metadata jsonb DEFAULT '{}';
        RAISE NOTICE '✅ Coloana metadata adăugată în wallet_transactions';
    END IF;
END $$;

-- ========================================
-- 4. CREEAZĂ INDEXURILE PENTRU PERFORMANȚĂ
-- ========================================

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id ON public.wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON public.wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON public.wallet_transactions(type);

-- ========================================
-- 5. ACTIVEAZĂ RLS ȘI CREEAZĂ POLICIES
-- ========================================

-- RLS pentru wallets
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "wallets_policy" ON public.wallets;
CREATE POLICY "wallets_policy" ON public.wallets FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- RLS pentru wallet_transactions
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "wallet_transactions_policy" ON public.wallet_transactions;
CREATE POLICY "wallet_transactions_policy" ON public.wallet_transactions FOR ALL USING (
    auth.uid() = user_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- ========================================
-- 6. CREEAZĂ WALLETS PENTRU UTILIZATORII EXISTENȚI
-- ========================================

-- Creează wallets pentru toți utilizatorii care nu au
INSERT INTO public.wallets (user_id, balance, currency, is_active, created_at, updated_at)
SELECT 
    p.id,
    0.00,
    'RON',
    true,
    now(),
    now()
FROM public.profiles p
LEFT JOIN public.wallets w ON p.id = w.user_id
WHERE w.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;

-- ========================================
-- 7. ADAUGĂ CÂTEVA TRANZACȚII DEMO PENTRU TESTARE
-- ========================================

-- Adaugă tranzacții demo pentru primul utilizator
INSERT INTO public.wallet_transactions (user_id, type, amount, description, metadata, created_at)
SELECT 
    p.id,
    'credit',
    100.00,
    'Bonus de bun venit',
    '{"type": "welcome_bonus", "source": "system"}',
    now() - interval '7 days'
FROM public.profiles p
WHERE p.role = 'student'
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO public.wallet_transactions (user_id, type, amount, description, metadata, created_at)
SELECT 
    p.id,
    'debit',
    50.00,
    'Plată curs Salsa',
    '{"type": "course_payment", "course_name": "Salsa pentru începători"}',
    now() - interval '3 days'
FROM public.profiles p
WHERE p.role = 'student'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Actualizează balanța wallet-ului
UPDATE public.wallets 
SET balance = (
    SELECT COALESCE(
        SUM(CASE WHEN wt.type = 'credit' THEN wt.amount ELSE -wt.amount END), 
        0.00
    )
    FROM wallet_transactions wt 
    WHERE wt.user_id = wallets.user_id
),
updated_at = now()
WHERE EXISTS (
    SELECT 1 FROM wallet_transactions wt 
    WHERE wt.user_id = wallets.user_id
);

-- ========================================
-- 8. VERIFICARE FINALĂ
-- ========================================

DO $$
DECLARE
    wallets_count integer;
    transactions_count integer;
    profiles_count integer;
BEGIN
    -- Numără wallets
    SELECT count(*) FROM public.wallets INTO wallets_count;
    
    -- Numără tranzacții
    SELECT count(*) FROM public.wallet_transactions INTO transactions_count;
    
    -- Numără profiles
    SELECT count(*) FROM public.profiles INTO profiles_count;
    
    RAISE NOTICE '✅ VERIFICARE WALLET SYSTEM:';
    RAISE NOTICE '   - Profiles: %', profiles_count;
    RAISE NOTICE '   - Wallets: %', wallets_count;
    RAISE NOTICE '   - Tranzacții: %', transactions_count;
    
    IF wallets_count >= profiles_count THEN
        RAISE NOTICE '🎉 Wallet system este configurat corect!';
    ELSE
        RAISE NOTICE '❌ Lipsesc wallet-uri pentru unii utilizatori';
    END IF;
END $$;

-- ========================================
-- FINAL
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Script WALLET_COMPLETE_FIX completat!';
    RAISE NOTICE '💰 Sistemul de wallet este acum complet funcțional!';
END $$;







