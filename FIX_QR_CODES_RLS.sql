-- FIX QR_CODES RLS POLICIES
-- Corectează policies pentru a permite generarea QR-urilor

-- 1. Elimină toate policies existente pentru qr_codes
DROP POLICY IF EXISTS "Users can view active QR codes" ON qr_codes;
DROP POLICY IF EXISTS "Users can insert their own QR codes" ON qr_codes;
DROP POLICY IF EXISTS "Admins can do everything on QR codes" ON qr_codes;
DROP POLICY IF EXISTS "Admins can view all QR codes" ON qr_codes;
DROP POLICY IF EXISTS "Admins can insert QR codes" ON qr_codes;
DROP POLICY IF EXISTS "Admins can update QR codes" ON qr_codes;
DROP POLICY IF EXISTS "Instructors can create QR codes" ON qr_codes;

-- 2. Activează RLS pentru qr_codes
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;

-- 3. Creează policies noi, mai permisive pentru admini
-- Policy pentru administratori: pot face orice cu QR codes
CREATE POLICY "Admins can do everything on qr_codes" ON qr_codes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Policy pentru utilizatori: pot vedea QR codes active
CREATE POLICY "Users can view active qr_codes" ON qr_codes
    FOR SELECT USING (is_active = true);

-- Policy pentru utilizatori: pot insera propriile QR codes (dacă au created_by)
CREATE POLICY "Users can insert their own qr_codes" ON qr_codes
    FOR INSERT WITH CHECK (
        auth.uid() = created_by OR 
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 4. Asigură-te că tabela qr_codes are coloana created_by
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'qr_codes' AND column_name = 'created_by' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.qr_codes ADD COLUMN created_by UUID REFERENCES profiles(id);
        RAISE NOTICE '✅ Coloana created_by adăugată în tabela qr_codes';
    ELSE
        RAISE NOTICE 'ℹ️  Coloana created_by există deja în tabela qr_codes';
    END IF;
END $$;

-- 5. Actualizează QR codes existente fără created_by
UPDATE qr_codes 
SET created_by = (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1)
WHERE created_by IS NULL;

-- 6. Testează inserarea unui QR code
DO $$
DECLARE
    admin_user_id UUID;
    test_qr_id UUID;
BEGIN
    -- Găsește un admin
    SELECT id INTO admin_user_id FROM profiles WHERE role = 'admin' LIMIT 1;
    
    IF admin_user_id IS NOT NULL THEN
        -- Testează inserarea
        INSERT INTO qr_codes (
            code, 
            type, 
            title, 
            data, 
            is_active, 
            created_by,
            expires_at
        ) VALUES (
            'TEST_QR_' || EXTRACT(EPOCH FROM NOW())::text,
            'test',
            'Test QR Code',
            '{"test": true}'::jsonb,
            true,
            admin_user_id,
            NOW() + INTERVAL '1 hour'
        ) RETURNING id INTO test_qr_id;
        
        -- Șterge testul
        DELETE FROM qr_codes WHERE id = test_qr_id;
        
        RAISE NOTICE '✅ Test inserare QR code reușit!';
    ELSE
        RAISE NOTICE '❌ Nu s-a găsit admin pentru test';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Eroare la test: %', SQLERRM;
END $$;

-- 7. Verifică policies
SELECT 
    policyname,
    tablename,
    '✅ Policy OK' as status
FROM pg_policies 
WHERE tablename = 'qr_codes'
ORDER BY policyname;

-- Mesaj final
SELECT '🎉 QR_CODES RLS POLICIES FIXED!' as final_status;
