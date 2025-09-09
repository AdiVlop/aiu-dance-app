-- =====================================================
-- 🔧 SETUP COMPLET SUPABASE PENTRU AIU DANCE
-- =====================================================
-- Execută acest script în Supabase Dashboard > SQL Editor
-- Rulează toate comenzile în ordine pentru setup complet

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
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  role = 'admin',
  is_active = true,
  updated_at = NOW();

-- Verifică că profilul a fost creat/actualizat
SELECT * FROM profiles 
WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf';

-- =====================================================
-- 3. CREEAZĂ TABELELE NECESARE (dacă nu există)
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
  type VARCHAR(50) NOT NULL, -- 'topup', 'payment', 'refund'
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'completed', 'failed'
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
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'completed', 'cancelled'
  UNIQUE(user_id, course_id)
);

-- Tabela attendance
CREATE TABLE IF NOT EXISTS attendance (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  course_id UUID REFERENCES courses(id),
  attended_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'present' -- 'present', 'absent', 'late'
);

-- =====================================================
-- 4. CREEAZĂ ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Activează RLS pentru toate tabelele
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

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
CREATE POLICY "Anyone can view active courses" ON courses
  FOR SELECT USING (is_active = true);

CREATE POLICY "Instructors can manage their courses" ON courses
  FOR ALL USING (
    instructor_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies pentru wallets
CREATE POLICY "Users can view their own wallet" ON wallets
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own wallet" ON wallets
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Admins can view all wallets" ON wallets
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies pentru wallet_transactions
CREATE POLICY "Users can view their own transactions" ON wallet_transactions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view all transactions" ON wallet_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- 5. CREEAZĂ FUNCȚII UTILE
-- =====================================================

-- Funcție pentru a actualiza updated_at automat
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pentru updated_at
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at 
  BEFORE UPDATE ON courses 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at 
  BEFORE UPDATE ON wallets 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 6. INSEREAZĂ DATE DE TEST (opțional)
-- =====================================================

-- Creează un instructor de test
INSERT INTO profiles (
  id,
  email,
  full_name,
  role,
  is_active,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'instructor@aiudance.ro',
  'Instructor Test',
  'instructor',
  true,
  NOW(),
  NOW()
) ON CONFLICT (email) DO NOTHING;

-- Creează un student de test
INSERT INTO profiles (
  id,
  email,
  full_name,
  role,
  is_active,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'student@aiudance.ro',
  'Student Test',
  'student',
  true,
  NOW(),
  NOW()
) ON CONFLICT (email) DO NOTHING;

-- =====================================================
-- 7. VERIFICĂRI FINALE
-- =====================================================

-- Verifică toate tabelele
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

-- Verifică profilul admin
SELECT * FROM profiles 
WHERE email = 'adrian@payai-x.com';

-- =====================================================
-- ✅ SETUP COMPLET FINALIZAT
-- =====================================================
-- Acum poți rula aplicația Flutter cu toate tabelele
-- și permisiunile configurate corect!
