-- ===============================================
-- NOTIFICATIONS FIX - Creează tabela notifications cu coloana 'read'
-- ===============================================

-- 1. Șterge tabela existentă dacă există (pentru a evita conflictele)
DROP TABLE IF EXISTS public.notifications CASCADE;

-- 2. Creează tabela notifications cu toate coloanele necesare
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    read BOOLEAN DEFAULT false,
    type TEXT DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error')),
    metadata JSONB,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- 3. Creează index pentru performanță
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_read ON public.notifications(read);
CREATE INDEX idx_notifications_sent_at ON public.notifications(sent_at);

-- 4. Activează RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 5. Creează policies RLS
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() 
            AND (role = 'admin' OR role = 'instructor')
        )
    );

CREATE POLICY "Admins can view all notifications" ON public.notifications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() 
            AND (role = 'admin' OR role = 'instructor')
        )
    );

-- 6. Inserează notificări demo
INSERT INTO public.notifications (user_id, title, body, type, read)
SELECT 
    p.id,
    'Bine ai venit în AIU Dance!',
    'Explorează cursurile disponibile și înscrie-te la cel care îți place.',
    'info',
    false
FROM public.profiles p
WHERE p.email = 'adrian@payai-x.com'
ON CONFLICT DO NOTHING;

INSERT INTO public.notifications (user_id, title, body, type, read)
SELECT 
    p.id,
    'Sistem de plăți activat',
    'Acum poți plăti cursurile prin Cash, Wallet, Revolut sau în Rate.',
    'success',
    false
FROM public.profiles p
WHERE p.email = 'adrian@payai-x.com'
ON CONFLICT DO NOTHING;

-- 7. Verifică rezultatul
SELECT 
    'notifications' as table_name, 
    count(*) as total_records,
    count(*) FILTER (WHERE read = false) as unread_count
FROM public.notifications;
