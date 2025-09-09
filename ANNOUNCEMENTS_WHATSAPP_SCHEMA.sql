-- ANNOUNCEMENTS WHATSAPP SCHEMA
-- Adaugă funcționalitatea pentru distribuirea anunțurilor în WhatsApp și notificări

-- ========================================
-- 1. ADAUGĂ COLOANELE PENTRU PUBLICARE
-- ========================================

DO $$
BEGIN
    -- is_published
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'announcements' AND column_name = 'is_published') THEN
        ALTER TABLE public.announcements ADD COLUMN is_published boolean DEFAULT false;
        RAISE NOTICE '✅ Coloana is_published adăugată';
    END IF;
    
    -- published_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'announcements' AND column_name = 'published_at') THEN
        ALTER TABLE public.announcements ADD COLUMN published_at timestamp with time zone;
        RAISE NOTICE '✅ Coloana published_at adăugată';
    END IF;
    
    -- distribution_method
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'announcements' AND column_name = 'distribution_method') THEN
        ALTER TABLE public.announcements ADD COLUMN distribution_method text;
        RAISE NOTICE '✅ Coloana distribution_method adăugată';
    END IF;
    
    -- reminder_sent_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'announcements' AND column_name = 'reminder_sent_at') THEN
        ALTER TABLE public.announcements ADD COLUMN reminder_sent_at timestamp with time zone;
        RAISE NOTICE '✅ Coloana reminder_sent_at adăugată';
    END IF;
    
    -- reminder_count
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'announcements' AND column_name = 'reminder_count') THEN
        ALTER TABLE public.announcements ADD COLUMN reminder_count integer DEFAULT 0;
        RAISE NOTICE '✅ Coloana reminder_count adăugată';
    END IF;
END $$;

-- ========================================
-- 2. CREEAZĂ TABELA PENTRU REMINDER-E
-- ========================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' AND table_name = 'announcement_reminders') THEN
        
        CREATE TABLE public.announcement_reminders (
            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            announcement_id uuid REFERENCES public.announcements(id) ON DELETE CASCADE,
            instructor_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
            reminder_type text DEFAULT 'hourly', -- hourly, daily
            next_reminder_at timestamp with time zone NOT NULL,
            total_reminders_sent integer DEFAULT 0,
            max_reminders integer DEFAULT 24, -- Maxim 24 de reminder-e (o zi)
            is_active boolean DEFAULT true,
            created_at timestamp with time zone DEFAULT now()
        );
        
        RAISE NOTICE '✅ Tabela announcement_reminders creată cu succes';
    ELSE
        RAISE NOTICE '✅ Tabela announcement_reminders există deja';
    END IF;
END $$;

-- Index pentru performanță
CREATE INDEX IF NOT EXISTS idx_announcement_reminders_next_reminder ON public.announcement_reminders(next_reminder_at);
CREATE INDEX IF NOT EXISTS idx_announcement_reminders_active ON public.announcement_reminders(is_active);

-- RLS pentru announcement_reminders
ALTER TABLE public.announcement_reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "announcement_reminders_policy" ON public.announcement_reminders;
CREATE POLICY "announcement_reminders_policy" ON public.announcement_reminders FOR ALL USING (
    auth.uid() = instructor_id OR 
    (SELECT auth.jwt() ->> 'role') = 'admin'
);

-- ========================================
-- 3. FUNCȚIE PENTRU TRIMITEREA REMINDER-ELOR
-- ========================================

CREATE OR REPLACE FUNCTION send_announcement_reminders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    reminder_record record;
BEGIN
    -- Găsește reminder-ele care trebuie trimise
    FOR reminder_record IN 
        SELECT ar.*, a.title, p.full_name, p.email
        FROM announcement_reminders ar
        JOIN announcements a ON ar.announcement_id = a.id
        JOIN profiles p ON ar.instructor_id = p.id
        WHERE ar.is_active = true
          AND ar.next_reminder_at <= now()
          AND ar.total_reminders_sent < ar.max_reminders
          AND a.is_published = false
    LOOP
        -- Creează notificarea
        INSERT INTO notifications (
            user_id,
            title,
            body,
            type,
            data,
            read,
            sent_at
        ) VALUES (
            reminder_record.instructor_id,
            'Anunț nepublicat - Reminder #' || (reminder_record.total_reminders_sent + 1),
            'Anunțul "' || reminder_record.title || '" așteaptă să fie publicat în WhatsApp.',
            'announcement_reminder',
            jsonb_build_object(
                'announcement_id', reminder_record.announcement_id,
                'reminder_number', reminder_record.total_reminders_sent + 1,
                'instructor_name', reminder_record.full_name
            ),
            false,
            now()
        );
        
        -- Actualizează reminder-ul
        UPDATE announcement_reminders
        SET 
            total_reminders_sent = total_reminders_sent + 1,
            next_reminder_at = now() + interval '1 hour',
            is_active = CASE 
                WHEN total_reminders_sent + 1 >= max_reminders THEN false 
                ELSE true 
            END
        WHERE id = reminder_record.id;
        
    END LOOP;
END;
$$;

-- ========================================
-- 4. FUNCȚIE PENTRU MARCAREA CA PUBLICAT
-- ========================================

CREATE OR REPLACE FUNCTION mark_announcement_published(
    p_announcement_id uuid,
    p_distribution_method text DEFAULT 'app_only'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Marchează anunțul ca publicat
    UPDATE announcements
    SET 
        is_published = true,
        published_at = now(),
        distribution_method = p_distribution_method,
        updated_at = now()
    WHERE id = p_announcement_id;
    
    -- Dezactivează reminder-ele pentru acest anunț
    UPDATE announcement_reminders
    SET 
        is_active = false,
        updated_at = now()
    WHERE announcement_id = p_announcement_id;
    
    RETURN true;
END;
$$;

-- ========================================
-- 5. DATE DEMO PENTRU TESTARE
-- ========================================

-- Actualizează anunțurile existente
UPDATE public.announcements 
SET 
    is_published = COALESCE(is_published, false),
    distribution_method = CASE 
        WHEN is_published = true THEN COALESCE(distribution_method, 'app_only')
        ELSE NULL
    END,
    reminder_count = COALESCE(reminder_count, 0)
WHERE is_published IS NULL;

-- ========================================
-- 6. VERIFICARE FINALĂ
-- ========================================

DO $$
DECLARE
    announcements_columns integer;
    reminders_exists boolean;
    functions_exist integer;
BEGIN
    -- Numără coloanele din announcements
    SELECT count(*) FROM information_schema.columns 
    WHERE table_name = 'announcements' INTO announcements_columns;
    
    -- Verifică tabela reminders
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'announcement_reminders'
    ) INTO reminders_exists;
    
    -- Verifică funcțiile
    SELECT count(*) FROM information_schema.routines 
    WHERE routine_name IN ('send_announcement_reminders', 'mark_announcement_published') 
    INTO functions_exist;
    
    RAISE NOTICE '✅ VERIFICARE WHATSAPP SCHEMA:';
    RAISE NOTICE '   - Coloane announcements: %', announcements_columns;
    RAISE NOTICE '   - Tabela reminders: %', reminders_exists;
    RAISE NOTICE '   - Funcții create: %', functions_exist;
    
    IF announcements_columns >= 8 AND reminders_exists AND functions_exist >= 2 THEN
        RAISE NOTICE '🎉 Schema WhatsApp pentru anunțuri este gata!';
    ELSE
        RAISE NOTICE '❌ Probleme detectate în schema WhatsApp';
    END IF;
END $$;

-- ========================================
-- FINAL
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 Script ANNOUNCEMENTS_WHATSAPP_SCHEMA completat!';
    RAISE NOTICE '📱 Instructorii pot acum distribui anunțuri în WhatsApp!';
    RAISE NOTICE '🔔 Reminder-ele din oră în oră sunt activate!';
END $$;

