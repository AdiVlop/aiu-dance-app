# 🎭 AIU Dance - Brevo Integration Manual Setup

## 📧 **Credențiale Brevo furnizate:**
- **SMTP Server**: smtp-relay.brevo.com
- **Port**: 587
- **Login**: 96b766001@smtp-brevo.com
- **Password**: UArdmNSZHEGa6bLX
- **API Key**: UArdmNSZHEGa6bLX

## 🔧 **Configurare Manuală în Supabase Dashboard**

### **1. SMTP Configuration**
Mergi la **Authentication → Email → SMTP** și configurează:

```
Host: smtp-relay.brevo.com
Port: 587 (STARTTLS)
Username: 96b766001@smtp-brevo.com
Password: UArdmNSZHEGa6bLX
From name: AIU Dance
From email: noreply@appauidance.com
```

### **2. Email Templates**
Mergi la **Authentication → Templates → Confirm signup** și folosește:

```html
<h1>Confirmă-ți contul AIU Dance</h1>
<p>Bună!</p>
<p>Apasă butonul de mai jos pentru a confirma emailul și a activa contul tău:</p>
<a href="{{ .ConfirmationURL }}" style="background: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block; margin: 20px 0;">
  Confirmă Email
</a>
<p>Dacă nu ai creat acest cont, poți ignora acest email.</p>
<p>Echipa AIU Dance</p>
```

## 🚀 **Deploy Edge Function și Migrație**

### **Instalează Supabase CLI:**
```bash
npm install -g supabase
```

### **Configurează proiectul:**
```bash
# Link la proiect
supabase link --project-ref wphitbnrfcyzehjbpztd

# Setează secretele
supabase secrets set BREVO_API_KEY=UArdmNSZHEGa6bLX
supabase secrets set BREVO_LIST_ID=0
supabase secrets set HOOK_SECRET=4486c721d94bdaecbedfec2fc5cb76acc676255a28b001a5

# Deploy Edge Function
supabase functions deploy brevo-upsert-contact

# Aplică migrația
supabase db push
```

## 🧪 **Testare**

### **1. Test SMTP:**
- Mergi la **Authentication → Email** în Supabase Dashboard
- Apasă **Send test email**
- Verifică că emailul ajunge în inbox

### **2. Test Edge Function:**
```bash
curl -X POST https://wphitbnrfcyzehjbpztd.functions.supabase.co/brevo-upsert-contact \
  -H "Content-Type: application/json" \
  -H "x-hook-secret: 4486c721d94bdaecbedfec2fc5cb76acc676255a28b001a5" \
  -d '{"email":"test@aiudance.com","firstName":"Test","lastName":"User"}'
```

### **3. Test end-to-end:**
1. Creează un user nou în aplicația AIU Dance
2. Verifică că primești emailul de confirmare
3. Apasă link-ul de confirmare
4. Verifică în Brevo Dashboard că contactul a fost adăugat

## 🔍 **Troubleshooting**

### **Verifică logs Edge Function:**
```bash
supabase functions logs --function brevo-upsert-contact
```

### **Verifică secretele:**
```bash
supabase secrets list
```

### **Verifică migrația:**
```bash
supabase db diff
```

## ✅ **Checklist Final**

- [ ] SMTP configurat în Supabase Dashboard
- [ ] Email template personalizat
- [ ] Supabase CLI instalat
- [ ] Proiectul link-uit
- [ ] Secretele Brevo setate
- [ ] Edge Function deployată
- [ ] Migrația aplicată
- [ ] Test SMTP funcțional
- [ ] Test Edge Function funcțional
- [ ] Test end-to-end funcțional

## 🎯 **Rezultat Așteptat**

Când un utilizator se înregistrează:
1. ✅ Primește email de confirmare prin Brevo SMTP
2. ✅ Apasă link-ul de confirmare
3. ✅ Contul este activat în Supabase
4. ✅ Contactul este automat adăugat în Brevo
5. ✅ Utilizatorul poate accesa aplicația AIU Dance

**🎭 Integrarea este completă și gata pentru utilizare!**
