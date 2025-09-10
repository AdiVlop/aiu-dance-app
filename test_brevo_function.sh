#!/bin/bash

# =====================================================
# AIU Dance - Test Brevo Edge Function
# =====================================================

set -e

echo "🎭 AIU Dance - Testing Brevo Edge Function"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
FUNCTION_URL="https://wphitbnrfcyzehjbpztd.functions.supabase.co/brevo-upsert-contact"
HOOK_SECRET="4486c721d94bdaecbedfec2fc5cb76acc676255a28b001a5"

echo -e "${BLUE}📋 Testing Edge Function...${NC}"
echo "URL: $FUNCTION_URL"
echo ""

# Test payload
TEST_PAYLOAD='{
  "email": "test@aiudance.com",
  "firstName": "Test",
  "lastName": "User"
}'

echo -e "${YELLOW}📤 Sending test request...${NC}"
echo "Payload: $TEST_PAYLOAD"
echo ""

# Send test request
RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -H "x-hook-secret: $HOOK_SECRET" \
  -d "$TEST_PAYLOAD")

echo -e "${GREEN}📥 Response:${NC}"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
echo ""

# Check if successful
if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo -e "${GREEN}✅ Test successful!${NC}"
else
    echo -e "${YELLOW}⚠️  Test may have failed. Check the response above.${NC}"
fi
