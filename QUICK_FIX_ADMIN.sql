-- =====================================================
-- 🚀 QUICK FIX PENTRU ADMIN DASHBOARD
-- =====================================================
-- Execută acest script în Supabase Dashboard > SQL Editor
-- Pentru a fixa rapid problema cu Admin Dashboard

-- 1. Fixează constraint-ul pentru roluri
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check CHECK (role IN ('admin', 'student', 'instructor'));

-- Verifică că constraint-ul a fost adăugat
SELECT conname, contype 
FROM pg_constraint 
WHERE conname = 'profiles_role_check';

-- 2. Creează profilul admin cu ID-ul specificat
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

-- 3. Verifică că profilul a fost creat
SELECT * FROM profiles WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf';

-- 4. Creează tabelele de bază dacă nu există
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

CREATE TABLE IF NOT EXISTS wallets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) UNIQUE,
  balance DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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

-- 5. Activează RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

-- 6. Creează policies de bază
CREATE POLICY IF NOT EXISTS "Users can view their own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY IF NOT EXISTS "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY IF NOT EXISTS "Anyone can view active courses" ON courses
  FOR SELECT USING (is_active = true);

CREATE POLICY IF NOT EXISTS "Users can view their own wallet" ON wallets
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY IF NOT EXISTS "Users can view their own transactions" ON wallet_transactions
  FOR SELECT USING (user_id = auth.uid());

-- ✅ GATA! Acum poți rula aplicația
