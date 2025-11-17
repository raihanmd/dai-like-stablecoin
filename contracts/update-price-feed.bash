#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Price Feed IDs
WETH_ID="0x9d4294bbcd1174d6f2003ec365831e64cc31d9f6f15a2b85399db8d5000960f6"
BTC_ID="0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43"

echo -e "${YELLOW}📁 Creating directories...${NC}"
mkdir -p test/fixtures

echo -e "${YELLOW}🌐 Fetching Pyth price updates...${NC}"

# Fetch data
response=$(curl -s "https://hermes.pyth.network/v2/updates/price/latest?ids[]=${WETH_ID}&ids[]=${BTC_ID}")

if [ $? -ne 0 ] || [ -z "$response" ]; then
    echo -e "${RED}❌ Error: Failed to fetch data${NC}"
    exit 1
fi

# Save full response
echo "$response" > test/fixtures/full-response.json
echo -e "${GREEN}✅ Saved full response${NC}"

# Extract hex data using grep and sed (no jq needed)
hex_data=$(echo "$response" | grep -o '"data":\["[^"]*"' | sed 's/"data":\["\(.*\)"/\1/')

if [ -z "$hex_data" ]; then
    echo -e "${RED}❌ Error: Could not extract hex data${NC}"
    echo "Response saved to test/fixtures/full-response.json"
    exit 1
fi

# Remove 0x prefix if exists
hex_data=${hex_data#0x}

# Save with 0x prefix
echo "0x${hex_data}" > test/fixtures/pyth-price-update.hex

echo -e "${GREEN}✅ Success!${NC}"
echo -e "${GREEN}📁 Files saved:${NC}"
echo "   - test/fixtures/pyth-price-update.hex"
echo "   - test/fixtures/full-response.json"
echo ""
echo -e "${GREEN}📊 Hex data length: ${#hex_data} characters${NC}"

# Extract and show prices (basic parsing without jq)
echo ""
echo -e "${YELLOW}Price data saved. Check full-response.json for details.${NC}"

# Try to extract prices with basic grep
weth_price=$(echo "$response" | grep -o '"9d4294bbcd1174d6f2.*"price":"[0-9]*"' | grep -o '"price":"[0-9]*"' | grep -o '[0-9]*' | head -1)
btc_price=$(echo "$response" | grep -o '"e62df6c8b4a85fe1a67db44dc12de5db.*"price":"[0-9]*"' | grep -o '"price":"[0-9]*"' | grep -o '[0-9]*' | head -1)

if [ -n "$weth_price" ]; then
    weth_usd=$(awk "BEGIN {printf \"%.2f\", $weth_price / 100000000}")
    echo -e "${GREEN}   WETH: \$$weth_usd${NC}"
fi

if [ -n "$btc_price" ]; then
    btc_usd=$(awk "BEGIN {printf \"%.2f\", $btc_price / 100000000}")
    echo -e "${GREEN}   BTC: \$$btc_usd${NC}"
fi