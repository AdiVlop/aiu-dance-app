-- =====================================================
-- AIU Dance - Brevo Integration Migration
-- =====================================================
-- Creează trigger pentru upsert contact în Brevo la confirmarea emailului

-- 1) Extensia pentru HTTP din Postgres
create extension if not exists pg_net;

-- 2) Funcție care se apelează la confirmarea emailului
create or replace function public.on_user_email_confirmed()
returns trigger
language plpgsql
security definer
as $$
declare
  hook_url text := 'https://wphitbnrfcyzehjbpztd.functions.supabase.co/brevo-upsert-contact';
  hook_secret text := '4486c721d94bdaecbedfec2fc5cb76acc676255a28b001a5'; -- Secret pentru validare webhook
  first_name text := coalesce((new.raw_user_meta_data->>'first_name'), '');
  last_name  text := coalesce((new.raw_user_meta_data->>'last_name'),  '');
  payload jsonb := jsonb_build_object(
    'email', new.email,
    'firstName', first_name,
    'lastName',  last_name
  );
begin
  -- Rulează doar când email_confirmed_at devine non-null prima oară
  if (new.email_confirmed_at is not null and old.email_confirmed_at is null) then
    -- Log pentru debugging
    raise notice '🎭 AIU Dance: User email confirmed for %', new.email;
    
    -- Apelează Edge Function pentru upsert contact în Brevo
    perform net.http_post(
      url := hook_url,
      headers := jsonb_build_object(
        'Content-Type','application/json',
        'x-hook-secret', hook_secret
      ),
      body := payload,
      timeout_milliseconds := 10000 -- 10 secunde timeout
    );
    
    raise notice '✅ AIU Dance: Brevo upsert request sent for %', new.email;
  end if;
  
  return new;
end;
$$;

-- 3) Trigger pe auth.users
drop trigger if exists trg_on_user_email_confirmed on auth.users;
create trigger trg_on_user_email_confirmed
after update on auth.users
for each row
execute function public.on_user_email_confirmed();

-- 4) Comentarii pentru documentație
comment on function public.on_user_email_confirmed() is 'Trigger function that calls Brevo API to upsert contact when user confirms email';
