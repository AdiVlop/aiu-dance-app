#!/bin/bash

echo "📚 Generare Manual AIU Dance în PDF..."
echo "======================================"

# Verifică dacă pandoc este instalat
if ! command -v pandoc &> /dev/null; then
    echo "❌ Pandoc nu este instalat. Instalând..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install pandoc
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt-get update
        sudo apt-get install -y pandoc
    else
        echo "❌ Sistemul de operare nu este suportat pentru instalarea automată"
        echo "📥 Instalați manual pandoc de la: https://pandoc.org/installing.html"
        exit 1
    fi
fi

# Creează directorul docs dacă nu există
mkdir -p docs

# Creează CSS pentru styling
cat > docs/manual_style.css << 'EOF'
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}

h1 {
    color: #2c3e50;
    border-bottom: 3px solid #3498db;
    padding-bottom: 10px;
    text-align: center;
}

h2 {
    color: #34495e;
    border-left: 4px solid #3498db;
    padding-left: 15px;
    margin-top: 30px;
}

h3 {
    color: #2980b9;
    margin-top: 25px;
}

h4 {
    color: #16a085;
    margin-top: 20px;
}

ul, ol {
    margin-left: 20px;
}

li {
    margin-bottom: 8px;
}

code {
    background-color: #f8f9fa;
    padding: 2px 6px;
    border-radius: 3px;
    font-family: 'Courier New', monospace;
}

pre {
    background-color: #f8f9fa;
    padding: 15px;
    border-radius: 5px;
    overflow-x: auto;
    border-left: 4px solid #3498db;
}

blockquote {
    border-left: 4px solid #e74c3c;
    padding-left: 15px;
    margin-left: 0;
    color: #7f8c8d;
}

table {
    border-collapse: collapse;
    width: 100%;
    margin: 20px 0;
}

th, td {
    border: 1px solid #ddd;
    padding: 12px;
    text-align: left;
}

th {
    background-color: #3498db;
    color: white;
}

tr:nth-child(even) {
    background-color: #f2f2f2;
}

.emoji {
    font-size: 1.2em;
}

.toc {
    background-color: #ecf0f1;
    padding: 20px;
    border-radius: 5px;
    margin: 20px 0;
}

.toc h2 {
    border-left: none;
    padding-left: 0;
    margin-top: 0;
}

.toc ul {
    list-style-type: none;
    padding-left: 0;
}

.toc li {
    margin-bottom: 5px;
}

.toc a {
    text-decoration: none;
    color: #2980b9;
}

.toc a:hover {
    text-decoration: underline;
}

.note {
    background-color: #fff3cd;
    border: 1px solid #ffeaa7;
    border-radius: 5px;
    padding: 15px;
    margin: 15px 0;
}

.warning {
    background-color: #f8d7da;
    border: 1px solid #f5c6cb;
    border-radius: 5px;
    padding: 15px;
    margin: 15px 0;
}

.success {
    background-color: #d4edda;
    border: 1px solid #c3e6cb;
    border-radius: 5px;
    padding: 15px;
    margin: 15px 0;
}

.page-break {
    page-break-before: always;
}

@media print {
    body {
        font-size: 12pt;
    }
    
    h1 {
        font-size: 18pt;
    }
    
    h2 {
        font-size: 16pt;
    }
    
    h3 {
        font-size: 14pt;
    }
    
    .page-break {
        page-break-before: always;
    }
}
EOF

# Generează HTML-ul mai întâi
echo "🔄 Generare HTML..."
pandoc docs/Manual_AIU_Dance_Complet.md \
    --css=docs/manual_style.css \
    --metadata title="Manual AIU Dance - Ghid Complet" \
    --metadata author="AIU Dance Team" \
    --metadata date="$(date +'%d %B %Y')" \
    --standalone \
    -o docs/Manual_AIU_Dance_Complet.html

# Încearcă să genereze PDF-ul cu diferite engine-uri
echo "🔄 Generare PDF..."

# Încearcă cu prince (dacă este disponibil)
if command -v prince &> /dev/null; then
    echo "📄 Folosind Prince pentru PDF..."
    prince docs/Manual_AIU_Dance_Complet.html -o docs/Manual_AIU_Dance_Complet.pdf
elif command -v wkhtmltopdf &> /dev/null; then
    echo "📄 Folosind wkhtmltopdf pentru PDF..."
    wkhtmltopdf docs/Manual_AIU_Dance_Complet.html docs/Manual_AIU_Dance_Complet.pdf
elif command -v weasyprint &> /dev/null; then
    echo "📄 Folosind WeasyPrint pentru PDF..."
    weasyprint docs/Manual_AIU_Dance_Complet.html docs/Manual_AIU_Dance_Complet.pdf
else
    echo "📄 Folosind pandoc cu LaTeX pentru PDF..."
    pandoc docs/Manual_AIU_Dance_Complet.md \
        --pdf-engine=xelatex \
        --metadata title="Manual AIU Dance - Ghid Complet" \
        --metadata author="AIU Dance Team" \
        --metadata date="$(date +'%d %B %Y')" \
        -o docs/Manual_AIU_Dance_Complet.pdf
fi

# Verifică dacă generarea a reușit
if [ -f "docs/Manual_AIU_Dance_Complet.pdf" ]; then
    echo "✅ Manual generat cu succes!"
    echo "📄 Fișier PDF: docs/Manual_AIU_Dance_Complet.pdf"
    echo "📏 Dimensiune PDF: $(du -h docs/Manual_AIU_Dance_Complet.pdf | cut -f1)"
    
    # Deschide PDF-ul dacă este macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🔍 Deschidere PDF..."
        open docs/Manual_AIU_Dance_Complet.pdf
    fi
else
    echo "⚠️  PDF-ul nu a putut fi generat, dar HTML-ul este disponibil"
    echo "📄 Fișier HTML: docs/Manual_AIU_Dance_Complet.html"
    
    # Deschide HTML-ul dacă este macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🔍 Deschidere HTML..."
        open docs/Manual_AIU_Dance_Complet.html
    fi
fi

# Creează și un fișier README pentru manual
cat > docs/README_Manual.md << 'EOF'
# 📚 Manual AIU Dance - Documentație

## 📄 Fișiere Disponibile

### Manual Complet
- **Manual_AIU_Dance_Complet.md** - Versiunea Markdown (editabilă)
- **Manual_AIU_Dance_Complet.html** - Versiunea HTML (vizualizare web)
- **Manual_AIU_Dance_Complet.pdf** - Versiunea PDF (printare)

### Styling
- **manual_style.css** - Fișierul CSS pentru styling

## 🎯 Conținut Manual

### Module Acoperite
1. **🔐 Autentificare și Acces**
2. **👨‍💼 Dashboard Admin**
3. **💰 Master Wallet**
4. **📱 QR Bar Management**
5. **🔢 QR Generator**
6. **👥 User Management**
7. **📚 Course Management**
8. **📝 Enrollment Management**
9. **📊 Reports & Analytics**
10. **📅 Daily Reservations**
11. **📢 Announcements**
12. **📱 QR Scanner**
13. **🍹 Bar QR Scanner**
14. **👨‍🏫 Instructor Dashboard**
15. **👤 User Dashboard**
16. **💳 Wallet Management**

### Secțiuni Suplimentare
- **🔧 Setări și Configurări**
- **📞 Support și Ajutor**
- **📱 Acces Mobil**
- **🔒 Securitate și Confidențialitate**
- **🚀 Funcționalități Avansate**

## 📝 Actualizare Manual

Pentru a actualiza manualul:

1. Editați `Manual_AIU_Dance_Complet.md`
2. Rulați `./scripts/generate_manual.sh`
3. Verificați fișierele generate

## 🎨 Personalizare

Pentru a personaliza styling-ul:
1. Editați `manual_style.css`
2. Regenerați manualul
3. Verificați rezultatul

## 📤 Distribuire

Manualul poate fi distribuit în oricare din formatele:
- **PDF** - Pentru printare și distribuție offline
- **HTML** - Pentru vizualizare online
- **Markdown** - Pentru editare și versionare

## 🔗 Link-uri Utile

- **Aplicația Live:** https://aiu-dance.web.app
- **Dashboard Admin:** https://aiu-dance.web.app/admin
- **Support:** support@aiudance.com

---

*Manual generat automat pe $(date)*
EOF

echo ""
echo "📚 Manualul conține:"
echo "   • Ghid complet pentru toate modulele"
echo "   • Screenshot-uri și exemple"
echo "   • FAQ și troubleshooting"
echo "   • Contact support"
echo ""
echo "🎯 Următorii pași:"
echo "   1. Distribuiți manualul echipei"
echo "   2. Actualizați manualul la fiecare versiune nouă"
echo "   3. Adăugați screenshot-uri specifice"
echo "   4. Traduceți în alte limbi dacă este necesar"
echo ""
echo "📁 Fișiere generate în directorul 'docs/':"
ls -la docs/
