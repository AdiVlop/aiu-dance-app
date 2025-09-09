-- ===============================================
-- ADMIN WALLET EXTENDED SCHEMA
-- Tabela pentru tranzacțiile administratorului
-- ===============================================

-- 1. CREEAZĂ TABELA ADMIN_TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.admin_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('withdraw', 'transfer', 'payment')),
    direction TEXT NOT NULL CHECK (direction IN ('in', 'out')),
    amount NUMERIC NOT NULL CHECK (amount > 0),
    method TEXT NOT NULL CHECK (method IN ('cash', 'revolut', 'iban', 'internal')),
    target TEXT, -- destinatar: user_id pentru transfer, furnizor pentru payment, IBAN/Revolut pentru withdraw
    description TEXT,
    metadata JSONB,
    status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. ACTIVEAZĂ RLS
ALTER TABLE public.admin_transactions ENABLE ROW LEVEL SECURITY;

-- 3. CREEAZĂ INDEXURI
CREATE INDEX IF NOT EXISTS idx_admin_transactions_admin_id ON public.admin_transactions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_transactions_type ON public.admin_transactions(type);
CREATE INDEX IF NOT EXISTS idx_admin_transactions_created_at ON public.admin_transactions(created_at);

-- 4. CREEAZĂ POLICIES RLS
DO $$ 
BEGIN 
    -- Admins can manage their own transactions
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'admin_transactions' AND policyname = 'Admins can manage own transactions') THEN
        CREATE POLICY "Admins can manage own transactions" ON public.admin_transactions
            FOR ALL USING (
                auth.uid() = admin_id AND
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND role = 'admin'
                )
            );
    END IF;
    
    -- Super admins can view all transactions
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'admin_transactions' AND policyname = 'Super admins can view all transactions') THEN
        CREATE POLICY "Super admins can view all transactions" ON public.admin_transactions
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND role = 'admin'
                    AND email = 'adrian@payai-x.com' -- Super admin
                )
            );
    END IF;
END $$;

-- 5. ADAUGĂ FUNCȚIE PENTRU ACTUALIZAREA UPDATED_AT
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 6. CREEAZĂ TRIGGER PENTRU UPDATED_AT
DROP TRIGGER IF EXISTS update_admin_transactions_updated_at ON public.admin_transactions;
CREATE TRIGGER update_admin_transactions_updated_at
    BEFORE UPDATE ON public.admin_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 7. INSEREAZĂ DATE DEMO
INSERT INTO public.admin_transactions (admin_id, type, direction, amount, method, target, description)
SELECT 
    p.id,
    'withdraw',
    'out',
    1000.00,
    'revolut',
    '@adi.ro',
    'Retragere fonduri pentru eveniment dans'
FROM public.profiles p
WHERE p.email = 'adrian@payai-x.com'
ON CONFLICT DO NOTHING;

INSERT INTO public.admin_transactions (admin_id, type, direction, amount, method, target, description)
SELECT 
    p.id,
    'payment',
    'out',
    450.00,
    'iban',
    'SC Furnizor SRL',
    'Chirie sală pentru cursuri'
FROM public.profiles p
WHERE p.email = 'adrian@payai-x.com'
ON CONFLICT DO NOTHING;

-- 8. VERIFICĂ REZULTATELE
SELECT 
    'Admin transactions schema created successfully!' as status,
    (SELECT COUNT(*) FROM public.admin_transactions) as total_transactions;

-- 9. AFIȘEAZĂ STRUCTURA TABELEI
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'admin_transactions'
ORDER BY ordinal_position;
