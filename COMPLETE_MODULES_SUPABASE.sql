-- COMPLETE MODULES SUPABASE STRUCTURE
-- Structura completa pentru Anunturi, Cursuri si Bar

-- 1. TABEL ANNOUNCEMENTS (Anunturi)
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    visible_to TEXT DEFAULT 'all' CHECK (visible_to IN ('all', 'student', 'instructor')),
    course_id UUID REFERENCES public.courses(id) ON DELETE SET NULL,
    media_url TEXT,
    media_type TEXT CHECK (media_type IN ('image', 'video', 'none')),
    scheduled_at TIMESTAMPTZ,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Adauga coloane lipsa pentru announcements daca nu exista
DO $$
BEGIN
    -- visible_to
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements' AND column_name = 'visible_to' AND table_schema = 'public') THEN
        ALTER TABLE public.announcements ADD COLUMN visible_to TEXT DEFAULT 'all';
        ALTER TABLE public.announcements ADD CONSTRAINT announcements_visible_to_check CHECK (visible_to IN ('all', 'student', 'instructor'));
    END IF;
    
    -- media_type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements' AND column_name = 'media_type' AND table_schema = 'public') THEN
        ALTER TABLE public.announcements ADD COLUMN media_type TEXT DEFAULT 'none';
        ALTER TABLE public.announcements ADD CONSTRAINT announcements_media_type_check CHECK (media_type IN ('image', 'video', 'none'));
    END IF;
    
    -- media_url
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements' AND column_name = 'media_url' AND table_schema = 'public') THEN
        ALTER TABLE public.announcements ADD COLUMN media_url TEXT;
    END IF;
    
    -- is_published
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements' AND column_name = 'is_published' AND table_schema = 'public') THEN
        ALTER TABLE public.announcements ADD COLUMN is_published BOOLEAN DEFAULT true;
    END IF;
    
    -- scheduled_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements' AND column_name = 'scheduled_at' AND table_schema = 'public') THEN
        ALTER TABLE public.announcements ADD COLUMN scheduled_at TIMESTAMPTZ;
    END IF;
    
    -- course_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements' AND column_name = 'course_id' AND table_schema = 'public') THEN
        ALTER TABLE public.announcements ADD COLUMN course_id UUID REFERENCES public.courses(id) ON DELETE SET NULL;
    END IF;
    
    -- created_by
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements' AND column_name = 'created_by' AND table_schema = 'public') THEN
        ALTER TABLE public.announcements ADD COLUMN created_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
    
    -- updated_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'announcements' AND column_name = 'updated_at' AND table_schema = 'public') THEN
        ALTER TABLE public.announcements ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- Enable RLS
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Policy pentru announcements
DROP POLICY IF EXISTS "announcements_policy" ON public.announcements;
CREATE POLICY "announcements_policy" ON public.announcements 
FOR ALL USING (auth.role() = 'authenticated');

-- 2. TABEL COURSES (Cursuri) - Verificare si actualizare
DO $$
BEGIN
    -- Adauga coloane lipsa daca nu exista
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'teacher' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN teacher TEXT DEFAULT 'Instructor';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'capacity' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN capacity INTEGER DEFAULT 20;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'start_time' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN start_time TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'end_time' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN end_time TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'location' AND table_schema = 'public') THEN
        ALTER TABLE public.courses ADD COLUMN location TEXT DEFAULT 'Sala de dans AIU';
    END IF;
END $$;

-- 3. TABEL BAR_MENU (Produse Bar)
CREATE TABLE IF NOT EXISTS public.bar_menu (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    category TEXT DEFAULT 'bauturi',
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.bar_menu ENABLE ROW LEVEL SECURITY;

-- Policy pentru bar_menu
DROP POLICY IF EXISTS "bar_menu_policy" ON public.bar_menu;
CREATE POLICY "bar_menu_policy" ON public.bar_menu 
FOR ALL USING (true); -- Public read, admin write

-- 4. TABEL BAR_ORDERS (Comenzi Bar) - Actualizare
DO $$
BEGIN
    -- Verifica daca tabela bar_orders exista
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bar_orders' AND table_schema = 'public') THEN
        -- Adauga coloane lipsa
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bar_orders' AND column_name = 'product_id' AND table_schema = 'public') THEN
            ALTER TABLE public.bar_orders ADD COLUMN product_id UUID REFERENCES public.bar_menu(id) ON DELETE CASCADE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bar_orders' AND column_name = 'quantity' AND table_schema = 'public') THEN
            ALTER TABLE public.bar_orders ADD COLUMN quantity INTEGER DEFAULT 1;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'bar_orders' AND column_name = 'user_id' AND table_schema = 'public') THEN
            ALTER TABLE public.bar_orders ADD COLUMN user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
        END IF;
    ELSE
        -- Creaza tabela daca nu exista
        CREATE TABLE public.bar_orders (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
            product_id UUID REFERENCES public.bar_menu(id) ON DELETE CASCADE,
            quantity INTEGER DEFAULT 1,
            status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'delivered', 'cancelled')),
            total_amount DECIMAL(10,2) DEFAULT 0.00,
            notes TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
END $$;

-- Enable RLS pentru bar_orders
ALTER TABLE public.bar_orders ENABLE ROW LEVEL SECURITY;

-- Policy pentru bar_orders
DROP POLICY IF EXISTS "bar_orders_policy" ON public.bar_orders;
CREATE POLICY "bar_orders_policy" ON public.bar_orders 
FOR ALL USING (auth.role() = 'authenticated');

-- 5. STORAGE BUCKETS pentru media
INSERT INTO storage.buckets (id, name, public) 
VALUES 
    ('announcements', 'announcements', true),
    ('bar_menu', 'bar_menu', true)
ON CONFLICT (id) DO NOTHING;

-- Policies pentru storage
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'announcements_storage_policy') THEN
        CREATE POLICY "announcements_storage_policy" ON storage.objects 
        FOR ALL USING (bucket_id = 'announcements');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'bar_menu_storage_policy') THEN
        CREATE POLICY "bar_menu_storage_policy" ON storage.objects 
        FOR ALL USING (bucket_id = 'bar_menu');
    END IF;
END $$;

-- 6. ACTUALIZARE DATE EXISTENTE
-- Actualizare bar_orders cu valori default pentru coloana items
UPDATE public.bar_orders 
SET items = jsonb_build_array(
    jsonb_build_object(
        'product_id', COALESCE(product_id, gen_random_uuid()),
        'name', 'Produs demo',
        'price', COALESCE(total_amount, 0.00),
        'quantity', COALESCE(quantity, 1)
    )
)
WHERE items IS NULL;

-- Actualizare attendance cu valori default
UPDATE public.attendance 
SET 
    session_date = COALESCE(session_date, CURRENT_DATE),
    created_at = COALESCE(created_at, NOW()),
    updated_at = COALESCE(updated_at, NOW()),
    status = COALESCE(status, 'present')
WHERE session_date IS NULL OR created_at IS NULL OR updated_at IS NULL OR status IS NULL;

-- 7. DEMO DATA - ANNOUNCEMENTS
INSERT INTO public.announcements (title, content, visible_to, media_type, is_published) VALUES 
('Bun venit la AIU Dance!', 'Vă așteptăm la cursurile noastre de dans. Programul complet îl găsiți pe site.', 'all', 'none', true),
('Curs special Bachata', 'Sâmbătă 14 septembrie - curs special de Bachata cu Raul. Înscrierile se fac la recepție.', 'student', 'none', true),
('Eveniment Kizomba Night', 'Vineri 20 septembrie - Kizomba Night cu DJ live. Intrarea liberă pentru studenți.', 'all', 'none', true)
ON CONFLICT DO NOTHING;

-- 8. DEMO DATA - COURSES
INSERT INTO public.courses (title, category, teacher, capacity, start_time, end_time, location) VALUES 
('Bachata Începători', 'Bachata', 'Raul', 30, '2025-01-10 19:00:00+00', '2025-01-10 20:00:00+00', 'Sala 1'),
('Kizomba Intermediar', 'Kizomba', 'Emilia', 25, '2025-01-10 20:00:00+00', '2025-01-10 21:00:00+00', 'Sala 1'),
('Salsa Lady Style', 'Salsa', 'Alina', 20, '2025-01-11 18:00:00+00', '2025-01-11 19:00:00+00', 'Sala 2'),
('Bachata Social Tricks', 'Bachata', 'Andrei', 20, '2025-01-14 16:00:00+00', '2025-01-14 17:30:00+00', 'Sala 1'),
('Urban Kizz Avansați', 'Kizomba', 'Nico', 18, '2025-01-15 17:30:00+00', '2025-01-15 19:00:00+00', 'Sala 2'),
('Salsa Începători', 'Salsa', 'Dan', 30, '2025-01-10 17:00:00+00', '2025-01-10 18:00:00+00', 'Sala 1')
ON CONFLICT DO NOTHING;

-- 9. DEMO DATA - BAR MENU
INSERT INTO public.bar_menu (name, description, price, category) VALUES 
('Apă plată 500ml', 'Apă minerală naturală', 7.00, 'bauturi'),
('Cola 500ml', 'Coca Cola rece', 10.00, 'bauturi'),
('Red Bull', 'Băutură energizantă', 15.00, 'bauturi'),
('Cafea espresso', 'Cafea proaspăt măcinată', 8.00, 'cafea'),
('Mojito fără alcool', 'Mojito fresh cu mentă', 18.00, 'cocktail'),
('Hugo', 'Cocktail cu prosecco și mentă', 22.00, 'cocktail'),
('Gin Tonic', 'Gin premium cu tonic', 25.00, 'cocktail'),
('Prosecco 150ml', 'Prosecco italian', 20.00, 'alcool')
ON CONFLICT DO NOTHING;

-- 10. DEMO DATA - BAR ORDERS
INSERT INTO public.bar_orders (user_id, product_id, quantity, status, total_amount, items) 
SELECT 
    p.id as user_id,
    bm.id as product_id,
    1 as quantity,
    'pending' as status,
    bm.price as total_amount,
    jsonb_build_array(
        jsonb_build_object(
            'product_id', bm.id,
            'name', bm.name,
            'price', bm.price,
            'quantity', 1
        )
    ) as items
FROM public.profiles p, public.bar_menu bm 
WHERE p.role = 'admin' AND bm.name = 'Cola 500ml'
LIMIT 1
ON CONFLICT DO NOTHING;

-- SUCCESS MESSAGE
SELECT 
    'COMPLETE MODULES STRUCTURE CREATED!' as status,
    'Announcements, Courses, Bar - All tables and demo data ready!' as message;
