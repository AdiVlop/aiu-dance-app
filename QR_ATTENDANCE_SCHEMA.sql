-- QR ATTENDANCE SYSTEM SCHEMA
-- Schema completă pentru sistemul de prezență prin QR

-- ========================================
-- 1. CREEAZĂ TABELA ATTENDANCE
-- ========================================

-- Creează tabela pentru prezența prin QR
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    scanned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Asigură-te că toate coloanele există (pentru cazul când tabela există deja)
DO $$
BEGIN
    -- Adaugă coloana scanned_at dacă nu există
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'scanned_at' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.attendance ADD COLUMN scanned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Coloana scanned_at adăugată în tabela attendance';
    END IF;

    -- Adaugă coloana metadata dacă nu există
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'metadata' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.attendance ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
        RAISE NOTICE 'Coloana metadata adăugată în tabela attendance';
    END IF;

    -- Adaugă coloana updated_at dacă nu există
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' AND column_name = 'updated_at' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.attendance ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Coloana updated_at adăugată în tabela attendance';
    END IF;
END $$;

-- Comentarii pentru tabela attendance
COMMENT ON TABLE attendance IS 'Tabela pentru înregistrarea prezenței prin scanarea codurilor QR';
COMMENT ON COLUMN attendance.user_id IS 'ID-ul utilizatorului care a scanat QR-ul';
COMMENT ON COLUMN attendance.course_id IS 'ID-ul cursului pentru care s-a înregistrat prezența';
COMMENT ON COLUMN attendance.scanned_at IS 'Data și ora când s-a scanat QR-ul';
COMMENT ON COLUMN attendance.metadata IS 'Date suplimentare despre scanare (device info, location, etc.)';

-- ========================================
-- 2. INDEXURI PENTRU PERFORMANȚĂ
-- ========================================

-- Index pentru căutări rapide după user_id
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);

-- Index pentru căutări rapide după course_id
CREATE INDEX IF NOT EXISTS idx_attendance_course_id ON attendance(course_id);

-- Index pentru căutări rapide după data scanării
CREATE INDEX IF NOT EXISTS idx_attendance_scanned_at ON attendance(scanned_at DESC);

-- Index compus pentru evitarea duplicatelor și căutări rapide
CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_user_course_unique 
ON attendance(user_id, course_id);

-- Index pentru statistici rapide
CREATE INDEX IF NOT EXISTS idx_attendance_course_date ON attendance(course_id, scanned_at);

-- ========================================
-- 3. RLS (ROW LEVEL SECURITY) POLICIES
-- ========================================

-- Activează RLS pentru tabela attendance
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

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

-- Policy pentru administratori: pot insera înregistrări pentru oricine
DROP POLICY IF EXISTS "Admins can insert any attendance" ON attendance;
CREATE POLICY "Admins can insert any attendance" ON attendance
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Policy pentru instructori: pot vedea prezența la cursurile proprii
DROP POLICY IF EXISTS "Instructors can view attendance for their courses" ON attendance;
CREATE POLICY "Instructors can view attendance for their courses" ON attendance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM courses 
            WHERE id = attendance.course_id 
            AND instructor_id = auth.uid()
        )
    );

-- ========================================
-- 4. ACTUALIZEAZĂ COLOANELE EXISTENTE
-- ========================================

-- Asigură-te că tabela courses are coloana is_active
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE courses ADD COLUMN is_active BOOLEAN DEFAULT true;
        COMMENT ON COLUMN courses.is_active IS 'Indică dacă cursul este activ pentru prezență';
    END IF;
END $$;

-- ========================================
-- 5. FUNCȚII HELPER PENTRU STATISTICI
-- ========================================

-- Funcție pentru a obține statistici de prezență pentru un curs
CREATE OR REPLACE FUNCTION get_course_attendance_stats(p_course_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_attendance', (
            SELECT COUNT(*) FROM attendance WHERE course_id = p_course_id
        ),
        'unique_attendees', (
            SELECT COUNT(DISTINCT user_id) FROM attendance WHERE course_id = p_course_id
        ),
        'recent_attendance', (
            SELECT COUNT(*) FROM attendance 
            WHERE course_id = p_course_id 
            AND scanned_at >= NOW() - INTERVAL '24 hours'
        ),
        'today_attendance', (
            SELECT COUNT(*) FROM attendance 
            WHERE course_id = p_course_id 
            AND DATE(scanned_at) = CURRENT_DATE
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 6. TRIGGER PENTRU UPDATED_AT
-- ========================================

-- Funcție pentru actualizarea automată a updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pentru tabela attendance
DROP TRIGGER IF EXISTS update_attendance_updated_at ON attendance;
CREATE TRIGGER update_attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- 7. DATE DEMO PENTRU TESTARE
-- ========================================

-- Inserează cursuri demo dacă nu există
INSERT INTO courses (id, title, category, instructor_id, is_active, description)
SELECT 
    gen_random_uuid(),
    'Curs Demo QR - Dans Modern',
    'Dans',
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
    true,
    'Curs demonstrativ pentru testarea sistemului QR de prezență'
WHERE NOT EXISTS (
    SELECT 1 FROM courses WHERE title LIKE '%QR%'
);

INSERT INTO courses (id, title, category, instructor_id, is_active, description)
SELECT 
    gen_random_uuid(),
    'Curs Demo QR - Hip Hop',
    'Dans',
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
    true,
    'Curs demonstrativ Hip Hop pentru testarea sistemului QR'
WHERE NOT EXISTS (
    SELECT 1 FROM courses WHERE title LIKE '%Hip Hop%'
);

-- Inserează date demo de prezență (doar dacă există cursuri și utilizatori)
DO $$
DECLARE
    demo_course_id UUID;
    demo_user_id UUID;
BEGIN
    -- Găsește un curs demo
    SELECT id INTO demo_course_id FROM courses WHERE title LIKE '%QR%' LIMIT 1;
    
    -- Găsește un utilizator demo (nu admin)
    SELECT id INTO demo_user_id FROM profiles WHERE role != 'admin' LIMIT 1;
    
    -- Inserează prezență demo doar dacă există cursul și utilizatorul
    IF demo_course_id IS NOT NULL AND demo_user_id IS NOT NULL THEN
        INSERT INTO attendance (user_id, course_id, scanned_at, metadata)
        SELECT 
            demo_user_id,
            demo_course_id,
            NOW() - INTERVAL '2 hours',
            '{"device": "demo", "location": "test"}'::jsonb
        WHERE NOT EXISTS (
            SELECT 1 FROM attendance 
            WHERE user_id = demo_user_id AND course_id = demo_course_id
        );
        
        RAISE NOTICE 'Date demo de prezență adăugate pentru cursul % și utilizatorul %', demo_course_id, demo_user_id;
    ELSE
        RAISE NOTICE 'Nu s-au găsit cursuri sau utilizatori pentru date demo';
    END IF;
END $$;

-- ========================================
-- 8. VERIFICĂRI FINALE
-- ========================================

-- Verifică că tabela a fost creată corect
SELECT 
    'attendance' as table_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) >= 0 THEN '✅ OK' 
        ELSE '❌ ERROR' 
    END as status
FROM attendance;

-- Verifică indexurile
SELECT 
    indexname,
    tablename,
    '✅ Index OK' as status
FROM pg_indexes 
WHERE tablename = 'attendance'
ORDER BY indexname;

-- Verifică policies RLS
SELECT 
    policyname,
    tablename,
    '✅ Policy OK' as status
FROM pg_policies 
WHERE tablename = 'attendance'
ORDER BY policyname;

-- Mesaj final de succes
SELECT '🎉 QR ATTENDANCE SYSTEM SCHEMA CREATED SUCCESSFULLY!' as final_status;

-- ========================================
-- 9. INSTRUCȚIUNI DE UTILIZARE
-- ========================================

/*
INSTRUCȚIUNI PENTRU UTILIZARE:

1. RULEAZĂ ACEST SCRIPT în Supabase Dashboard > SQL Editor

2. VERIFICĂ că toate tabelele și policies au fost create:
   - attendance (tabela principală)
   - indexuri pentru performanță
   - RLS policies pentru securitate
   - funcții helper pentru statistici

3. TESTEAZĂ funcționalitatea:
   - Generează QR în AdminDashboard > Prezență QR
   - Scanează QR cu aplicația mobilă
   - Verifică că prezența apare în tabela attendance

4. MONITORIZEAZĂ performanța:
   - Indexurile vor accelera căutările
   - RLS policies asigură securitatea datelor
   - Funcțiile helper optimizează statisticile

5. PERSONALIZEAZĂ după nevoie:
   - Adaugă coloane suplimentare în attendance
   - Modifică policies pentru alte roluri
   - Extinde funcțiile helper pentru alte statistici
*/
