-- SIMPLE QR ATTENDANCE FIX
-- Script simplificat pentru a corecta doar problemele imediate

-- 1. Verifică și creează tabela attendance cu coloanele corecte
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    session_date DATE DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'present' CHECK (status IN ('present', 'absent', 'late', 'excused')),
    check_in_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, course_id, session_date)
);

-- 2. Asigură-te că tabela courses are coloana is_active
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'is_active' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.courses ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE '✅ Coloana is_active adăugată în tabela courses';
    ELSE
        RAISE NOTICE 'ℹ️  Coloana is_active există deja în tabela courses';
    END IF;
END $$;

-- 3. Activează RLS pentru tabela attendance
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- 4. Creează policies de bază
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

-- 5. Creează indexuri pentru performanță
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_course_id ON attendance(course_id);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in_time ON attendance(check_in_time DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_session_date ON attendance(session_date DESC);

-- 6. Inserează cursuri demo DOAR cu coloanele existente
INSERT INTO courses (title, category, instructor_id, is_active, description, location, level)
SELECT 
    'Curs Demo QR - Dans Modern',
    'Dans',
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
    true,
    'Curs demonstrativ pentru testarea sistemului QR de prezență',
    'Sala 1 - QR Demo',
    'Începător'
WHERE NOT EXISTS (
    SELECT 1 FROM courses WHERE title LIKE '%Demo QR%'
) AND EXISTS (
    SELECT 1 FROM profiles WHERE role = 'admin'
);

-- 7. Verifică rezultatul
SELECT 
    'attendance' as table_name,
    COUNT(*) as record_count,
    '✅ Tabela attendance este gata!' as status
FROM attendance;

-- 8. Verifică coloanele tabelei attendance
SELECT 
    column_name,
    data_type,
    is_nullable,
    '✅ OK' as status
FROM information_schema.columns 
WHERE table_name = 'attendance' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 9. Verifică cursurile active
SELECT 
    id,
    title,
    category,
    is_active,
    '✅ Curs activ' as status
FROM courses 
WHERE is_active = true
ORDER BY title;

-- Mesaj final
SELECT '🎉 QR ATTENDANCE SYSTEM READY FOR TESTING!' as final_status;
