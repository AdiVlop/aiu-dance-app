# Changelog

Toate modificările importante ale proiectului AIU Dance vor fi documentate în acest fișier.

Formatul se bazează pe [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
iar acest proiect aderă la [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nici o funcționalitate nouă încă

### Changed
- Nici o modificare încă

### Deprecated
- Nici o funcționalitate depreciată încă

### Removed
- Nici o funcționalitate eliminată încă

### Fixed
- Nici o problemă rezolvată încă

### Security
- Nici o problemă de securitate rezolvată încă

---

## [1.0.0] - 2025-09-09

### Added
- **Sistem de autentificare complet**
  - Login și Register cu Firebase/Supabase
  - Autentificare prin email și parolă
  - Gestionare sesiuni utilizator

- **Dashboard-uri personalizate**
  - Dashboard Student cu cursuri și progres
  - Dashboard Instructor cu gestionare cursuri
  - Dashboard Admin cu control complet

- **Modul Wallet digital**
  - Portofel integrat pentru fiecare utilizator
  - Top-up prin Stripe cu carduri
  - Istoric tranzacții și balanțe
  - Integrare Revolut pentru plăți rapide

- **Sistem QR Code complet**
  - Check-in automat prin QR codes
  - Generare QR codes pentru cursuri
  - Scanare QR pentru prezență
  - QR codes pentru comenzi bar

- **Gestionare cursuri avansată**
  - Lista completă de cursuri disponibile
  - Înscrieri și dezînscrieri
  - Programe și orare
  - Gestionare instructori

- **Modul Bar digital**
  - Meniu complet cu produse
  - Comenzi prin QR code
  - Plăți integrate prin portofel
  - Gestionare comenzi în timp real

- **Sistem de notificări**
  - Notificări push pentru evenimente importante
  - Reminder-uri pentru cursuri
  - Actualizări despre plăți și tranzacții

- **Rapoarte și statistici**
  - Rapoarte financiare pentru admin
  - Statistici de prezență
  - Analize de utilizare
  - Export date în PDF

- **Interfață responsive**
  - Design modern și intuitiv
  - Suport pentru telefoane și tablete
  - Tema întunecată și luminoasă
  - Animații și tranziții fluide

### Technical Details
- **Frontend**: Flutter (Dart) cu design Material 3
- **Backend**: Supabase pentru baza de date și autentificare
- **Plăți**: Stripe API pentru procesarea plăților
- **Hosting**: Firebase Hosting pentru web
- **APK Distribution**: GitHub Releases cu CDN
- **QR Codes**: Generare și scanare integrate

### Known Issues
- **Play Protect Warnings**: Unele telefoane Android mai vechi pot afișa avertismente Play Protect la instalare. Utilizatorii trebuie să apese "Install anyway" sau "Allow from this source".
- **iOS Version**: Versiunea iOS nu este încă disponibilă. Se lucrează la o versiune pentru App Store.
- **Offline Mode**: Aplicația necesită conexiune internet pentru majoritatea funcționalităților.
- **Camera Permissions**: Pe unele dispozitive, permisiunile pentru cameră (necesare pentru QR scanning) pot necesita configurare manuală.

### System Requirements
- **Android**: 6.0+ (API level 23)
- **RAM**: Minimum 2GB recomandat
- **Storage**: 100MB spațiu liber
- **Network**: Conexiune internet pentru funcționalități complete

### Download Information
- **APK Size**: ~50MB
- **Download URL**: https://github.com/AdiVlop/aiu-dance-app/releases/download/v1.0.0/AIU_Dance_APK.apk
- **QR Code**: Disponibil pe pagina de download
- **Alternative**: Firebase Storage și cereri prin email/WhatsApp

### Support
- **Email**: admin@aiudance.ro
- **WhatsApp**: +40712345678
- **Website**: https://aiu-dance.web.app
- **GitHub**: https://github.com/AdiVlop/aiu-dance-app

---

## [0.9.0] - 2025-08-15

### Added
- Versiunea beta pentru testare internă
- Funcționalități de bază pentru autentificare
- Prototip pentru dashboard-uri

### Known Issues
- Instabilitate în sistemul de plăți
- Probleme cu sincronizarea datelor
- Interfață incompletă

---

## [0.1.0] - 2025-07-01

### Added
- Proiectul inițial AIU Dance
- Structura de bază Flutter
- Configurare Supabase
- Design-ul de bază al aplicației

---

## Legend

- **Added** pentru funcționalități noi
- **Changed** pentru modificări la funcționalități existente
- **Deprecated** pentru funcționalități care vor fi eliminate în versiuni viitoare
- **Removed** pentru funcționalități eliminate în această versiune
- **Fixed** pentru orice bug fix
- **Security** pentru vulnerabilități de securitate

---

## Cum să actualizezi CHANGELOG.md pentru versiuni viitoare

1. **Adaugă o nouă secțiune** pentru versiunea următoare în partea de sus (sub `[Unreleased]`)
2. **Folosește formatul standard** cu categoriile: Added, Changed, Deprecated, Removed, Fixed, Security
3. **Actualizează data** în format YYYY-MM-DD
4. **Documentează toate modificările** importante
5. **Menține consistența** în stilul de scriere
6. **Adaugă link-uri** către issue-uri sau PR-uri relevante dacă este cazul

### Exemplu pentru versiunea următoare:

```markdown
## [1.1.0] - 2025-10-15

### Added
- Funcționalitate nouă X
- Îmbunătățire Y

### Changed
- Modificare la funcționalitatea Z

### Fixed
- Bug fix pentru problema A
- Rezolvare pentru issue B

### Known Issues
- Lista problemelor cunoscute
```

---

*Ultima actualizare: 09 Septembrie 2025*

