# 🚀 CONFIGURARE SUPABASE PENTRU AIU DANCE

## 📋 Pași de configurare

### 1. Creează cont Supabase
1. Mergi la [supabase.com](https://supabase.com)
2. Apasă "Start your project"
3. Creează un cont nou sau conectează-te cu GitHub

### 2. Creează proiectul
1. Apasă "New Project"
2. Alege organizația
3. Denumește proiectul: `aiu-dance`
4. Alege o parolă pentru baza de date
5. Alege regiunea (recomand: `West Europe` pentru România)
6. Apasă "Create new project"

### 3. Obține credențialele
1. În proiect, mergi la **Settings** → **API**
2. Copiază:
   - **Project URL** (ex: `https://wphitbnrfcyzehjbpztd.supabase.co`)
   - **anon public** key (ex: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

### 4. Testează conexiunea
1. Verifică că URL-ul și cheia sunt corecte
2. Testează cu widget-ul din `SupabaseTestWidget`
3. Verifică consola pentru mesaje de succes/eroare

### 4. Actualizează configurația
În `lib/config/supabase_config.dart`, înlocuiește:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://xyzcompany.supabase.co';  // URL-ul tău real
  static const String supabaseAnonKey = 'eyJhbGciOi...';               // Cheia ta reală
}
```

### 5. Rulează schema bazei de date
1. În Supabase, mergi la **SQL Editor**
2. Copiază conținutul din `database_schema.sql`
3. Apasă "Run" pentru a crea toate tabelele

### 6. Configurează autentificarea
1. În **Authentication** → **Settings**
2. Activează **Email auth**
3. Opțional: activează **Google auth** pentru login cu Google

### 7. Testează aplicația
```bash
flutter run -d chrome
```

## 🔑 Variabile de mediu (opțional)

Pentru securitate, poți folosi variabile de mediu:

1. Creează `.env` în rădăcina proiectului:
```env
SUPABASE_URL=https://xyzcompany.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
```

2. Instalează `flutter_dotenv`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

3. Actualizează `supabase_config.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
```

4. În `main.dart`:
```dart
void main() async {
  await dotenv.load(fileName: ".env");
  // ... restul codului
}
```

## 🧪 Testare

### Widget de test
Folosește `SupabaseTestWidget` din `lib/examples/supabase_usage_example.dart`:

```dart
// În orice ecran
SupabaseTestWidget()
```

### Testare login
1. Creează un utilizator în Supabase (Authentication → Users)
2. Testează login-ul cu credențialele
3. Verifică consola pentru mesaje de succes/eroare

## 🚨 Probleme comune

### Eroare "Invalid API key"
- Verifică că ai copiat cheia completă
- Verifică că folosești cheia `anon public`, nu `service_role`

### Eroare "Connection failed"
- Verifică URL-ul proiectului
- Verifică că proiectul este activ
- Verifică firewall-ul

### Eroare "Table doesn't exist"
- Rulează schema din `database_schema.sql`
- Verifică că tabelele au fost create în **Table Editor**

## 📱 Testare pe iOS

După configurarea Supabase:

```bash
flutter run -d "iPhone 16 Plus"
```

**Nu ar mai trebui să apară erorile BoringSSL-GRPC!** 🎉

## 🔒 Securitate

- **NU** comite cheia `service_role` în Git
- **NU** expune cheia `anon` în codul client (este OK să fie publică)
- Folosește **Row Level Security (RLS)** pentru protecția datelor
- Configurează **policies** pentru fiecare tabelă

## 📚 Resurse

- [Supabase Flutter Docs](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Database Schema](database_schema.sql)

---

**🎯 Obiectiv: Aplicația AIU Dance să ruleze fără probleme pe iOS cu Supabase!**








