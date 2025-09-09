-- =====================================================
-- 🚀 SUPABASE COMPLETE SETUP - FIXED VERSION
-- =====================================================
-- Execută acest script în Supabase Dashboard > SQL Editor
-- Versiune fără erori de syntax

-- =====================================================
-- 1. FIXEAZĂ CONSTRAINT-UL PENTRU ROLURI
-- =====================================================

-- Verifică constraint-ul existent
SELECT conname, contype 
FROM pg_constraint 
WHERE conname = 'profiles_role_check';

-- Șterge constraint-ul existent
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

-- Adaugă noul constraint care permite toate rolurile
ALTER TABLE profiles 
ADD CONSTRAINT profiles_role_check 
CHECK (role IN ('admin', 'student', 'instructor'));

-- Verifică că constraint-ul a fost adăugat
SELECT conname, contype 
FROM pg_constraint 
WHERE conname = 'profiles_role_check';

-- =====================================================
-- 2. VERIFICĂ ȘI CREEAZĂ PROFILUL ADMIN
-- =====================================================

-- Verifică dacă există utilizatorul în auth.users
SELECT id, email, raw_user_meta_data 
FROM auth.users 
WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf';

-- Verifică dacă există profilul în profiles
SELECT * FROM profiles 
WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf';

-- Creează sau actualizează profilul admin
INSERT INTO profiles (
  id,
  email,
  full_name,
  role,
  is_active,
  created_at,
  updated_at
) VALUES (
  '9195288e-d88b-4178-b970-b13a7ed445cf',
  'adrian@payai-x.com',
  'Admin',
  'admin',
  true,
  NOW(),
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  email = 'adrian@payai-x.com',
  full_name = 'Admin',
  role = 'admin',
  is_active = true,
  updated_at = NOW();

-- =====================================================
-- 3. CREEAZĂ TABELELE NECESARE
-- =====================================================

-- Tabela courses
CREATE TABLE IF NOT EXISTS courses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  instructor_id UUID REFERENCES profiles(id),
  price DECIMAL(10,2) DEFAULT 0,
  duration_minutes INTEGER DEFAULT 60,
  max_students INTEGER DEFAULT 20,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela wallets
CREATE TABLE IF NOT EXISTS wallets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) UNIQUE,
  balance DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela wallet_transactions
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  amount DECIMAL(10,2) NOT NULL,
  type VARCHAR(50) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  description TEXT,
  payment_intent_id VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela enrollments
CREATE TABLE IF NOT EXISTS enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  course_id UUID REFERENCES courses(id),
  enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'active',
  UNIQUE(user_id, course_id)
);

-- Tabela attendance
CREATE TABLE IF NOT EXISTS attendance (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  course_id UUID REFERENCES courses(id),
  attended_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'present'
);

-- =====================================================
-- 4. ACTIVEAZĂ ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. CREEAZĂ POLICIES DE SECURITATE
-- =====================================================

-- Policies pentru profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
CREATE POLICY "Users can view their own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies pentru courses
DROP POLICY IF EXISTS "Anyone can view active courses" ON courses;
CREATE POLICY "Anyone can view active courses" ON courses
  FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Instructors can manage their courses" ON courses;
CREATE POLICY "Instructors can manage their courses" ON courses
  FOR ALL USING (
    instructor_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies pentru wallets
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
CREATE POLICY "Users can view their own wallet" ON wallets
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own wallet" ON wallets;
CREATE POLICY "Users can update their own wallet" ON wallets
  FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all wallets" ON wallets;
CREATE POLICY "Admins can view all wallets" ON wallets
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies pentru wallet_transactions
DROP POLICY IF EXISTS "Users can view their own transactions" ON wallet_transactions;
CREATE POLICY "Users can view their own transactions" ON wallet_transactions
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all transactions" ON wallet_transactions;
CREATE POLICY "Admins can view all transactions" ON wallet_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies pentru enrollments
DROP POLICY IF EXISTS "Users can view their own enrollments" ON enrollments;
CREATE POLICY "Users can view their own enrollments" ON enrollments
  FOR SELECT USING (user_id = auth.uid());

-- Policies pentru attendance
DROP POLICY IF EXISTS "Users can view their own attendance" ON attendance;
CREATE POLICY "Users can view their own attendance" ON attendance
  FOR SELECT USING (user_id = auth.uid());

-- =====================================================
-- 6. CREEAZĂ FUNCȚIA PENTRU NOI UTILIZATORI
-- =====================================================

-- Șterge funcția existentă dacă există
DROP FUNCTION IF EXISTS handle_new_user();

-- Creează funcția pentru gestionarea noilor utilizatori
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name, role, is_active, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    true,
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. CREEAZĂ TRIGGER-UL PENTRU NOI UTILIZATORI
-- =====================================================

-- Șterge trigger-ul existent dacă există
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Creează trigger-ul pentru noii utilizatori
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- 8. VERIFICĂRI FINALE
-- =====================================================

-- Verifică tabelele create
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Verifică constraint-urile
SELECT conname, contype 
FROM pg_constraint 
WHERE conname LIKE '%role%' OR conname LIKE '%profiles%';

-- Verifică policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public';

-- Verifică funcțiile
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public';

-- Verifică trigger-urile
SELECT trigger_name, event_object_table, action_timing, event_manipulation 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- ✅ SETUP COMPLET! Aplicația AIU Dance este gata de utilizare
