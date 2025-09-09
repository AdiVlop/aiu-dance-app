-- =====================================================
-- AIU DANCE - COMPLETE SUPABASE SCHEMA (CORECTATĂ)
-- =====================================================
-- Această schemă conține toate tabelele, politici RLS,
-- trigger-e și funcții necesare pentru aplicația AIU Dance
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. CURĂȚARE TABELE EXISTENTE (OPȚIONAL)
-- =====================================================

-- Comentează aceste linii dacă nu vrei să ștergi tabelele existente
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

-- =====================================================
-- 2. TABELE PRINCIPALE
-- =====================================================

-- Tabela pentru profilurile utilizatorilor
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

-- Tabela pentru cursuri
CREATE TABLE IF NOT EXISTS courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    instructor_name TEXT,
    level TEXT CHECK (level IN ('Începător', 'Intermediar', 'Avansat')) DEFAULT 'Începător',
    category TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    duration INTEGER NOT NULL DEFAULT 60, -- în minute
    max_students INTEGER NOT NULL DEFAULT 15,
    enrolled_students TEXT[] DEFAULT '{}', -- array de user IDs
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    schedule TEXT[], -- array de zile și ore
    location TEXT NOT NULL,
    image_urls TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    requirements JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela pentru înscrieri la cursuri
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

-- Tabela pentru prezență
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

-- Tabela pentru coduri QR
CREATE TABLE IF NOT EXISTS qr_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id)
);

-- Tabela pentru meniul bar-ului
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

-- Tabela pentru comenzi bar
CREATE TABLE IF NOT EXISTS bar_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    items JSONB NOT NULL, -- array de produse cu cantitate și preț
    total_amount DECIMAL(10,2) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled')) DEFAULT 'pending',
    order_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_time TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    payment_method TEXT DEFAULT 'wallet'
);

-- Tabela pentru portofel
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    balance DECIMAL(10,2) DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela pentru tranzacții portofel
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT CHECK (type IN ('credit', 'debit')) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    reference_id TEXT, -- ID-ul tranzacției Stripe sau alte referințe
    balance_before DECIMAL(10,2),
    balance_after DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela pentru anunțuri
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

-- Tabela pentru notificări
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT CHECK (type IN ('info', 'success', 'warning', 'error')) DEFAULT 'info',
    is_read BOOLEAN DEFAULT false,
    related_id TEXT, -- ID-ul entității legate (curs, anunț, etc.)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela pentru rezervări
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

-- =====================================================
-- 3. INDEXURI PENTRU PERFORMANȚĂ
-- =====================================================

-- Indexuri pentru profiles
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_active ON profiles(is_active);

-- Indexuri pentru courses
CREATE INDEX IF NOT EXISTS idx_courses_instructor ON courses(instructor_id);
CREATE INDEX IF NOT EXISTS idx_courses_category ON courses(category);
CREATE INDEX IF NOT EXISTS idx_courses_active ON courses(is_active);
CREATE INDEX IF NOT EXISTS idx_courses_start_time ON courses(start_time);

-- Indexuri pentru enrollments
CREATE INDEX IF NOT EXISTS idx_enrollments_user ON enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON enrollments(status);

-- Indexuri pentru attendance
CREATE INDEX IF NOT EXISTS idx_attendance_user ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_course ON attendance(course_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(session_date);

-- Indexuri pentru wallet_transactions
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON wallet_transactions(type);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_date ON wallet_transactions(created_at);

-- Indexuri pentru announcements
CREATE INDEX IF NOT EXISTS idx_announcements_created_by ON announcements(created_by);
CREATE INDEX IF NOT EXISTS idx_announcements_target_role ON announcements(target_role);
CREATE INDEX IF NOT EXISTS idx_announcements_published ON announcements(is_published);

-- =====================================================
-- 4. TRIGGER-E PENTRU UPDATED_AT
-- =====================================================

-- Funcție pentru actualizarea automată a updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger-e pentru actualizarea automată
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bar_menu_updated_at BEFORE UPDATE ON bar_menu
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. TRIGGER-E PENTRU CREAREA AUTOMATĂ A WALLET-ULUI
-- =====================================================

-- Funcție pentru crearea automată a wallet-ului
CREATE OR REPLACE FUNCTION create_wallet_for_user()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'user' THEN
        INSERT INTO wallets (user_id, balance) VALUES (NEW.id, 0.0);
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pentru crearea automată a wallet-ului
CREATE TRIGGER create_wallet_trigger AFTER INSERT ON profiles
    FOR EACH ROW EXECUTE FUNCTION create_wallet_for_user();

-- =====================================================
-- 6. FUNCȚII UTILITARE
-- =====================================================

-- Funcție pentru obținerea statisticilor cursului
CREATE OR REPLACE FUNCTION get_course_stats(course_uuid UUID)
RETURNS TABLE(
    total_enrolled INTEGER,
    attendance_rate DECIMAL,
    revenue DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT e.user_id)::INTEGER as total_enrolled,
        ROUND(
            (COUNT(CASE WHEN a.status = 'present' THEN 1 END)::DECIMAL / 
             COUNT(a.id)::DECIMAL) * 100, 2
        ) as attendance_rate,
        COALESCE(SUM(e.payment_amount), 0) as revenue
    FROM courses c
    LEFT JOIN enrollments e ON c.id = e.course_id
    LEFT JOIN attendance a ON c.id = a.course_id AND e.user_id = a.user_id
    WHERE c.id = course_uuid
    GROUP BY c.id;
END;
$$ LANGUAGE plpgsql;

-- Funcție pentru validarea codului QR
CREATE OR REPLACE FUNCTION validate_qr_code(qr_code TEXT, user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    qr_record RECORD;
    user_enrolled BOOLEAN;
BEGIN
    -- Verifică dacă codul QR există și este valid
    SELECT * INTO qr_record FROM qr_codes 
    WHERE code = qr_code AND is_active = true 
    AND (expires_at IS NULL OR expires_at > NOW());
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Verifică dacă utilizatorul este înscris la curs
    SELECT EXISTS(
        SELECT 1 FROM enrollments 
        WHERE user_id = user_uuid AND course_id = qr_record.course_id
    ) INTO user_enrolled;
    
    RETURN user_enrolled;
END;
$$ LANGUAGE plpgsql;

-- Funcție pentru verificarea dacă utilizatorul este admin
CREATE OR REPLACE FUNCTION is_user_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM profiles 
        WHERE id = user_uuid AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql;

-- Funcție pentru verificarea dacă utilizatorul este instructor
CREATE OR REPLACE FUNCTION is_user_instructor(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM profiles 
        WHERE id = user_uuid AND role = 'instructor'
    );
END;
$$ LANGUAGE plpgsql;

-- Funcție pentru obținerea statisticilor dashboard-ului
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS TABLE(
    total_users INTEGER,
    total_courses INTEGER,
    total_enrollments INTEGER,
    total_revenue DECIMAL,
    active_courses INTEGER,
    pending_orders INTEGER,
    today_attendance INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(p.id)::INTEGER as total_users,
        COUNT(c.id)::INTEGER as total_courses,
        COUNT(e.id)::INTEGER as total_enrollments,
        COALESCE(SUM(e.payment_amount), 0) as total_revenue,
        COUNT(CASE WHEN c.is_active THEN 1 END)::INTEGER as active_courses,
        COUNT(CASE WHEN bo.status = 'pending' THEN 1 END)::INTEGER as pending_orders,
        COUNT(CASE WHEN a.session_date = CURRENT_DATE THEN 1 END)::INTEGER as today_attendance
    FROM profiles p
    CROSS JOIN courses c
    CROSS JOIN enrollments e
    CROSS JOIN bar_orders bo
    CROSS JOIN attendance a;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Activează RLS pentru toate tabelele
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

-- Politici pentru profiles
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON profiles
    FOR ALL USING (is_user_admin(auth.uid()));

-- Politici pentru courses
CREATE POLICY "Anyone can view active courses" ON courses
    FOR SELECT USING (is_active = true);

CREATE POLICY "Instructors can view own courses" ON courses
    FOR SELECT USING (instructor_id = auth.uid());

CREATE POLICY "Instructors can manage own courses" ON courses
    FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "Admins can manage all courses" ON courses
    FOR ALL USING (is_user_admin(auth.uid()));

-- Politici pentru enrollments
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

-- Politici pentru attendance
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

-- Politici pentru wallets
CREATE POLICY "Users can view own wallet" ON wallets
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own wallet" ON wallets
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all wallets" ON wallets
    FOR ALL USING (is_user_admin(auth.uid()));

-- Politici pentru wallet_transactions
CREATE POLICY "Users can view own transactions" ON wallet_transactions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view all transactions" ON wallet_transactions
    FOR SELECT USING (is_user_admin(auth.uid()));

-- Politici pentru announcements
CREATE POLICY "Anyone can view published announcements" ON announcements
    FOR SELECT USING (is_published = true);

CREATE POLICY "Instructors can create announcements" ON announcements
    FOR INSERT WITH CHECK (is_user_instructor(auth.uid()));

CREATE POLICY "Instructors can manage own announcements" ON announcements
    FOR ALL USING (created_by = auth.uid());

CREATE POLICY "Admins can manage all announcements" ON announcements
    FOR ALL USING (is_user_admin(auth.uid()));

-- Politici pentru bar_orders
CREATE POLICY "Users can view own orders" ON bar_orders
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create orders" ON bar_orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can manage all orders" ON bar_orders
    FOR ALL USING (is_user_admin(auth.uid()));

-- =====================================================
-- 8. DATE DE EXEMPLU
-- =====================================================

-- Inserare utilizatori de exemplu (parolele vor fi create prin auth)
INSERT INTO profiles (id, email, full_name, role, phone) VALUES
    ('11111111-1111-1111-1111-111111111111', 'admin@aiudance.ro', 'Administrator AIU Dance', 'admin', '+40 721 000 001'),
    ('22222222-2222-2222-2222-222222222222', 'instructor@aiudance.ro', 'Maria Popescu', 'instructor', '+40 721 000 002'),
    ('33333333-3333-3333-3333-333333333333', 'student@aiudance.ro', 'Alexandru Ionescu', 'user', '+40 721 000 003')
ON CONFLICT (id) DO NOTHING;

-- Inserare cursuri de exemplu
INSERT INTO courses (id, title, description, instructor_id, instructor_name, level, category, price, duration, max_students, location, schedule) VALUES
    ('44444444-4444-4444-4444-444444444444', 'Modern Dance - Începători', 'Curs de dans modern pentru începători', '22222222-2222-2222-2222-222222222222', 'Maria Popescu', 'Începător', 'Modern', 200.0, 60, 15, 'Sala 1', ARRAY['Luni 18:00', 'Miercuri 18:00']),
    ('55555555-5555-5555-5555-555555555555', 'Latin Dance - Intermediari', 'Curs de dans latin pentru intermediari', '22222222-2222-2222-2222-222222222222', 'Maria Popescu', 'Intermediar', 'Latin', 250.0, 90, 12, 'Sala 2', ARRAY['Marți 19:30', 'Joi 19:30'])
ON CONFLICT (id) DO NOTHING;

-- Inserare meniu bar de exemplu
INSERT INTO bar_menu (name, description, price, category, stock_quantity) VALUES
    ('Apa minerală', 'Apa minerală naturală 500ml', 5.0, 'Băuturi', 100),
    ('Suc de portocale', 'Suc natural de portocale 330ml', 8.0, 'Băuturi', 50),
    ('Sandwich cu șuncă', 'Sandwich cu șuncă și brânză', 15.0, 'Sandwich-uri', 20),
    ('Croissant', 'Croissant cu unt proaspăt', 12.0, 'Patiserie', 30)
ON CONFLICT DO NOTHING;

-- =====================================================
-- 9. COMENTARII ȘI DOCUMENTAȚIE
-- =====================================================

COMMENT ON TABLE profiles IS 'Profilurile utilizatorilor cu roluri și informații personale';
COMMENT ON TABLE courses IS 'Cursurile de dans cu detalii complete';
COMMENT ON TABLE enrollments IS 'Înscrierile utilizatorilor la cursuri';
COMMENT ON TABLE attendance IS 'Prezența la cursuri';
COMMENT ON TABLE qr_codes IS 'Codurile QR pentru check-in';
COMMENT ON TABLE bar_menu IS 'Meniul bar-ului cu produse disponibile';
COMMENT ON TABLE bar_orders IS 'Comenzile de la bar';
COMMENT ON TABLE wallets IS 'Portofelele digitale ale utilizatorilor';
COMMENT ON TABLE wallet_transactions IS 'Tranzacțiile din portofel';
COMMENT ON TABLE announcements IS 'Anunțurile pentru utilizatori';
COMMENT ON TABLE notifications IS 'Notificările pentru utilizatori';
COMMENT ON TABLE reservations IS 'Rezervările pentru cursuri';

-- =====================================================
-- SCHEMA COMPLETĂ AIU DANCE (CORECTATĂ)
-- =====================================================
-- Această schemă conține tot ce este necesar pentru:
-- ✅ Autentificare și autorizare cu roluri
-- ✅ Gestionarea cursurilor și instructorilor
-- ✅ Sistem de prezență cu QR codes
-- ✅ Portofel digital și plăți
-- ✅ Bar și comenzi
-- ✅ Anunțuri și notificări
-- ✅ Securitate RLS completă
-- ✅ Funcții utilitare
-- ✅ Date de exemplu
-- =====================================================








