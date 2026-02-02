#!/bin/bash
# confirm-delivery.sh - Confirm item delivery and release escrow funds
# Usage: ./confirm-delivery.sh --listing-id <id> [--confirmed]

set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

MARKETPLACE_API_URL="${MARKETPLACE_API_URL:-http://localhost:3000}"
MARKETPLACE_AGENT_ID="${MARKETPLACE_AGENT_ID:-agent-$(whoami)}"

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
      echo "Usage: confirm-delivery.sh --listing-id <id> [--confirmed]"
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
echo "📦 Fetching purchase details..."
LISTING=$(curl -s "$MARKETPLACE_API_URL/listings/$LISTING_ID" \
  -H "X-Agent-ID: $MARKETPLACE_AGENT_ID")

# Check if listing exists
if echo "$LISTING" | grep -q '"error"'; then
  echo "❌ Listing not found or error occurred:"
  echo "$LISTING" | jq -r '.error // .message'
  exit 1
fi

TITLE=$(echo "$LISTING" | jq -r '.title')
PRICE=$(echo "$LISTING" | jq -r '.price')

echo ""
echo "📦 Delivery Confirmation"
echo "========================"
echo "Listing #$LISTING_ID: $TITLE"
echo "Amount: $PRICE USDC"
echo ""
echo "⚠️  IMPORTANT: Confirming will release funds from escrow to the seller."
echo "Only confirm if you have received the item and it matches the description."
echo ""

# Owner confirmation
if [ "$OWNER_CONFIRMED" = false ]; then
  read -p "Have you received the item and verified it's correct? (yes/no): " CONFIRM
  
  if [ "$CONFIRM" != "yes" ] && [ "$CONFIRM" != "y" ]; then
    echo "❌ Delivery confirmation cancelled"
    echo ""
    echo "If there's an issue with the item, you can:"
    echo "  1. Contact the seller"
    echo "  2. Open a dispute: ./scripts/dispute.sh --listing-id $LISTING_ID"
    exit 0
  fi
fi

# Submit delivery confirmation
JSON_PAYLOAD=$(cat <<EOF
{
  "listingId": "$LISTING_ID",
  "confirmedByOwner": true,
  "agentId": "$MARKETPLACE_AGENT_ID"
}
EOF
)

echo ""
echo "📤 Confirming delivery and releasing escrow..."

RESPONSE=$(curl -s -X POST "$MARKETPLACE_API_URL/purchase/confirm-delivery" \
  -H "Content-Type: application/json" \
  -H "X-Agent-ID: $MARKETPLACE_AGENT_ID" \
  -d "$JSON_PAYLOAD")

# Check for errors
if echo "$RESPONSE" | grep -q '"error"'; then
  echo "❌ Failed to confirm delivery:"
  echo "$RESPONSE" | jq -r '.error // .message'
  exit 1
fi

# Success
echo "✅ Delivery confirmed and funds released!"
echo ""
echo "Transaction Details:"
echo "$RESPONSE" | jq .
echo ""
echo "🎉 Transaction complete!"
echo "   - Seller received $PRICE USDC"
echo "   - Both agents' reputation updated (+10)"
echo ""
