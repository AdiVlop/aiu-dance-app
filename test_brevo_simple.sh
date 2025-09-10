#!/bin/bash

# =====================================================
# AIU Dance - Simple Brevo Function Test
# =====================================================

echo "🎭 AIU Dance - Testing Brevo Edge Function"
echo "=========================================="

# Configuration
FUNCTION_URL="https://wphitbnrfcyzehjbpztd.functions.supabase.co/brevo-upsert-contact"
HOOK_SECRET="4486c721d94bdaecbedfec2fc5cb76acc676255a28b001a5"

echo "📋 Testing Edge Function..."
echo "URL: $FUNCTION_URL"
echo ""

# Test payload
TEST_PAYLOAD='{
  "email": "test@aiudance.com",
  "firstName": "Test",
  "lastName": "User"
}'

echo "📤 Sending test request..."
echo "Payload: $TEST_PAYLOAD"
echo ""

# Send test request
echo "🚀 Executing curl command..."
curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -H "x-hook-secret: $HOOK_SECRET" \
  -H "Authorization: Bearer $HOOK_SECRET" \
  -d "$TEST_PAYLOAD" \
  -w "\n\nHTTP Status: %{http_code}\n"

echo ""
echo "✅ Test completed!"
echo ""
echo "💡 If you see HTTP Status: 200, the function is working correctly."
echo "💡 If you see HTTP Status: 500, check the Brevo API key in secrets."
