#!/bin/bash

# =====================================================
# AIU Dance - Brevo Integration Setup Script
# =====================================================
# Configurează integrarea Supabase + Brevo pentru email confirmation

set -e  # Exit on any error

echo "🎭 AIU Dance - Brevo Integration Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI not found. Please install it first:${NC}"
    echo "npm install -g supabase"
    exit 1
fi

# Check if we're in a Supabase project
if [ ! -f "supabase/config.toml" ]; then
    echo -e "${RED}❌ Not in a Supabase project directory.${NC}"
    echo "Please run this script from your Supabase project root."
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Linking to Supabase project...${NC}"

# Link to the project
supabase link --project-ref wphitbnrfcyzehjbpztd

echo -e "${BLUE}📋 Step 2: Setting up Brevo secrets...${NC}"

# Generate a secure hook secret
HOOK_SECRET=$(openssl rand -hex 24)
echo -e "${YELLOW}🔑 Generated HOOK_SECRET: $HOOK_SECRET${NC}"

# Set the secrets (you need to replace these with your actual values)
echo -e "${YELLOW}⚠️  Please set your actual Brevo credentials:${NC}"
echo ""
echo "Run these commands with your actual values:"
echo ""
echo -e "${BLUE}supabase secrets set BREVO_API_KEY=your_brevo_api_key_here${NC}"
echo -e "${BLUE}supabase secrets set BREVO_LIST_ID=your_brevo_list_id_here${NC}"
echo -e "${BLUE}supabase secrets set HOOK_SECRET=$HOOK_SECRET${NC}"
echo ""

# Update the migration file with the correct hook secret
sed -i.bak "s/aiu_dance_brevo_hook_secret_2025/$HOOK_SECRET/g" supabase/migrations/20250110_add_brevo_trigger.sql
rm supabase/migrations/20250110_add_brevo_trigger.sql.bak

echo -e "${GREEN}✅ Updated migration file with generated HOOK_SECRET${NC}"

echo -e "${BLUE}📋 Step 3: Deploying Edge Function...${NC}"

# Deploy the Edge Function
supabase functions deploy brevo-upsert-contact

echo -e "${BLUE}📋 Step 4: Applying database migration...${NC}"

# Apply the migration
supabase db push

echo -e "${GREEN}🎉 Brevo integration setup completed!${NC}"
echo ""
echo -e "${BLUE}📊 Next steps:${NC}"
echo "1. Set your actual Brevo credentials using the commands above"
echo "2. Configure SMTP in Supabase Dashboard:"
echo "   - Host: smtp-relay.brevo.com"
echo "   - Port: 587 (STARTTLS)"
echo "   - Username: your_brevo_email"
echo "   - Password: your_brevo_smtp_key"
echo "   - From name: AIU Dance"
echo "   - From email: noreply@appauidance.com"
echo "3. Test email confirmation flow"
echo "4. Verify contacts appear in Brevo"
echo ""
echo -e "${YELLOW}💡 Useful commands:${NC}"
echo "• Check function logs: supabase functions logs --function brevo-upsert-contact"
echo "• Test function: curl -X POST https://wphitbnrfcyzehjbpztd.functions.supabase.co/brevo-upsert-contact"
echo "• Check secrets: supabase secrets list"
