#!/bin/bash

echo "📚 Generare Manuale Module AIU Dance..."
echo "======================================"

# Creează directorul pentru manualele modulelor
mkdir -p docs/modules

# Funcție pentru generarea unui manual de modul
generate_module_manual() {
    local module_name=$1
    local module_title=$2
    local module_emoji=$3
    local content=$4
    
    echo "📝 Generare manual pentru $module_title..."
    
    # Creează fișierul Markdown pentru modul
    cat > "docs/modules/Manual_${module_name}.md" << EOF
# ${module_emoji} MANUAL ${module_title}
## Ghid de utilizare complet

---

## 📋 CUPRINS

1. [🔍 Prezentare Generală](#prezentare-generală)
2. [🚀 Acces și Navigare](#acces-și-navigare)
3. [⚙️ Funcționalități Principale](#funcționalități-principale)
4. [📱 Interfața Utilizator](#interfața-utilizator)
5. [🔧 Operațiuni de Bază](#operațiuni-de-bază)
6. [⚡ Operațiuni Avansate](#operațiuni-avansate)
7. [📊 Statistici și Rapoarte](#statistici-și-rapoarte)
8. [❓ FAQ și Troubleshooting](#faq-și-troubleshooting)
9. [📞 Support](#support)

---

## 🔍 PREZENTARE GENERALĂ

### Ce este ${module_title}?
${content}

### Când să folosești ${module_title}?
- Pentru gestionarea ${module_name,,}
- Pentru vizualizarea statisticilor
- Pentru operațiuni administrative
- Pentru raportare și analiză

### Beneficii
- Interfață intuitivă și ușor de folosit
- Funcționalități complete pentru toate operațiunile
- Statistici în timp real
- Integrare cu toate modulele aplicației

---

## 🚀 ACCES ȘI NAVIGARE

### Accesul la Modul
1. **Autentificare:** Conectați-vă cu credențialele de admin
2. **Dashboard:** Accesați dashboard-ul principal
3. **Navigare:** Folosiți meniul lateral pentru acces
4. **Quick Actions:** Utilizați butoanele de acțiune rapidă

### Permisiuni Necesare
- **Admin:** Acces complet la toate funcții
- **Instructor:** Acces limitat (dacă aplicabil)
- **Student:** Acces doar citire (dacă aplicabil)

### Browser Compatibilitate
- **Chrome** (Recomandat)
- **Safari**
- **Firefox**
- **Edge**

---

## ⚙️ FUNCȚIONALITĂȚI PRINCIPALE

### Operațiuni de Bază
- **Vizualizare:** Lista completă de elemente
- **Adăugare:** Crearea de noi elemente
- **Editare:** Modificarea elementelor existente
- **Ștergere:** Eliminarea elementelor

### Operațiuni Avansate
- **Filtrare:** Căutare și filtrare avansată
- **Sortare:** Organizarea datelor
- **Export:** Descărcarea datelor
- **Import:** Încărcarea datelor

### Integrări
- **Firebase:** Sincronizare în timp real
- **Social Media:** Partajare și notificări
- **Email:** Trimitere rapoarte
- **WhatsApp:** Notificări și anunțuri

---

## 📱 INTERFAȚA UTILIZATOR

### Layout Principal
- **Header:** Titlu și navigare
- **Sidebar:** Meniu principal
- **Content:** Zona principală de lucru
- **Footer:** Informații și link-uri

### Elemente de Interfață
- **Butoane:** Acțiuni principale
- **Formulare:** Introducere date
- **Tabele:** Afișare date
- **Grafice:** Vizualizare statistici

### Responsive Design
- **Desktop:** Interfață completă
- **Tablet:** Adaptată pentru touch
- **Mobile:** Optimizată pentru ecrane mici

---

## 🔧 OPERAȚIUNI DE BAZĂ

### Adăugare Element Nou
1. **Acces:** Clic pe butonul "Adaugă"
2. **Completare:** Introduceți toate câmpurile obligatorii
3. **Validare:** Verificați datele introduse
4. **Salvare:** Clic pe "Salvează"

### Editare Element
1. **Selectare:** Clic pe elementul de editat
2. **Modificare:** Schimbați câmpurile necesare
3. **Actualizare:** Clic pe "Actualizează"
4. **Confirmare:** Verificați modificările

### Ștergere Element
1. **Selectare:** Clic pe elementul de șters
2. **Confirmare:** Clic pe "Șterge"
3. **Verificare:** Confirmați operațiunea
4. **Finalizare:** Elementul este eliminat

---

## ⚡ OPERAȚIUNI AVANSATE

### Filtrare și Căutare
- **Căutare text:** Introducere termeni de căutare
- **Filtrare după dată:** Selectare perioadă
- **Filtrare după categorie:** Selectare tip
- **Filtrare după statut:** Selectare stare

### Sortare și Organizare
- **Sortare după nume:** Alfabetic
- **Sortare după dată:** Cronologic
- **Sortare după prioritate:** Importanță
- **Sortare personalizată:** Criterii proprii

### Export și Import
- **Export PDF:** Rapoarte în format PDF
- **Export Excel:** Date în format Excel
- **Import CSV:** Încărcare date din fișiere
- **Backup:** Salvarea datelor

---

## 📊 STATISTICI ȘI RAPOARTE

### Statistici în Timp Real
- **Număr total:** Elemente în sistem
- **Activități recente:** Ultimele operațiuni
- **Tendințe:** Evoluția în timp
- **Performanță:** Metrici de eficiență

### Rapoarte Disponibile
- **Raport zilnic:** Activități pe zi
- **Raport săptămânal:** Sumar săptămânal
- **Raport lunar:** Analiză lunară
- **Raport anual:** Rezumat anual

### Grafice și Vizualizări
- **Grafice de linie:** Evoluția în timp
- **Grafice de bare:** Comparații
- **Grafice circulare:** Distribuții
- **Heatmaps:** Concentrații

---

## ❓ FAQ ȘI TROUBLESHOOTING

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

**Problema:** Exportul nu funcționează
**Soluția:** Verificați permisiunile browser-ului pentru descărcări

---

## 📞 SUPPORT

### Contact Direct
- **Email:** support@aiudance.com
- **Telefon:** +40 XXX XXX XXX
- **WhatsApp:** +40 XXX XXX XXX

### Program de Suport
- **Luni-Vineri:** 9:00-18:00
- **Sâmbătă:** 9:00-14:00
- **Duminică:** Închis

### Canale de Suport
- **Email:** Pentru probleme tehnice
- **Telefon:** Pentru urgențe
- **WhatsApp:** Pentru întrebări rapide
- **Chat:** Pentru asistență în timp real

### Documentație Suplimentară
- **Manual Complet:** docs/Manual_AIU_Dance_Complet.html
- **Video Tutorials:** Link-uri către ghiduri video
- **FAQ Online:** Secțiunea de întrebări frecvente
- **Community:** Forum-ul utilizatorilor

---

## 🔗 LINK-URI UTILE

- **Aplicația Principală:** https://aiu-dance.web.app
- **Dashboard Admin:** https://aiu-dance.web.app/admin
- **Documentație Completă:** docs/Manual_AIU_Dance_Complet.html
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
generate_module_manual "Master_Wallet" "MASTER WALLET" "💰" "Modulul Master Wallet permite gestionarea completă a fondurilor aplicației, inclusiv adăugarea, retragerea și transferul de bani, precum și generarea de rapoarte financiare detaliate."

# 2. QR Bar Management
generate_module_manual "QR_Bar_Management" "QR BAR MANAGEMENT" "📱" "Modulul QR Bar Management oferă funcționalități complete pentru gestionarea barului, inclusiv produse, comenzi, plăți și generarea de coduri QR pentru meniuri."

# 3. QR Generator
generate_module_manual "QR_Generator" "QR GENERATOR" "🔢" "Modulul QR Generator permite crearea de coduri QR pentru diverse scopuri: cursuri, evenimente, discount-uri și alte tipuri de informații."

# 4. User Management
generate_module_manual "User_Management" "USER MANAGEMENT" "👥" "Modulul User Management oferă funcționalități complete pentru gestionarea utilizatorilor: adăugare, editare, ștergere și administrarea permisiunilor."

# 5. Course Management
generate_module_manual "Course_Management" "COURSE MANAGEMENT" "📚" "Modulul Course Management permite gestionarea completă a cursurilor: creare, editare, ștergere și administrarea înscrierilor studenților."

# 6. Enrollment Management
generate_module_manual "Enrollment_Management" "ENROLLMENT MANAGEMENT" "📝" "Modulul Enrollment Management oferă funcționalități avansate pentru gestionarea înscrierilor, setarea prețurilor individuale și procesarea plăților."

# 7. Reports Analytics
generate_module_manual "Reports_Analytics" "REPORTS & ANALYTICS" "📊" "Modulul Reports & Analytics oferă rapoarte detaliate și analize pentru toate aspectele aplicației, cu grafice interactive și export de date."

# 8. Daily Reservations
generate_module_manual "Daily_Reservations" "DAILY RESERVATIONS" "📅" "Modulul Daily Reservations permite gestionarea rezervărilor zilnice pentru cursuri, cu integrare WhatsApp pentru notificări și anunțuri."

# 9. Announcements
generate_module_manual "Announcements" "ANNOUNCEMENTS" "📢" "Modulul Announcements oferă funcționalități complete pentru crearea și gestionarea anunțurilor, cu integrare social media și programare automată."

# 10. QR Scanner
generate_module_manual "QR_Scanner" "QR SCANNER" "📱" "Modulul QR Scanner permite scanarea și procesarea codurilor QR pentru diverse tipuri de operațiuni: prezență, comenzi, discount-uri."

# 11. Bar QR Scanner
generate_module_manual "Bar_QR_Scanner" "BAR QR SCANNER" "🍹" "Modulul Bar QR Scanner oferă funcționalități specifice pentru scanarea codurilor QR de la bar, afișarea meniului și procesarea comenzilor."

# 12. Instructor Dashboard
generate_module_manual "Instructor_Dashboard" "INSTRUCTOR DASHBOARD" "👨‍🏫" "Modulul Instructor Dashboard oferă o interfață personalizată pentru instructori, cu funcționalități pentru gestionarea cursurilor și studenților."

# 13. User Dashboard
generate_module_manual "User_Dashboard" "USER DASHBOARD" "👤" "Modulul User Dashboard oferă o interfață personalizată pentru utilizatori, cu funcționalități pentru gestionarea cursurilor și contului personal."

# 14. Wallet Management
generate_module_manual "Wallet_Management" "WALLET MANAGEMENT" "💳" "Modulul Wallet Management permite utilizatorilor să gestioneze contul personal, să adauge fonduri și să vizualizeze istoricul tranzacțiilor."

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
2. Rulați `./scripts/generate_module_manuals.sh`
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

