-- 🚨 FIX INFINITE RECURSION IN SQL POLICIES
-- ==========================================
-- Execută acest script în Supabase Dashboard > SQL Editor
-- Șterge COMPLET toate policy-urile și le recreează fără recursiune

-- 1. ȘTERGE TOATE POLICY-URILE EXISTENTE
-- =====================================

-- Profiles policies
DROP POLICY IF EXISTS "Admins can do everything on profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;

-- Courses policies
DROP POLICY IF EXISTS "Admins can view all courses" ON courses;
DROP POLICY IF EXISTS "Instructors can view their courses" ON courses;
DROP POLICY IF EXISTS "Students can view active courses" ON courses;
DROP POLICY IF EXISTS "Enable read access for all users" ON courses;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON courses;
DROP POLICY IF EXISTS "Enable update for users based on email" ON courses;

-- Wallets policies
DROP POLICY IF EXISTS "Admins can view all wallets" ON wallets;
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON wallets;
DROP POLICY IF EXISTS "Enable read access for all users" ON wallets;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON wallets;
DROP POLICY IF EXISTS "Enable update for users based on email" ON wallets;

-- Wallet transactions policies
DROP POLICY IF EXISTS "Admins can view all transactions" ON wallet_transactions;
DROP POLICY IF EXISTS "Users can view their own transactions" ON wallet_transactions;
DROP POLICY IF EXISTS "Users can insert their own transactions" ON wallet_transactions;
DROP POLICY IF EXISTS "Enable read access for all users" ON wallet_transactions;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON wallet_transactions;
DROP POLICY IF EXISTS "Enable update for users based on email" ON wallet_transactions;

-- Enrollments policies
DROP POLICY IF EXISTS "Admins can view all enrollments" ON enrollments;
DROP POLICY IF EXISTS "Users can view their own enrollments" ON enrollments;
DROP POLICY IF EXISTS "Users can insert their own enrollments" ON enrollments;
DROP POLICY IF EXISTS "Enable read access for all users" ON enrollments;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON enrollments;
DROP POLICY IF EXISTS "Enable update for users based on email" ON enrollments;

-- Attendance policies
DROP POLICY IF EXISTS "Admins can view all attendance" ON attendance;
DROP POLICY IF EXISTS "Instructors can view their course attendance" ON attendance;
DROP POLICY IF EXISTS "Students can view their own attendance" ON attendance;
DROP POLICY IF EXISTS "Enable read access for all users" ON attendance;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON attendance;
DROP POLICY IF EXISTS "Enable update for users based on email" ON attendance;

-- 2. RECREEAZĂ POLICY-URILE SIMPLE FĂRĂ RECURSIUNE
-- ================================================

-- Policies pentru profiles - SIMPLE, FĂRĂ RECURSIUNE
CREATE POLICY "Users can view their own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Policies pentru courses - SIMPLE
CREATE POLICY "Everyone can view active courses" ON courses
  FOR SELECT USING (is_active = true);

CREATE POLICY "Instructors can manage their courses" ON courses
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'instructor'
    )
  );

-- Policies pentru wallets - SIMPLE
CREATE POLICY "Users can view their own wallet" ON wallets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet" ON wallets
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wallet" ON wallets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policies pentru wallet_transactions - SIMPLE
CREATE POLICY "Users can view their own transactions" ON wallet_transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own transactions" ON wallet_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policies pentru enrollments - SIMPLE
CREATE POLICY "Users can view their own enrollments" ON enrollments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own enrollments" ON enrollments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policies pentru attendance - SIMPLE
CREATE POLICY "Users can view their own attendance" ON attendance
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Instructors can manage attendance" ON attendance
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'instructor'
    )
  );

-- 3. ADĂUGĂ POLICY-URI SPECIALE PENTRU ADMIN
-- ===========================================

-- Admin poate vedea totul - FĂRĂ RECURSIUNE
CREATE POLICY "Admin can view all profiles" ON profiles
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'admin'
  );

CREATE POLICY "Admin can view all courses" ON courses
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'admin'
  );

CREATE POLICY "Admin can view all wallets" ON wallets
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'admin'
  );

CREATE POLICY "Admin can view all transactions" ON wallet_transactions
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'admin'
  );

CREATE POLICY "Admin can view all enrollments" ON enrollments
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'admin'
  );

CREATE POLICY "Admin can view all attendance" ON attendance
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'admin'
  );

-- ✅ GATA! Nu mai sunt policy-uri cu recursiune infinită!
-- Admin-ul poate vedea totul folosind JWT role, nu query-uri recursive!
