# 🎭 AIU Dance - Ghid de Dezvoltare

## 📋 Prezentare Generală

**AIU Dance** este o aplicație Flutter cross-platform pentru gestionarea unei școli de dans, cu funcționalități complete pentru:
- 🔐 Autentificare utilizatori (studenți, instructori, admini)
- 📚 Gestionare cursuri și înscrieri
- 📱 QR Check-in pentru prezență
- 💰 Portofel digital cu tranzacții
- 🍹 Sistem de comenzi bar prin QR
- 📊 Dashboard administrativ cu rapoarte
- 📈 Analize și statistici

## 🏗️ Arhitectura Tehnică

### Backend
- **Supabase** - Platformă open-source cu PostgreSQL
- **Autentificare** - Supabase Auth cu RLS (Row Level Security)
- **Bază de date** - PostgreSQL cu scheme optimizate
- **Storage** - Supabase Storage pentru fișiere
- **Real-time** - Supabase Realtime pentru notificări

### Frontend
- **Flutter** - Framework cross-platform
- **State Management** - Provider pentru gestionarea stării
- **UI Components** - Material Design 3 cu teme personalizate
- **Navigation** - Routing cu `onGenerateRoute`

### Dependințe Cheie
```yaml
supabase_flutter: ^1.10.17    # Backend Supabase
provider: ^6.1.1              # State Management
qr_flutter: ^4.1.0            # Generare QR Codes
mobile_scanner: ^3.5.7        # Scanare QR
flutter_stripe: ^9.3.0        # Procesare plăți
pdf: ^3.10.7                  # Generare rapoarte PDF
share_plus: ^7.2.2            # Partajare fișiere
```

## 🚀 Instalare și Configurare

### 1. Cerințe Preliminare
- Flutter SDK 3.29.0+
- Dart 3.8.0+
- Android Studio / Xcode (pentru mobile)
- VS Code cu extensii Flutter

### 2. Clone și Setup
```bash
# Clonează repository-ul
git clone <repository-url>
cd aiu_dance

# Instalează dependințele
flutter pub get

# Verifică setup-ul
flutter doctor
```

### 3. Configurare Supabase
1. **Creează cont** pe [supabase.com](https://supabase.com)
2. **Creează proiect nou** cu numele "aiu-dance"
3. **Extrage credențialele** din Settings > API
4. **Actualizează** `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
```

### 4. Rulare Schema SQL
1. Deschide **Supabase Dashboard** > SQL Editor
2. Copiază conținutul din `supabase_schema.sql`
3. Rulează scriptul pentru a crea tabelele și funcțiile

### 5. Testare Aplicație
```bash
# Web
flutter run -d chrome --target=lib/main_supabase_final.dart

# iOS Simulator
flutter run -d "iPhone SE (3rd generation)" --target=lib/main_supabase_final.dart

# Android Emulator
flutter run -d "Pixel_4_API_30" --target=lib/main_supabase_final.dart
```

## 📁 Structura Proiectului

```
lib/
├── config/                          # Configurări
│   └── supabase_config.dart        # Credențiale Supabase
├── services/                        # Servicii și API
│   ├── supabase_service.dart       # Servicii principale
│   ├── supabase_auth_service.dart  # Autentificare
│   └── notification_service.dart   # Notificări
├── screens/                         # Ecrane aplicație
│   ├── auth/                       # Login & Register
│   ├── dashboard/                  # Dashboard principal
│   ├── courses/                    # Gestionare cursuri
│   ├── wallet/                     # Portofel digital
│   ├── qr/                         # QR Scanner
│   └── admin/                      # Dashboard admin
├── widgets/                         # Componente reutilizabile
│   ├── course_card.dart            # Card curs
│   ├── wallet_balance_card.dart    # Card portofel
│   ├── qr_code_generator.dart     # Generator QR
│   └── bar_order_tile.dart        # Tile comandă bar
├── models/                          # Modele de date
├── utils/                           # Utilități (Logger, etc.)
└── main_supabase_final.dart        # Entry point principal
```

## 🔐 Sistemul de Autentificare

### Flux de Autentificare
1. **Login** - Email + parolă
2. **Verificare** - Supabase Auth
3. **Profil** - Încărcare date utilizator
4. **Navigare** - Dashboard bazat pe rol

### Roluri Utilizatori
- **student** - Acces cursuri, portofel, QR check-in
- **instructor** - Gestionare cursuri, generare QR
- **admin** - Acces complet la toate funcționalitățile

### Securitate
- **RLS Policies** - Acces la date bazat pe rol
- **JWT Tokens** - Autentificare securizată
- **Validare Input** - Sanitizare date utilizator

## 📚 Gestionarea Cursurilor

### Structura Curs
```dart
{
  'id': 'uuid',
  'name': 'Salsa pentru începători',
  'description': 'Curs de salsa pentru începători',
  'category': 'salsa',
  'instructor_name': 'Maria Popescu',
  'start_time': '18:00',
  'end_time': '19:30',
  'max_students': 20,
  'enrolled_students': 15,
  'price': 150.0,
  'is_active': true
}
```

### Funcționalități
- **Listare cursuri** cu filtre pe categorii
- **Înscriere** cu verificare disponibilitate
- **QR Check-in** pentru prezență
- **Statistici** participanți și prezență

## 📱 Sistemul QR

### Tipuri QR
1. **Course Attendance** - Check-in la cursuri
2. **Bar Products** - Comenzi produse bar
3. **Event Check-in** - Evenimente speciale

### Generare QR
```dart
CourseQRGenerator(
  courseId: 'course-123',
  courseName: 'Salsa pentru începători',
  sessionDate: DateTime.now(),
  instructorId: 'instructor-456',
)
```

### Scanare QR
- **Camera** - Scanare directă cu camera
- **Galerie** - Selectare din galerie
- **Manual** - Introducere manuală cod

## 💰 Portofelul Digital

### Funcționalități
- **Sold curent** cu afișare vizuală
- **Top-up** cu Stripe sau numerar
- **Transfer** între utilizatori
- **Istoric** tranzacții complete
- **Export** rapoarte PDF

### Integrare Stripe
1. **Configurare** chei API în `stripe_config.dart`
2. **Webhook** pentru confirmarea plăților
3. **Securitate** - chei secrete în backend

## 🍹 Sistemul Bar

### Produse Bar
- **Catalog** cu prețuri și disponibilitate
- **QR Codes** pentru fiecare produs
- **Categorii** - băuturi, snacks, etc.

### Comenzi
- **Scanare QR** pentru selectare produs
- **Verificare sold** înainte de comandă
- **Procesare** cu confirmare automată
- **Status tracking** - pending, accepted, completed

## 📊 Dashboard Admin

### Statistici Principale
- **Utilizatori** - total, activi, noi
- **Cursuri** - active, înscrieri, prezență
- **Venituri** - total, lunar, tranzacții
- **Comenzi Bar** - pending, completed, revenue

### Funcționalități Admin
- **Gestionare utilizatori** - CRUD, roluri
- **Gestionare cursuri** - creare, editare, ștergere
- **Rapoarte** - export PDF, analize
- **Monitorizare** - status sistem, notificări

## 🔧 Dezvoltare și Debugging

### Comenzi Utile
```bash
# Clean și rebuild
flutter clean
flutter pub get

# Analiză cod
flutter analyze

# Teste
flutter test

# Build release
flutter build web --target=lib/main_supabase_final.dart --release
flutter build ios --target=lib/main_supabase_final.dart --release
flutter build apk --target=lib/main_supabase_final.dart --release
```

### Debugging
- **Flutter Inspector** - pentru UI debugging
- **Supabase Dashboard** - pentru debugging bază de date
- **Logger** - logging centralizat în `utils/logger.dart`
- **Hot Reload** - pentru dezvoltare rapidă

### Performance
- **Lazy Loading** - încărcare la cerere
- **Caching** - date locale cu SharedPreferences
- **Image Optimization** - compresie și lazy loading
- **Code Splitting** - încărcare modulară

## 📱 Responsive Design

### Breakpoints
- **Mobile** - < 768px
- **Tablet** - 768px - 1024px
- **Desktop** - > 1024px

### Adaptare UI
- **Layouts** - Grid vs List bazat pe screen size
- **Navigation** - Drawer vs Bottom Navigation
- **Components** - Adaptive sizing și spacing

## 🚀 Deployment

### Web (Supabase Hosting)
```bash
# Build pentru web
flutter build web --target=lib/main_supabase_final.dart --release

# Deploy pe Supabase
supabase functions deploy
```

### Mobile
```bash
# iOS
flutter build ios --target=lib/main_supabase_final.dart --release
# Uploadează .ipa în App Store Connect

# Android
flutter build apk --target=lib/main_supabase_final.dart --release
# Uploadează .aab în Google Play Console
```

## 🧪 Testing

### Unit Tests
```bash
flutter test test/unit/
```

### Widget Tests
```bash
flutter test test/widget/
```

### Integration Tests
```bash
flutter test test/integration/
```

### Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📚 Resurse și Documentație

### Flutter
- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Flutter Widget Catalog](https://docs.flutter.dev/development/ui/widgets)

### Supabase
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter](https://supabase.com/docs/reference/dart)
- [Supabase Examples](https://github.com/supabase/supabase-flutter)

### Design Patterns
- [Provider Pattern](https://pub.dev/packages/provider)
- [Repository Pattern](https://medium.com/@ayushpguptaapg/clean-architecture-in-flutter-using-repository-pattern-7b1b3c4b5b8c)
- [Service Layer Pattern](https://medium.com/flutter-community/flutter-service-layer-pattern-5c5c5c5c5c5c)

## 🤝 Contribuții

### Guidelines
1. **Fork** repository-ul
2. **Creează branch** pentru feature: `git checkout -b feature/nume-feature`
3. **Commit** modificările: `git commit -m 'Add: descriere feature'`
4. **Push** la branch: `git push origin feature/nume-feature`
5. **Creează Pull Request**

### Code Style
- **Dart Format** - `dart format .`
- **Lint Rules** - urmează `analysis_options.yaml`
- **Documentație** - comentarii pentru funcții complexe
- **Naming** - camelCase pentru variabile, PascalCase pentru clase

## 🐛 Troubleshooting

### Probleme Comune

#### 1. Supabase Connection
```bash
# Verifică credențialele
flutter run --verbose

# Testează conexiunea
curl -X GET "https://your-project.supabase.co/rest/v1/" \
  -H "apikey: your-anon-key"
```

#### 2. Build Errors
```bash
# Clean build
flutter clean
flutter pub get
flutter build web --target=lib/main_supabase_final.dart
```

#### 3. iOS Issues
```bash
# Clean iOS
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

#### 4. Android Issues
```bash
# Clean Android
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Logs și Debugging
- **Flutter Logs** - `flutter run --verbose`
- **Supabase Logs** - Dashboard > Logs
- **Device Logs** - Android Studio / Xcode
- **Network Logs** - Chrome DevTools > Network

## 📞 Suport și Contact

### Echipa de Dezvoltare
- **Lead Developer** - [Nume] - [email]
- **UI/UX Designer** - [Nume] - [email]
- **Backend Developer** - [Nume] - [email]

### Canale de Comunicare
- **GitHub Issues** - pentru bug reports
- **Discord** - pentru suport în timp real
- **Email** - pentru întrebări tehnice

---

## 🎯 Următorii Pași

1. **Completează setup-ul** Supabase
2. **Rulează schema SQL** pentru baza de date
3. **Testează autentificarea** cu utilizatori de test
4. **Explorează funcționalitățile** pe web și mobile
5. **Contribuie la dezvoltare** prin Pull Requests

**Happy Coding! 🚀**








