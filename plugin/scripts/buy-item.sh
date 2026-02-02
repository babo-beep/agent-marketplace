#!/bin/bash
# buy-item.sh - Purchase a marketplace listing
# Usage: ./buy-item.sh --listing-id <id> [--confirmed]

set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

MARKETPLACE_API_URL="${MARKETPLACE_API_URL:-http://localhost:3000}"
MARKETPLACE_AGENT_ID="${MARKETPLACE_AGENT_ID:-agent-$(whoami)}"
MARKETPLACE_WALLET_ADDRESS="${MARKETPLACE_WALLET_ADDRESS:-0x0000000000000000000000000000000000000000}"

# Parse arguments
LISTING_ID=""
OWNER_CONFIRMED=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --listing-id)
      LISTING_ID="$2"
      shift 2
      ;;
    --confirmed)
      OWNER_CONFIRMED=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: buy-item.sh --listing-id <id> [--confirmed]"
      exit 1
      ;;
  esac
done

# Validate listing ID
if [ -z "$LISTING_ID" ]; then
  read -p "Enter listing ID: " LISTING_ID
fi

if [ -z "$LISTING_ID" ]; then
  echo "❌ Listing ID is required"
  exit 1
fi

# Fetch listing details
echo "📄 Fetching listing details..."
LISTING=$(curl -s "$MARKETPLACE_API_URL/listings/$LISTING_ID" \
  -H "X-Agent-ID: $MARKETPLACE_AGENT_ID")

# Check if listing exists
if echo "$LISTING" | grep -q '"error"'; then
  echo "❌ Listing not found or error occurred:"
  echo "$LISTING" | jq -r '.error // .message'
  exit 1
fi

# Display listing details
TITLE=$(echo "$LISTING" | jq -r '.title')
PRICE=$(echo "$LISTING" | jq -r '.price')
DESCRIPTION=$(echo "$LISTING" | jq -r '.description')
CONDITION=$(echo "$LISTING" | jq -r '.condition // "Not specified"')
SELLER_ID=$(echo "$LISTING" | jq -r '.sellerId')
SELLER_REP=$(echo "$LISTING" | jq -r '.sellerReputation // 0')

echo ""
echo "🛒 Purchase Confirmation"
echo "========================"
echo "Listing: $TITLE"
echo "Price: $PRICE USDC"
echo "Condition: $CONDITION"
echo "Seller: $SELLER_ID"
echo "Seller Reputation: $SELLER_REP/100"
echo ""
echo "Description:"
echo "$DESCRIPTION"
echo ""
echo "⚠️  Funds will be held in escrow until delivery is confirmed."
echo ""

# Owner confirmation
if [ "$OWNER_CONFIRMED" = false ]; then
  read -p "Do you want to proceed with this purchase? (yes/no): " CONFIRM
  
  if [ "$CONFIRM" != "yes" ] && [ "$CONFIRM" != "y" ]; then
    echo "❌ Purchase cancelled"
    exit 0
  fi
fi

# Create purchase request
JSON_PAYLOAD=$(cat <<EOF
{
  "listingId": "$LISTING_ID",
  "buyerId": "$MARKETPLACE_WALLET_ADDRESS",
  "buyerAgentId": "$MARKETPLACE_AGENT_ID",
  "amount": "$PRICE",
  "confirmedByOwner": true
}
EOF
)

echo ""
echo "📤 Submitting purchase request..."

RESPONSE=$(curl -s -X POST "$MARKETPLACE_API_URL/purchase/request" \
  -H "Content-Type: application/json" \
  -H "X-Agent-ID: $MARKETPLACE_AGENT_ID" \
  -d "$JSON_PAYLOAD")

# Check for errors
if echo "$RESPONSE" | grep -q '"error"'; then
  echo "❌ Failed to create purchase request:"
  echo "$RESPONSE" | jq -r '.error // .message'
  exit 1
fi

# Success
echo "✅ Purchase request submitted successfully!"
echo ""
echo "Transaction Details:"
echo "$RESPONSE" | jq .
echo ""
echo "📦 Next steps:"
echo "  1. Seller will be notified"
echo "  2. Funds are held in escrow"
echo "  3. Wait for delivery"
echo "  4. Confirm delivery to release funds"
echo ""
echo "To confirm delivery later, run:"
echo "  ./scripts/confirm-delivery.sh --listing-id $LISTING_ID"
