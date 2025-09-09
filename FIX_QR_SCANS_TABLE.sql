-- FIX QR_SCANS TABLE AND RELATIONSHIPS
-- Script pentru repararea tabelei qr_scans și relațiilor

-- ========================================
-- 1. CREEAZĂ TABELA QR_SCANS DACĂ NU EXISTĂ
-- ========================================

DO $$
BEGIN
    -- Verifică dacă tabela există
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'qr_scans') THEN
        
        CREATE TABLE public.qr_scans (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            qr_code_id uuid REFERENCES public.qr_codes(id) ON DELETE CASCADE,
            scanned_by uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
            scan_result text DEFAULT 'success',
            scan_data jsonb DEFAULT '{}',
            scanned_at timestamp with time zone DEFAULT now(),
            created_at timestamp with time zone DEFAULT now()
        );
        
        RAISE NOTICE '✅ Tabela qr_scans creată cu succes';
    ELSE
        RAISE NOTICE '✅ Tabela qr_scans există deja';
    END IF;
END $$;

-- ========================================
-- 2. ADAUGĂ COLOANELE LIPSĂ DACĂ NU EXISTĂ
-- ========================================

DO $$
BEGIN
    -- Verifică și adaugă coloana scanned_by
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_scans' AND column_name = 'scanned_by') THEN
        ALTER TABLE public.qr_scans ADD COLUMN scanned_by uuid REFERENCES public.profiles(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Coloana scanned_by adăugată';
    END IF;
    
    -- Verifică și adaugă coloana scan_result
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_scans' AND column_name = 'scan_result') THEN
        ALTER TABLE public.qr_scans ADD COLUMN scan_result text DEFAULT 'success';
        RAISE NOTICE '✅ Coloana scan_result adăugată';
    END IF;
    
    -- Verifică și adaugă coloana scan_data
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_scans' AND column_name = 'scan_data') THEN
        ALTER TABLE public.qr_scans ADD COLUMN scan_data jsonb DEFAULT '{}';
        RAISE NOTICE '✅ Coloana scan_data adăugată';
    END IF;
    
    -- Verifică și adaugă coloana scanned_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_scans' AND column_name = 'scanned_at') THEN
        ALTER TABLE public.qr_scans ADD COLUMN scanned_at timestamp with time zone DEFAULT now();
        RAISE NOTICE '✅ Coloana scanned_at adăugată';
    END IF;
END $$;

-- ========================================
-- 3. CREEAZĂ INDEXURILE PENTRU PERFORMANȚĂ
-- ========================================

CREATE INDEX IF NOT EXISTS idx_qr_scans_qr_code_id ON public.qr_scans(qr_code_id);
CREATE INDEX IF NOT EXISTS idx_qr_scans_scanned_by ON public.qr_scans(scanned_by);
CREATE INDEX IF NOT EXISTS idx_qr_scans_scanned_at ON public.qr_scans(scanned_at DESC);

-- ========================================
-- 4. ACTIVEAZĂ RLS ȘI CREEAZĂ POLICIES
-- ========================================

-- Activează RLS
ALTER TABLE public.qr_scans ENABLE ROW LEVEL SECURITY;

-- Elimină policies existente pentru a evita conflictele
DROP POLICY IF EXISTS "qr_scans_policy" ON public.qr_scans;

-- Creează policy simplă
CREATE POLICY "qr_scans_policy" ON public.qr_scans FOR ALL USING (
    auth.uid() = scanned_by OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- ========================================
-- 5. ADAUGĂ DATE DEMO PENTRU TESTARE
-- ========================================

-- Inserează câteva scanări demo
INSERT INTO public.qr_scans (qr_code_id, scanned_by, scan_result, scan_data)
SELECT 
    qc.id,
    p.id,
    'success',
    jsonb_build_object(
        'scan_type', 'payment',
        'amount', 25.50,
        'timestamp', now()
    )
FROM public.qr_codes qc
CROSS JOIN public.profiles p
WHERE qc.type = 'bar_payment' 
  AND p.role = 'student'
LIMIT 2
ON CONFLICT DO NOTHING;

-- ========================================
-- 6. VERIFICARE FINALĂ
-- ========================================

DO $$
DECLARE
    table_exists boolean;
    column_count integer;
    policy_count integer;
BEGIN
    -- Verifică dacă tabela există
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'qr_scans'
    ) INTO table_exists;
    
    -- Numără coloanele
    SELECT count(*) FROM information_schema.columns 
    WHERE table_name = 'qr_scans' INTO column_count;
    
    -- Numără policies
    SELECT count(*) FROM pg_policies 
    WHERE tablename = 'qr_scans' INTO policy_count;
    
    RAISE NOTICE '✅ VERIFICARE FINALĂ:';
    RAISE NOTICE '   - Tabelă există: %', table_exists;
    RAISE NOTICE '   - Coloane: %', column_count;
    RAISE NOTICE '   - Policies: %', policy_count;
    
    IF table_exists AND column_count >= 6 AND policy_count >= 1 THEN
        RAISE NOTICE '✅ Tabela qr_scans este configurată corect!';
    ELSE
        RAISE NOTICE '❌ Probleme detectate în configurarea tabelei qr_scans';
    END IF;
END $$;

-- ========================================
-- FINAL
-- ========================================
RAISE NOTICE '🎉 Script FIX_QR_SCANS_TABLE completat cu succes!';






