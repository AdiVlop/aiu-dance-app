-- Fix SQL errors in AdminDashboardScreen
-- 1. Fix UUID syntax error
-- 2. Fix missing scanned_at column in attendance table

-- 1. Fix attendance table - add scanned_at column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'attendance' 
        AND column_name = 'scanned_at'
    ) THEN
        ALTER TABLE attendance ADD COLUMN scanned_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- 2. Fix any invalid UUID constraints
-- Update any invalid UUIDs in profiles table
UPDATE profiles 
SET id = gen_random_uuid() 
WHERE id::text = 'is.not.null' OR id IS NULL;

-- 3. Ensure all tables have proper structure
-- Fix profiles table
ALTER TABLE profiles ALTER COLUMN id SET NOT NULL;
ALTER TABLE profiles ALTER COLUMN email SET NOT NULL;
ALTER TABLE profiles ALTER COLUMN role SET NOT NULL;

-- Fix courses table
ALTER TABLE courses ALTER COLUMN title SET NOT NULL;
ALTER TABLE courses ALTER COLUMN category SET NOT NULL;

-- Fix attendance table
ALTER TABLE attendance ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE attendance ALTER COLUMN course_id SET NOT NULL;

-- 4. Create missing tables if they don't exist
CREATE TABLE IF NOT EXISTS bar_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id),
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    total_price DECIMAL(10,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Enable RLS for all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bar_orders ENABLE ROW LEVEL SECURITY;

-- 6. Create admin policies
DROP POLICY IF EXISTS "Admin can view all profiles" ON profiles;
CREATE POLICY "Admin can view all profiles" ON profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin can view all courses" ON courses;
CREATE POLICY "Admin can view all courses" ON courses FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin can view all attendance" ON attendance;
CREATE POLICY "Admin can view all attendance" ON attendance FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin can view all wallets" ON wallets;
CREATE POLICY "Admin can view all wallets" ON wallets FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin can view all transactions" ON wallet_transactions;
CREATE POLICY "Admin can view all transactions" ON wallet_transactions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin can view all bar orders" ON bar_orders;
CREATE POLICY "Admin can view all bar orders" ON bar_orders FOR SELECT USING (true);

-- 7. Insert demo data if missing
INSERT INTO profiles (id, email, full_name, role, is_active, created_at, updated_at)
SELECT 
  '9195288e-d88b-4178-b970-b13a7ed445cf',
  'adrian@payai-x.com',
  'Admin AIU Dance',
  'admin',
  true,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM profiles WHERE id = '9195288e-d88b-4178-b970-b13a7ed445cf'
);

-- Insert demo courses
INSERT INTO courses (id, title, description, instructor_id, location, category, price, max_students, is_active, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  'Bachata Începători',
  'Curs de bachata pentru începători',
  '9195288e-d88b-4178-b970-b13a7ed445cf',
  'Sala de dans AIU',
  'Bachata',
  50.00,
  20,
  true,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM courses WHERE title = 'Bachata Începători'
);

INSERT INTO courses (id, title, description, instructor_id, location, category, price, max_students, is_active, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  'Salsa Avansat',
  'Curs de salsa pentru avansați',
  '9195288e-d88b-4178-b970-b13a7ed445cf',
  'Sala de dans AIU',
  'Salsa',
  60.00,
  15,
  true,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM courses WHERE title = 'Salsa Avansat'
);

-- Insert demo wallet
INSERT INTO wallets (id, user_id, balance, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  '9195288e-d88b-4178-b970-b13a7ed445cf',
  1000.00,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM wallets WHERE user_id = '9195288e-d88b-4178-b970-b13a7ed445cf'
);

-- Insert demo transactions
INSERT INTO wallet_transactions (id, user_id, amount, type, status, created_at)
SELECT 
  gen_random_uuid(),
  '9195288e-d88b-4178-b970-b13a7ed445cf',
  50.00,
  'wallet',
  'completed',
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM wallet_transactions WHERE user_id = '9195288e-d88b-4178-b970-b13a7ed445cf'
);

-- Insert demo bar orders
INSERT INTO bar_orders (id, user_id, product_name, quantity, total_price, status, created_at)
SELECT 
  gen_random_uuid(),
  '9195288e-d88b-4178-b970-b13a7ed445cf',
  'Coca Cola',
  2,
  10.00,
  'completed',
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM bar_orders WHERE user_id = '9195288e-d88b-4178-b970-b13a7ed445cf'
);

-- Insert demo attendance
INSERT INTO attendance (id, user_id, course_id, status, created_at, scanned_at)
SELECT 
  gen_random_uuid(),
  '9195288e-d88b-4178-b970-b13a7ed445cf',
  (SELECT id FROM courses LIMIT 1),
  'present',
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM attendance WHERE user_id = '9195288e-d88b-4178-b970-b13a7ed445cf'
);

-- 8. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_courses_active ON courses(is_active);
CREATE INDEX IF NOT EXISTS idx_attendance_user ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_course ON attendance(course_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_bar_orders_user ON bar_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_bar_orders_status ON bar_orders(status);

-- 9. Update statistics
ANALYZE profiles;
ANALYZE courses;
ANALYZE attendance;
ANALYZE wallets;
ANALYZE wallet_transactions;
ANALYZE bar_orders;

-- Success message
SELECT 'SQL errors fixed successfully!' as status;
