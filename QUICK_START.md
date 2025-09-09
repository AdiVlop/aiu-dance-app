# 🚀 AIU Dance - Quick Start Guide

## ⚡ Get Running in 5 Minutes

### 1. 🗄️ Setup Supabase Database (CRITICAL)
```bash
# 1. Open Supabase Dashboard: https://supabase.com/dashboard
# 2. Go to your project: wphitbnrfcyzehjbpztd
# 3. Navigate to SQL Editor
# 4. Copy and paste the entire content of supabase_schema.sql
# 5. Click "Run" to create all tables and policies
```

### 2. 🏃‍♂️ Run the App Locally
```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run on web (recommended for testing)
flutter run -d chrome --target=lib/main.dart

# Or use the final version
flutter run -d chrome --target=lib/main_supabase_final.dart
```

### 3. 🌐 Deploy to AWS (Optional)
```bash
# Make deployment script executable
chmod +x aws_s3_deploy.sh

# Configure AWS CLI (if not already done)
aws configure

# Deploy to S3
./aws_s3_deploy.sh
```

## 🔑 Environment Variables Needed

### Supabase (Already configured)
- ✅ URL: `https://wphitbnrfcyzehjbpztd.supabase.co`
- ✅ Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### Stripe (For payments)
```bash
export STRIPE_SECRET_KEY="sk_test_..."
export STRIPE_WEBHOOK_SECRET="whsec_..."
```

### OpenAI (For AI Assistant)
```bash
export OPENAI_API_KEY="sk-..."
```

## 🧪 Test the App

### 1. Authentication
- [ ] Open app in browser
- [ ] Try to register a new account
- [ ] Login with credentials
- [ ] Verify dashboard loads

### 2. Core Features
- [ ] Navigate between screens
- [ ] View course list
- [ ] Check wallet balance
- [ ] Generate QR codes

### 3. Admin Functions
- [ ] Access admin dashboard
- [ ] View attendance reports
- [ ] Export PDF reports

## 🚨 Common Issues & Solutions

### Issue: "Tables not found" error
**Solution**: Run the SQL schema in Supabase Dashboard

### Issue: App won't compile
**Solution**: 
```bash
flutter clean
flutter pub get
flutter doctor
```

### Issue: Can't connect to Supabase
**Solution**: Check internet connection and verify API keys

### Issue: QR scanner not working
**Solution**: Use web version or check camera permissions

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Web | ✅ Ready | Tested and working |
| iOS | ⚠️ Needs setup | Requires Xcode configuration |
| Android | ⚠️ Needs setup | Requires Android Studio |

## 🎯 What's Working Right Now

- ✅ Complete Flutter application
- ✅ Supabase backend integration
- ✅ User authentication system
- ✅ Course management
- ✅ QR code generation
- ✅ Digital wallet
- ✅ Admin dashboard
- ✅ Multi-language support (RO/EN/ES)
- ✅ AI assistant integration
- ✅ AWS deployment scripts
- ✅ CI/CD configuration

## 🚀 Next Steps After Quick Start

1. **Test all features** thoroughly
2. **Set up Stripe** for payments
3. **Configure AWS** for production
4. **Set up monitoring** and analytics
5. **Deploy to production** environment

## 📞 Need Help?

- **Documentation**: Check `README_DEV.md`
- **Database Issues**: Verify `supabase_schema.sql` was run
- **Deployment**: Check `DEPLOYMENT_STATUS.md`
- **Contact**: adrian@payai.ro

---

**Status**: 🟢 Ready to Run
**Last Updated**: $(date)
**Version**: 1.0.0








