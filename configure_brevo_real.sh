#!/bin/bash

# =====================================================
# AIU Dance - Configure Brevo Integration (Real Credentials)
# =====================================================

set -e

echo "🎭 AIU Dance - Configuring Brevo Integration"
echo "==========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Brevo credentials (provided by user)
BREVO_API_KEY="UArdmNSZHEGa6bLX"
BREVO_LIST_ID="0"  # Set to 0 if no specific list, or provide actual list ID
HOOK_SECRET="4486c721d94bdaecbedfec2fc5cb76acc676255a28b001a5"

echo -e "${BLUE}📋 Step 1: Linking to Supabase project...${NC}"
supabase link --project-ref wphitbnrfcyzehjbpztd

echo -e "${BLUE}📋 Step 2: Setting Brevo secrets...${NC}"
supabase secrets set BREVO_API_KEY="$BREVO_API_KEY"
supabase secrets set BREVO_LIST_ID="$BREVO_LIST_ID"
supabase secrets set HOOK_SECRET="$HOOK_SECRET"

echo -e "${GREEN}✅ Secrets configured successfully${NC}"

echo -e "${BLUE}📋 Step 3: Deploying Edge Function...${NC}"
supabase functions deploy brevo-upsert-contact

echo -e "${GREEN}✅ Edge Function deployed successfully${NC}"

echo -e "${BLUE}📋 Step 4: Applying database migration...${NC}"
supabase db push

echo -e "${GREEN}✅ Database migration applied successfully${NC}"

echo -e "${GREEN}🎉 Brevo integration configured successfully!${NC}"
echo ""
echo -e "${YELLOW}📧 SMTP Configuration for Supabase Dashboard:${NC}"
echo "Host: smtp-relay.brevo.com"
echo "Port: 587 (STARTTLS)"
echo "Username: 96b766001@smtp-brevo.com"
echo "Password: UArdmNSZHEGa6bLX"
echo "From name: AIU Dance"
echo "From email: noreply@appauidance.com"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Configure SMTP in Supabase Dashboard with the settings above"
echo "2. Test email confirmation flow"
echo "3. Verify contacts appear in Brevo"
echo ""
echo -e "${YELLOW}💡 Test commands:${NC}"
echo "• Test function: ./test_brevo_function.sh"
echo "• Check logs: supabase functions logs --function brevo-upsert-contact"
echo "• Check secrets: supabase secrets list"
