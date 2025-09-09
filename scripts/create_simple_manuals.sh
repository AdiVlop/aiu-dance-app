#!/bin/bash

echo "📚 Generare Manuale Simple pentru Module AIU Dance..."
echo "=================================================="

# Creează directorul pentru manualele modulelor
mkdir -p docs/modules

# Funcție pentru generarea unui manual simplu
create_simple_manual() {
    local module_name=$1
    local module_title=$2
    local module_emoji=$3
    local description=$4
    
    echo "📝 Creare manual pentru $module_title..."
    
    # Creează fișierul Markdown pentru modul
    cat > "docs/modules/Manual_${module_name}.md" << EOF
# ${module_emoji} MANUAL ${module_title}

## 📋 Prezentare Generală

### Ce este ${module_title}?
${description}

### Funcționalități Principale
- Gestionarea ${module_name,,}
- Interfață intuitivă și ușor de folosit
- Statistici în timp real
- Integrare cu toate modulele aplicației

## 🚀 Acces și Navigare

### Accesul la Modul
1. **Autentificare:** Conectați-vă cu credențialele de admin
2. **Dashboard:** Accesați dashboard-ul principal
3. **Navigare:** Folosiți meniul lateral pentru acces
4. **Quick Actions:** Utilizați butoanele de acțiune rapidă

### Permisiuni Necesare
- **Admin:** Acces complet la toate funcții
- **Instructor:** Acces limitat (dacă aplicabil)
- **Student:** Acces doar citire (dacă aplicabil)

## ⚙️ Operațiuni de Bază

### Adăugare Element Nou
1. Clic pe butonul "Adaugă"
2. Completați toate câmpurile obligatorii
3. Verificați datele introduse
4. Clic pe "Salvează"

### Editare Element
1. Clic pe elementul de editat
2. Modificați câmpurile necesare
3. Clic pe "Actualizează"
4. Verificați modificările

### Ștergere Element
1. Selectați elementul de șters
2. Clic pe "Șterge"
3. Confirmați operațiunea

## 📊 Statistici și Rapoarte

### Statistici în Timp Real
- Număr total de elemente
- Activități recente
- Tendințe și evoluții
- Metrici de performanță

### Export Date
- Export PDF pentru rapoarte
- Export Excel pentru analize
- Backup automat al datelor

## ❓ FAQ și Troubleshooting

### Întrebări Frecvente

**Q: Cum pot adăuga un element nou?**
A: Clic pe butonul "Adaugă" și completați formularul.

**Q: Cum pot edita un element existent?**
A: Clic pe elementul dorit și apoi pe "Editează".

**Q: Cum pot șterge un element?**
A: Selectați elementul și clic pe "Șterge".

**Q: Cum pot exporta datele?**
A: Folosiți butonul "Export" și selectați formatul dorit.

### Probleme Comune

**Problema:** Elementul nu se salvează
**Soluția:** Verificați că toate câmpurile obligatorii sunt completate

**Problema:** Interfața nu se încarcă
**Soluția:** Verificați conexiunea la internet și reîncărcați pagina

**Problema:** Datele nu se sincronizează
**Soluția:** Verificați conexiunea Firebase și reîncărcați

## 📞 Support

### Contact Direct
- **Email:** support@aiudance.com
- **Telefon:** +40 XXX XXX XXX
- **WhatsApp:** +40 XXX XXX XXX

### Program de Suport
- **Luni-Vineri:** 9:00-18:00
- **Sâmbătă:** 9:00-14:00
- **Duminică:** Închis

## 🔗 Link-uri Utile

- **Aplicația Principală:** https://aiu-dance.web.app
- **Dashboard Admin:** https://aiu-dance.web.app/admin
- **Manual Complet:** ../Manual_AIU_Dance_Complet.html
- **Support Email:** support@aiudance.com

---

*Manual generat automat pentru ${module_title}*
*Data: $(date +'%d %B %Y')*
*Versiune: 2.0*
EOF

    # Generează HTML-ul pentru modul
    pandoc "docs/modules/Manual_${module_name}.md" \
        --css=docs/manual_style.css \
        --metadata title="Manual ${module_title} - AIU Dance" \
        --metadata author="AIU Dance Team" \
        --metadata date="$(date +'%d %B %Y')" \
        --standalone \
        -o "docs/modules/Manual_${module_name}.html"
    
    echo "✅ Manual pentru $module_title generat cu succes!"
}

# Generează manualele pentru fiecare modul
echo "🔄 Generare manuale pentru toate modulele..."

# 1. Master Wallet
create_simple_manual "Master_Wallet" "MASTER WALLET" "💰" "Modulul Master Wallet permite gestionarea completă a fondurilor aplicației, inclusiv adăugarea, retragerea și transferul de bani, precum și generarea de rapoarte financiare detaliate."

# 2. QR Bar Management
create_simple_manual "QR_Bar_Management" "QR BAR MANAGEMENT" "📱" "Modulul QR Bar Management oferă funcționalități complete pentru gestionarea barului, inclusiv produse, comenzi, plăți și generarea de coduri QR pentru meniuri."

# 3. QR Generator
create_simple_manual "QR_Generator" "QR GENERATOR" "🔢" "Modulul QR Generator permite crearea de coduri QR pentru diverse scopuri: cursuri, evenimente, discount-uri și alte tipuri de informații."

# 4. User Management
create_simple_manual "User_Management" "USER MANAGEMENT" "👥" "Modulul User Management oferă funcționalități complete pentru gestionarea utilizatorilor: adăugare, editare, ștergere și administrarea permisiunilor."

# 5. Course Management
create_simple_manual "Course_Management" "COURSE MANAGEMENT" "📚" "Modulul Course Management permite gestionarea completă a cursurilor: creare, editare, ștergere și administrarea înscrierilor studenților."

# 6. Enrollment Management
create_simple_manual "Enrollment_Management" "ENROLLMENT MANAGEMENT" "📝" "Modulul Enrollment Management oferă funcționalități avansate pentru gestionarea înscrierilor, setarea prețurilor individuale și procesarea plăților."

# 7. Reports Analytics
create_simple_manual "Reports_Analytics" "REPORTS & ANALYTICS" "📊" "Modulul Reports & Analytics oferă rapoarte detaliate și analize pentru toate aspectele aplicației, cu grafice interactive și export de date."

# 8. Daily Reservations
create_simple_manual "Daily_Reservations" "DAILY RESERVATIONS" "📅" "Modulul Daily Reservations permite gestionarea rezervărilor zilnice pentru cursuri, cu integrare WhatsApp pentru notificări și anunțuri."

# 9. Announcements
create_simple_manual "Announcements" "ANNOUNCEMENTS" "📢" "Modulul Announcements oferă funcționalități complete pentru crearea și gestionarea anunțurilor, cu integrare social media și programare automată."

# 10. QR Scanner
create_simple_manual "QR_Scanner" "QR SCANNER" "📱" "Modulul QR Scanner permite scanarea și procesarea codurilor QR pentru diverse tipuri de operațiuni: prezență, comenzi, discount-uri."

# 11. Bar QR Scanner
create_simple_manual "Bar_QR_Scanner" "BAR QR SCANNER" "🍹" "Modulul Bar QR Scanner oferă funcționalități specifice pentru scanarea codurilor QR de la bar, afișarea meniului și procesarea comenzilor."

# 12. Instructor Dashboard
create_simple_manual "Instructor_Dashboard" "INSTRUCTOR DASHBOARD" "👨‍🏫" "Modulul Instructor Dashboard oferă o interfață personalizată pentru instructori, cu funcționalități pentru gestionarea cursurilor și studenților."

# 13. User Dashboard
create_simple_manual "User_Dashboard" "USER DASHBOARD" "👤" "Modulul User Dashboard oferă o interfață personalizată pentru utilizatori, cu funcționalități pentru gestionarea cursurilor și contului personal."

# 14. Wallet Management
create_simple_manual "Wallet_Management" "WALLET MANAGEMENT" "💳" "Modulul Wallet Management permite utilizatorilor să gestioneze contul personal, să adauge fonduri și să vizualizeze istoricul tranzacțiilor."

# Creează un index pentru toate manualele
cat > docs/modules/README_Module_Manuals.md << 'EOF'
# 📚 Manuale Module AIU Dance

## 📋 Lista Manualelor

### Module Administrative
1. **[💰 Master Wallet](Manual_Master_Wallet.html)** - Gestionare fonduri aplicație
2. **[📱 QR Bar Management](Manual_QR_Bar_Management.html)** - Gestionare bar și produse
3. **[🔢 QR Generator](Manual_QR_Generator.html)** - Generare coduri QR
4. **[👥 User Management](Manual_User_Management.html)** - Gestionare utilizatori
5. **[📚 Course Management](Manual_Course_Management.html)** - Gestionare cursuri
6. **[📝 Enrollment Management](Manual_Enrollment_Management.html)** - Gestionare înscrieri
7. **[📊 Reports & Analytics](Manual_Reports_Analytics.html)** - Rapoarte și analize
8. **[📅 Daily Reservations](Manual_Daily_Reservations.html)** - Rezervări zilnice
9. **[📢 Announcements](Manual_Announcements.html)** - Gestionare anunțuri

### Module de Utilizare
10. **[📱 QR Scanner](Manual_QR_Scanner.html)** - Scanare coduri QR
11. **[🍹 Bar QR Scanner](Manual_Bar_QR_Scanner.html)** - Scanare QR bar
12. **[👨‍🏫 Instructor Dashboard](Manual_Instructor_Dashboard.html)** - Dashboard instructor
13. **[👤 User Dashboard](Manual_User_Dashboard.html)** - Dashboard utilizator
14. **[💳 Wallet Management](Manual_Wallet_Management.html)** - Gestionare wallet personal

## 🎯 Utilizare

### Pentru Administratori
- Studiați toate manualele administrative
- Focus pe Master Wallet și Reports
- Înțelegeți integrarea între module

### Pentru Instructori
- Concentrați-vă pe Instructor Dashboard
- Înțelegeți Course Management
- Folosiți QR Scanner pentru prezență

### Pentru Utilizatori
- Studiați User Dashboard
- Înțelegeți Wallet Management
- Folosiți QR Scanner pentru cursuri

## 📝 Actualizare

Pentru a actualiza manualele:
1. Editați fișierele Markdown corespunzătoare
2. Rulați `./scripts/create_simple_manuals.sh`
3. Verificați fișierele HTML generate

## 🔗 Link-uri Utile

- **Manual Complet:** ../Manual_AIU_Dance_Complet.html
- **Aplicația Live:** https://aiu-dance.web.app
- **Support:** support@aiudance.com

---

*Manuale generate automat pe $(date)*
EOF

echo ""
echo "✅ Toate manualele au fost generate cu succes!"
echo "📁 Fișiere generate în directorul 'docs/modules/':"
ls -la docs/modules/

echo ""
echo "📚 Manuale generate:"
echo "   • Master Wallet"
echo "   • QR Bar Management"
echo "   • QR Generator"
echo "   • User Management"
echo "   • Course Management"
echo "   • Enrollment Management"
echo "   • Reports & Analytics"
echo "   • Daily Reservations"
echo "   • Announcements"
echo "   • QR Scanner"
echo "   • Bar QR Scanner"
echo "   • Instructor Dashboard"
echo "   • User Dashboard"
echo "   • Wallet Management"

echo ""
echo "🎯 Următorii pași:"
echo "   1. Distribuiți manualele echipei"
echo "   2. Actualizați manualele la fiecare versiune"
echo "   3. Adăugați screenshot-uri specifice"
echo "   4. Traduceți în alte limbi dacă este necesar"

