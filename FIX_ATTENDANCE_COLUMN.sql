-- FIX ATTENDANCE TABLE - COLOANA SCANNED_AT
-- Script rapid pentru a adăuga coloana lipsă în tabela attendance

-- 1. Verifică dacă tabela attendance există
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'attendance' AND table_schema = 'public'
    ) THEN
        -- Creează tabela dacă nu există
        CREATE TABLE attendance (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
            course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        RAISE NOTICE 'Tabela attendance a fost creată';
    END IF;
END $$;

-- 2. Adaugă coloana scanned_at dacă nu există
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'scanned_at' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.attendance ADD COLUMN scanned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Coloana scanned_at a fost adăugată în tabela attendance';
    ELSE
        RAISE NOTICE 'ℹ️  Coloana scanned_at există deja în tabela attendance';
    END IF;
END $$;

-- 3. Adaugă coloana metadata dacă nu există
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'metadata' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.attendance ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
        RAISE NOTICE '✅ Coloana metadata a fost adăugată în tabela attendance';
    ELSE
        RAISE NOTICE 'ℹ️  Coloana metadata există deja în tabela attendance';
    END IF;
END $$;

-- 4. Adaugă coloana updated_at dacă nu există
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'updated_at' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.attendance ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Coloana updated_at a fost adăugată în tabela attendance';
    ELSE
        RAISE NOTICE 'ℹ️  Coloana updated_at există deja în tabela attendance';
    END IF;
END $$;

-- 5. Activează RLS pentru tabela attendance
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- 6. Creează policies de bază pentru attendance
-- Policy pentru utilizatori: pot vedea doar propriile înregistrări
DROP POLICY IF EXISTS "Users can view their own attendance" ON attendance;
CREATE POLICY "Users can view their own attendance" ON attendance
    FOR SELECT USING (auth.uid() = user_id);

-- Policy pentru utilizatori: pot insera doar propriile înregistrări
DROP POLICY IF EXISTS "Users can insert their own attendance" ON attendance;
CREATE POLICY "Users can insert their own attendance" ON attendance
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy pentru administratori: pot vedea toate înregistrările
DROP POLICY IF EXISTS "Admins can view all attendance" ON attendance;
CREATE POLICY "Admins can view all attendance" ON attendance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 7. Creează indexuri pentru performanță
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_course_id ON attendance(course_id);
CREATE INDEX IF NOT EXISTS idx_attendance_scanned_at ON attendance(scanned_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_user_course_unique ON attendance(user_id, course_id);

-- 8. Verifică rezultatul
SELECT 
    'attendance' as table_name,
    COUNT(*) as record_count,
    '✅ Tabela attendance este gata!' as status
FROM attendance;

-- 9. Afișează structura tabelei
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    '✅ OK' as status
FROM information_schema.columns 
WHERE table_name = 'attendance' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Mesaj final
SELECT '🎉 ATTENDANCE TABLE FIXED SUCCESSFULLY!' as final_status;
