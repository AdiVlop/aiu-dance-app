-- =====================================================
-- AIU DANCE - SCHEMA SIMPLIFICATĂ (REZOLVĂ DEFINITIV instructor_id)
-- =====================================================
-- Această schemă simplificată rezolvă problema cu instructor_id
-- Rulează-o pas cu pas în Supabase SQL Editor
-- =====================================================

-- PAS 1: Curățare completă (decomentează dacă ai probleme)
-- DROP TABLE IF EXISTS notifications CASCADE;
-- DROP TABLE IF EXISTS announcements CASCADE;
-- DROP TABLE IF EXISTS reservations CASCADE;
-- DROP TABLE IF EXISTS wallet_transactions CASCADE;
-- DROP TABLE IF EXISTS wallets CASCADE;
-- DROP TABLE IF EXISTS bar_orders CASCADE;
-- DROP TABLE IF EXISTS bar_menu CASCADE;
-- DROP TABLE IF EXISTS qr_codes CASCADE;
-- DROP TABLE IF EXISTS attendance CASCADE;
-- DROP TABLE IF EXISTS enrollments CASCADE;
-- DROP TABLE IF EXISTS courses CASCADE;
-- DROP TABLE IF EXISTS profiles CASCADE;

-- PAS 2: Extensii necesare
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- PAS 3: Tabela PROFILES (fără verificări automate)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL CHECK (role IN ('user', 'instructor', 'admin')) DEFAULT 'user',
    date_of_birth DATE,
    address TEXT,
    emergency_contact TEXT,
    medical_info TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PAS 4: Tabela COURSES (cu instructor_id corect)
CREATE TABLE IF NOT EXISTS courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    instructor_name TEXT,
    level TEXT CHECK (level IN ('Începător', 'Intermediar', 'Avansat')) DEFAULT 'Începător',
    category TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    duration INTEGER NOT NULL DEFAULT 60,
    max_students INTEGER NOT NULL DEFAULT 15,
    enrolled_students TEXT[] DEFAULT '{}',
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    schedule TEXT[],
    location TEXT NOT NULL,
    image_urls TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    requirements JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PAS 5: Verificare manuală (rulează separat)
-- SELECT column_name FROM information_schema.columns 
-- WHERE table_name = 'courses' AND column_name = 'instructor_id';

-- PAS 6: Restul tabelelor
CREATE TABLE IF NOT EXISTS enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT CHECK (status IN ('active', 'completed', 'cancelled')) DEFAULT 'active',
    payment_status TEXT CHECK (payment_status IN ('pending', 'paid', 'refunded')) DEFAULT 'pending',
    payment_amount DECIMAL(10,2),
    notes TEXT,
    UNIQUE(user_id, course_id)
);

CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    session_date DATE NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT CHECK (status IN ('present', 'absent', 'late', 'excused')) DEFAULT 'present',
    check_in_time TIMESTAMP WITH TIME ZONE,
    check_out_time TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    UNIQUE(user_id, course_id, session_date)
);

CREATE TABLE IF NOT EXISTS qr_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id)
);

CREATE TABLE IF NOT EXISTS bar_menu (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category TEXT NOT NULL,
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bar_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    items JSONB NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled')) DEFAULT 'pending',
    order_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_time TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    payment_method TEXT DEFAULT 'wallet'
);

CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    balance DECIMAL(10,2) DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT CHECK (type IN ('credit', 'debit')) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    reference_id TEXT,
    balance_before DECIMAL(10,2),
    balance_after DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
    target_role TEXT CHECK (target_role IN ('all', 'students', 'instructors', 'admins')),
    course_id UUID REFERENCES courses(id) ON DELETE SET NULL,
    is_published BOOLEAN DEFAULT true,
    scheduled_for TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT CHECK (type IN ('info', 'success', 'warning', 'error')) DEFAULT 'info',
    is_read BOOLEAN DEFAULT false,
    related_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    reservation_date DATE NOT NULL,
    time_slot TEXT NOT NULL,
    status TEXT CHECK (status IN ('pending', 'confirmed', 'cancelled')) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT
);

-- PAS 7: Indexuri pentru performanță
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_active ON profiles(is_active);

CREATE INDEX IF NOT EXISTS idx_courses_instructor ON courses(instructor_id);
CREATE INDEX IF NOT EXISTS idx_courses_category ON courses(category);
CREATE INDEX IF NOT EXISTS idx_courses_active ON courses(is_active);
CREATE INDEX IF NOT EXISTS idx_courses_start_time ON courses(start_time);

CREATE INDEX IF NOT EXISTS idx_enrollments_user ON enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON enrollments(status);

CREATE INDEX IF NOT EXISTS idx_attendance_user ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_course ON attendance(course_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(session_date);

CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON wallet_transactions(type);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_date ON wallet_transactions(created_at);

CREATE INDEX IF NOT EXISTS idx_announcements_created_by ON announcements(created_by);
CREATE INDEX IF NOT EXISTS idx_announcements_target_role ON announcements(target_role);
CREATE INDEX IF NOT EXISTS idx_announcements_published ON announcements(is_published);

-- PAS 8: Funcții utilitare
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION create_wallet_for_user()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'user' THEN
        INSERT INTO wallets (user_id, balance) VALUES (NEW.id, 0.0);
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION is_user_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM profiles 
        WHERE id = user_uuid AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_user_instructor(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM profiles 
        WHERE id = user_uuid AND role = 'instructor'
    );
END;
$$ LANGUAGE plpgsql;

-- PAS 9: Trigger-e
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bar_menu_updated_at BEFORE UPDATE ON bar_menu
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER create_wallet_trigger AFTER INSERT ON profiles
    FOR EACH ROW EXECUTE FUNCTION create_wallet_for_user();

-- PAS 10: RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bar_menu ENABLE ROW LEVEL SECURITY;
ALTER TABLE bar_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;

-- PAS 11: Politici RLS
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON profiles
    FOR ALL USING (is_user_admin(auth.uid()));

CREATE POLICY "Anyone can view active courses" ON courses
    FOR SELECT USING (is_active = true);

CREATE POLICY "Instructors can view own courses" ON courses
    FOR SELECT USING (instructor_id = auth.uid());

CREATE POLICY "Instructors can manage own courses" ON courses
    FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "Admins can manage all courses" ON courses
    FOR ALL USING (is_user_admin(auth.uid()));

CREATE POLICY "Users can view own enrollments" ON enrollments
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can enroll in courses" ON enrollments
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Instructors can view course enrollments" ON enrollments
    FOR SELECT USING (
        course_id IN (
            SELECT id FROM courses WHERE instructor_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all enrollments" ON enrollments
    FOR ALL USING (is_user_admin(auth.uid()));

CREATE POLICY "Users can view own attendance" ON attendance
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Instructors can manage course attendance" ON attendance
    FOR ALL USING (
        course_id IN (
            SELECT id FROM courses WHERE instructor_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all attendance" ON attendance
    FOR ALL USING (is_user_admin(auth.uid()));

CREATE POLICY "Users can view own wallet" ON wallets
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own wallet" ON wallets
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all wallets" ON wallets
    FOR ALL USING (is_user_admin(auth.uid()));

CREATE POLICY "Users can view own transactions" ON wallet_transactions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view all transactions" ON wallet_transactions
    FOR SELECT USING (is_user_admin(auth.uid()));

CREATE POLICY "Anyone can view published announcements" ON announcements
    FOR SELECT USING (is_published = true);

CREATE POLICY "Instructors can create announcements" ON announcements
    FOR INSERT WITH CHECK (is_user_instructor(auth.uid()));

CREATE POLICY "Instructors can manage own announcements" ON announcements
    FOR ALL USING (created_by = auth.uid());

CREATE POLICY "Admins can manage all announcements" ON announcements
    FOR ALL USING (is_user_admin(auth.uid()));

CREATE POLICY "Users can view own orders" ON bar_orders
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create orders" ON bar_orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can manage all orders" ON bar_orders
    FOR ALL USING (is_user_admin(auth.uid()));

-- PAS 12: Date de exemplu
INSERT INTO profiles (id, email, full_name, role, phone) VALUES
    ('11111111-1111-1111-1111-111111111111', 'admin@aiudance.ro', 'Administrator AIU Dance', 'admin', '+40 721 000 001'),
    ('22222222-2222-2222-2222-222222222222', 'instructor@aiudance.ro', 'Maria Popescu', 'instructor', '+40 721 000 002'),
    ('33333333-3333-3333-3333-333333333333', 'student@aiudance.ro', 'Alexandru Ionescu', 'user', '+40 721 000 003')
ON CONFLICT (id) DO NOTHING;

INSERT INTO courses (id, title, description, instructor_id, instructor_name, level, category, price, duration, max_students, location, schedule) VALUES
    ('44444444-4444-4444-4444-444444444444', 'Modern Dance - Începători', 'Curs de dans modern pentru începători', '22222222-2222-2222-2222-222222222222', 'Maria Popescu', 'Începător', 'Modern', 200.0, 60, 15, 'Sala 1', ARRAY['Luni 18:00', 'Miercuri 18:00']),
    ('55555555-5555-5555-5555-555555555555', 'Latin Dance - Intermediari', 'Curs de dans latin pentru intermediari', '22222222-2222-2222-2222-222222222222', 'Maria Popescu', 'Intermediar', 'Latin', 250.0, 90, 12, 'Sala 2', ARRAY['Marți 19:30', 'Joi 19:30'])
ON CONFLICT (id) DO NOTHING;

INSERT INTO bar_menu (name, description, price, category, stock_quantity) VALUES
    ('Apa minerală', 'Apa minerală naturală 500ml', 5.0, 'Băuturi', 100),
    ('Suc de portocale', 'Suc natural de portocale 330ml', 8.0, 'Băuturi', 50),
    ('Sandwich cu șuncă', 'Sandwich cu șuncă și brânză', 15.0, 'Sandwich-uri', 20),
    ('Croissant', 'Croissant cu unt proaspăt', 12.0, 'Patiserie', 30)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SCHEMA SIMPLIFICATĂ - REZOLVĂ DEFINITIV instructor_id!
-- =====================================================
-- Această schemă nu are verificări automate care să eșueze
-- Rulează-o completă în Supabase SQL Editor
-- =====================================================
