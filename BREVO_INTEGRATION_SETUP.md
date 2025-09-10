# 🎭 AIU Dance - Brevo Integration Setup

## 📋 **Obiectiv**
Integrează Supabase cu Brevo pentru:
- ✅ Email confirmation prin Brevo SMTP
- ✅ Upsert contact în Brevo la confirmarea emailului

## 🔧 **Configurare Manuală în Supabase Dashboard**

### **1. SMTP Configuration**
Mergi la **Authentication → Email → SMTP**:

```
Host: smtp-relay.brevo.com
Port: 587 (STARTTLS)
Username: your_brevo_email@domain.com
Password: your_brevo_smtp_key
From name: AIU Dance
From email: noreply@appauidance.com
```

### **2. Email Templates**
Mergi la **Authentication → Templates → Confirm signup**:

```html
<h1>Confirmă-ți contul AIU Dance</h1>
<p>Apasă butonul de mai jos pentru a confirma emailul:</p>
<a href="{{ .ConfirmationURL }}" style="background: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
  Confirmă Email
</a>
```

## 🚀 **Deploy automat**

### **Rulează scriptul de setup:**
```bash
./setup_brevo_integration.sh
```

### **Setează credențialele Brevo:**
```bash
supabase secrets set BREVO_API_KEY=your_brevo_api_key_here
supabase secrets set BREVO_LIST_ID=your_brevo_list_id_here
supabase secrets set HOOK_SECRET=generated_secret_here
```

## 🧪 **Testare**

### **1. Test SMTP:**
- Mergi la **Authentication → Email**
- Apasă **Send test email**

### **2. Test end-to-end:**
1. Creează user nou în aplicație
2. Verifică emailul de confirmare
3. Apasă link-ul de confirmare
4. Verifică în Brevo → Contacts că userul a fost adăugat

## 🔍 **Troubleshooting**

### **Verifică logs:**
```bash
supabase functions logs --function brevo-upsert-contact
```

### **Testează funcția manual:**
```bash
curl -X POST https://wphitbnrfcyzehjbpztd.functions.supabase.co/brevo-upsert-contact \
  -H "Content-Type: application/json" \
  -H "x-hook-secret: your_hook_secret" \
  -d '{"email":"test@example.com","firstName":"Test","lastName":"User"}'
```

## ✅ **Checklist**

- [ ] SMTP configurat în Supabase Dashboard
- [ ] Email template personalizat
- [ ] Edge Function deployată
- [ ] Secretele Brevo setate
- [ ] Migrația aplicată
- [ ] Test SMTP funcțional
- [ ] Test end-to-end funcțional
