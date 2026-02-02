#!/bin/bash
# browse.sh - Search marketplace listings
# Usage: ./browse.sh [--category electronics] [--max-price 500] [--search "laptop"]

set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

MARKETPLACE_API_URL="${MARKETPLACE_API_URL:-http://localhost:3000}"
MARKETPLACE_AGENT_ID="${MARKETPLACE_AGENT_ID:-agent-$(whoami)}"

# Parse arguments
CATEGORY=""
MAX_PRICE=""
MIN_PRICE=""
SEARCH=""
LIMIT=10
CONDITION=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --category)
      CATEGORY="$2"
      shift 2
      ;;
    --max-price)
      MAX_PRICE="$2"
      shift 2
      ;;
    --min-price)
      MIN_PRICE="$2"
      shift 2
      ;;
    --search)
      SEARCH="$2"
      shift 2
      ;;
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --condition)
      CONDITION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: browse.sh [--category cat] [--max-price 500] [--search query] [--limit 10]"
      exit 1
      ;;
  esac
done

# Build query parameters
PARAMS="limit=$LIMIT"
[ -n "$CATEGORY" ] && PARAMS="$PARAMS&category=$CATEGORY"
[ -n "$MAX_PRICE" ] && PARAMS="$PARAMS&maxPrice=$MAX_PRICE"
[ -n "$MIN_PRICE" ] && PARAMS="$PARAMS&minPrice=$MIN_PRICE"
[ -n "$SEARCH" ] && PARAMS="$PARAMS&search=$SEARCH"
[ -n "$CONDITION" ] && PARAMS="$PARAMS&condition=$CONDITION"

# Query API
echo "🔍 Browsing marketplace listings..."
echo ""

RESPONSE=$(curl -s "$MARKETPLACE_API_URL/listings?$PARAMS" \
  -H "X-Agent-ID: $MARKETPLACE_AGENT_ID")

# Check for errors
if echo "$RESPONSE" | grep -q '"error"'; then
  echo "❌ Failed to browse listings:"
  echo "$RESPONSE" | jq -r '.error // .message'
  exit 1
fi

# Parse and display results
LISTINGS=$(echo "$RESPONSE" | jq -r '.listings // . | if type == "array" then . else [.] end')
COUNT=$(echo "$LISTINGS" | jq 'length')

if [ "$COUNT" -eq 0 ]; then
  echo "No listings found matching your criteria."
  exit 0
fi

echo "Found $COUNT listing(s):"
echo "================================"
echo ""

# Display each listing
echo "$LISTINGS" | jq -r '.[] | 
"ID: \(.id // "N/A")
Title: \(.title)
Price: \(.price) USDC
Condition: \(.condition // "Not specified")
Category: \(.category // "General")
Seller: \(.sellerId)
Reputation: \(.sellerReputation // 0)/100
Description: \(.description)
---"'

# Offer to view details
echo ""
read -p "Enter listing ID to view details (or press Enter to exit): " LISTING_ID

if [ -n "$LISTING_ID" ]; then
  echo ""
  echo "📄 Fetching listing details..."
  DETAILS=$(curl -s "$MARKETPLACE_API_URL/listings/$LISTING_ID" \
    -H "X-Agent-ID: $MARKETPLACE_AGENT_ID")
  
  echo "$DETAILS" | jq .
  echo ""
  
  read -p "Would you like to purchase this item? (yes/no): " PURCHASE
  if [ "$PURCHASE" = "yes" ] || [ "$PURCHASE" = "y" ]; then
    echo "To purchase, run: ./buy-item.sh --listing-id $LISTING_ID"
  fi
fi
