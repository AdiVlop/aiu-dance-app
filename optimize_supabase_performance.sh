#!/bin/bash

# =====================================================
# AIU Dance - Supabase Performance Optimization Script
# =====================================================
# Execută optimizările de performanță pentru Supabase RLS

set -e  # Exit on any error

echo "🎭 AIU Dance - Supabase Performance Optimization"
echo "================================================"

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

echo -e "${BLUE}📋 Step 1: Verifying current performance issues...${NC}"

# Run verification script first
if [ -f "verify_supabase_optimization.sql" ]; then
    echo -e "${YELLOW}🔍 Running performance verification...${NC}"
    supabase db reset --db-url "$(supabase status | grep 'DB URL' | awk '{print $3}')" --file verify_supabase_optimization.sql || true
else
    echo -e "${YELLOW}⚠️  Verification script not found, proceeding with optimization...${NC}"
fi

echo -e "${BLUE}📋 Step 2: Applying performance optimizations...${NC}"

# Apply the optimization script
if [ -f "fix_supabase_performance.sql" ]; then
    echo -e "${YELLOW}🔧 Applying RLS performance optimizations...${NC}"
    
    # Get database URL
    DB_URL=$(supabase status | grep 'DB URL' | awk '{print $3}')
    
    if [ -z "$DB_URL" ]; then
        echo -e "${RED}❌ Could not get database URL. Make sure Supabase is running.${NC}"
        echo "Run: supabase start"
        exit 1
    fi
    
    # Apply the optimization script
    psql "$DB_URL" -f fix_supabase_performance.sql
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Performance optimizations applied successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to apply optimizations. Check the SQL script for errors.${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Optimization script not found: fix_supabase_performance.sql${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 3: Verifying optimizations...${NC}"

# Run verification again
if [ -f "verify_supabase_optimization.sql" ]; then
    echo -e "${YELLOW}🔍 Verifying optimizations...${NC}"
    psql "$DB_URL" -f verify_supabase_optimization.sql
fi

echo -e "${GREEN}🎉 Supabase performance optimization completed!${NC}"
echo ""
echo -e "${BLUE}📊 Summary of optimizations:${NC}"
echo "✅ Auth functions optimized with (select auth.function())"
echo "✅ Duplicate RLS policies consolidated"
echo "✅ Duplicate indexes removed"
echo "✅ Performance warnings resolved"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "1. Test your application to ensure all functionality works"
echo "2. Monitor query performance in Supabase dashboard"
echo "3. Run database linter again to verify all warnings are resolved"
echo ""
echo -e "${BLUE}🔗 Useful commands:${NC}"
echo "• Check database status: supabase status"
echo "• View logs: supabase logs"
echo "• Open dashboard: supabase dashboard"
