# 🔧 INSTRUCȚIUNI PENTRU FIXAREA CONSTRAINT-ULUI ÎN SUPABASE

## Problema identificată:
Constraint-ul `profiles_role_check` din tabela `profiles` nu permite rolul `'student'`, ceea ce cauzează erori la încărcarea profilurilor.

## Soluția:

### 1. Accesează Supabase Dashboard
- Mergi la [https://supabase.com/dashboard](https://supabase.com/dashboard)
- Selectează proiectul AIU Dance
- Mergi la **SQL Editor**

### 2. Execută următorul script SQL:

```sql
-- 1. Verifică constraint-ul existent
SELECT conname, consrc 
FROM pg_constraint 
WHERE conname = 'profiles_role_check';

-- 2. Șterge constraint-ul existent
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

-- 3. Adaugă noul constraint care permite toate rolurile
ALTER TABLE profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('admin', 'student', 'instructor'));

-- 4. Verifică că constraint-ul a fost adăugat
SELECT conname, consrc 
FROM pg_constraint 
WHERE conname = 'profiles_role_check';
```

### 3. După executarea scriptului:
- Aplicația va funcționa normal
- Utilizatorii se vor putea loga fără erori
- Admin dashboard-ul se va încărca corect

## Verificare:
După executarea scriptului, încearcă să te loghezi din nou ca admin. Dashboard-ul ar trebui să se încarce corect.

## Note:
- Acest script este sigur și nu va afecta datele existente
- Doar actualizează constraint-ul pentru a permite rolul 'student'
- Toate celelalte roluri ('admin', 'instructor') rămân neschimbate
