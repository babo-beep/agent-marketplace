#!/bin/bash
# list-item.sh - Create a marketplace listing
# Usage: ./list-item.sh [--title "Item"] [--price 100] [--description "..."]

set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

MARKETPLACE_API_URL="${MARKETPLACE_API_URL:-http://localhost:3000}"
MARKETPLACE_AGENT_ID="${MARKETPLACE_AGENT_ID:-agent-$(whoami)}"

# Parse arguments
TITLE=""
DESCRIPTION=""
PRICE=""
CONDITION=""
CATEGORY=""
OWNER_CONFIRMED=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --title)
      TITLE="$2"
      shift 2
      ;;
    --description)
      DESCRIPTION="$2"
      shift 2
      ;;
    --price)
      PRICE="$2"
      shift 2
      ;;
    --condition)
      CONDITION="$2"
      shift 2
      ;;
    --category)
      CATEGORY="$2"
      shift 2
      ;;
    --confirmed)
      OWNER_CONFIRMED=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Interactive mode if no arguments provided
if [ -z "$TITLE" ]; then
  echo "🏷️  List an Item on Agent Marketplace"
  echo "======================================"
  echo ""
  read -p "Item title: " TITLE
fi

if [ -z "$DESCRIPTION" ]; then
  read -p "Description: " DESCRIPTION
fi

if [ -z "$PRICE" ]; then
  read -p "Price (USDC): " PRICE
fi

if [ -z "$CONDITION" ]; then
  echo "Condition options: new, like-new, good, fair, poor"
  read -p "Condition: " CONDITION
fi

if [ -z "$CATEGORY" ]; then
  echo "Category options: electronics, clothing, furniture, books, other"
  read -p "Category: " CATEGORY
fi

# Owner confirmation
if [ "$OWNER_CONFIRMED" = false ]; then
  echo ""
  echo "📋 Listing Summary:"
  echo "  Title: $TITLE"
  echo "  Description: $DESCRIPTION"
  echo "  Price: $PRICE USDC"
  echo "  Condition: $CONDITION"
  echo "  Category: $CATEGORY"
  echo ""
  read -p "⚠️  Confirm listing? (yes/no): " CONFIRM
  
  if [ "$CONFIRM" != "yes" ] && [ "$CONFIRM" != "y" ]; then
    echo "❌ Listing cancelled"
    exit 0
  fi
fi

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "title": "$TITLE",
  "description": "$DESCRIPTION",
  "price": "$PRICE",
  "condition": "$CONDITION",
  "category": "$CATEGORY",
  "sellerId": "$MARKETPLACE_AGENT_ID",
  "agentId": "$MARKETPLACE_AGENT_ID",
  "confirmedByOwner": true
}
EOF
)

# Submit to API
echo ""
echo "📤 Submitting listing to marketplace..."

RESPONSE=$(curl -s -X POST "$MARKETPLACE_API_URL/listings" \
  -H "Content-Type: application/json" \
  -H "X-Agent-ID: $MARKETPLACE_AGENT_ID" \
  -d "$JSON_PAYLOAD")

# Check for errors
if echo "$RESPONSE" | grep -q '"error"'; then
  echo "❌ Failed to create listing:"
  echo "$RESPONSE" | jq -r '.error // .message'
  exit 1
fi

# Success
LISTING_ID=$(echo "$RESPONSE" | jq -r '.id // .listingId')
echo "✅ Listing created successfully!"
echo ""
echo "Listing ID: $LISTING_ID"
echo "View at: $MARKETPLACE_API_URL/listings/$LISTING_ID"
echo ""
echo "$RESPONSE" | jq .
