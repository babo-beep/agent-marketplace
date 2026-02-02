#!/bin/bash
# check-reputation.sh - Check agent reputation score
# Usage: ./check-reputation.sh [--agent-id <id>]

set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

MARKETPLACE_API_URL="${MARKETPLACE_API_URL:-http://localhost:3000}"
MARKETPLACE_AGENT_ID="${MARKETPLACE_AGENT_ID:-agent-$(whoami)}"

# Parse arguments
TARGET_AGENT_ID="$MARKETPLACE_AGENT_ID"

while [[ $# -gt 0 ]]; do
  case $1 in
    --agent-id)
      TARGET_AGENT_ID="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: check-reputation.sh [--agent-id <id>]"
      exit 1
      ;;
  esac
done

# Query API
echo "🏆 Checking reputation for agent: $TARGET_AGENT_ID"
echo ""

RESPONSE=$(curl -s "$MARKETPLACE_API_URL/agents/$TARGET_AGENT_ID/reputation" \
  -H "X-Agent-ID: $MARKETPLACE_AGENT_ID")

# Check for errors
if echo "$RESPONSE" | grep -q '"error"'; then
  echo "❌ Failed to get reputation:"
  echo "$RESPONSE" | jq -r '.error // .message'
  exit 1
fi

# Parse reputation data
SCORE=$(echo "$RESPONSE" | jq -r '.score // 0')
TOTAL_TX=$(echo "$RESPONSE" | jq -r '.totalTransactions // 0')
SUCCESS_TX=$(echo "$RESPONSE" | jq -r '.successfulTransactions // 0')
DISPUTES=$(echo "$RESPONSE" | jq -r '.disputes // 0')
LAST_UPDATED=$(echo "$RESPONSE" | jq -r '.lastUpdated // "Never"')

# Calculate success rate
if [ "$TOTAL_TX" -gt 0 ]; then
  SUCCESS_RATE=$(echo "scale=1; $SUCCESS_TX * 100 / $TOTAL_TX" | bc)
else
  SUCCESS_RATE="N/A"
fi

# Display reputation
echo "Reputation Report"
echo "================="
echo "Score: $SCORE/100"
echo "Total Transactions: $TOTAL_TX"
echo "Successful: $SUCCESS_TX"
echo "Success Rate: $SUCCESS_RATE%"
echo "Disputes: $DISPUTES"
echo "Last Updated: $LAST_UPDATED"
echo ""

# Reputation assessment
if [ "$SCORE" -ge 80 ]; then
  echo "✅ Excellent reputation - highly trustworthy"
elif [ "$SCORE" -ge 60 ]; then
  echo "👍 Good reputation - generally reliable"
elif [ "$SCORE" -ge 40 ]; then
  echo "⚠️  Fair reputation - proceed with caution"
else
  echo "❌ Poor reputation - high risk"
fi

echo ""
echo "Full details:"
echo "$RESPONSE" | jq .
