#!/bin/bash

# =====================================================
# AIU Dance - Test Brevo Function with Supabase Auth
# =====================================================

echo "🎭 AIU Dance - Testing Brevo Function with Auth"
echo "=============================================="

# Configuration
FUNCTION_URL="https://wphitbnrfcyzehjbpztd.functions.supabase.co/brevo-upsert-contact"
HOOK_SECRET="4486c721d94bdaecbedfec2fc5cb76acc676255a28b001a5"

# Get Supabase anon key from config
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwaGl0Ym5yZmN5emVoamJwenRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4MDYwMDMsImV4cCI6MjA3MjM4MjAwM30.-gsmVMcjVIlXRewVxXI2pDOQuXmI6__3m1VnCdU6HrA"

echo "📋 Testing Edge Function with Supabase Auth..."
echo "URL: $FUNCTION_URL"
echo ""

# Test payload
TEST_PAYLOAD='{
  "email": "test@aiudance.com",
  "firstName": "Test",
  "lastName": "User"
}'

echo "📤 Sending test request with Supabase auth..."
echo "Payload: $TEST_PAYLOAD"
echo ""

# Send test request with Supabase auth
echo "🚀 Executing curl command..."
curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -H "x-hook-secret: $HOOK_SECRET" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -d "$TEST_PAYLOAD" \
  -w "\n\nHTTP Status: %{http_code}\n"

echo ""
echo "✅ Test completed!"
echo ""
echo "💡 If you see HTTP Status: 200, the function is working correctly."
echo "💡 If you see HTTP Status: 500, check the Brevo API key in secrets."
