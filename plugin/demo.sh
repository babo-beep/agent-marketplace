#!/bin/bash
# demo.sh - Demonstration of the Agent Marketplace Plugin
# This script demonstrates the complete flow: list → browse → buy → confirm

set -e

echo "🤖 Agent Marketplace Plugin - Live Demo"
echo "========================================"
echo ""
echo "This demo will:"
echo "1. List an item for sale"
echo "2. Browse the marketplace"
echo "3. Purchase an item (simulated)"
echo "4. Check reputation"
echo ""

# Check if API is running
MARKETPLACE_API_URL="${MARKETPLACE_API_URL:-http://localhost:3000}"
echo "Checking API connection at $MARKETPLACE_API_URL..."

if ! curl -s "$MARKETPLACE_API_URL/health" > /dev/null 2>&1; then
  echo "⚠️  Warning: API not responding at $MARKETPLACE_API_URL"
  echo "For a full demo, start the API first: cd ../api && npm start"
  echo ""
  echo "Continuing with local demonstration..."
  DEMO_MODE=true
else
  echo "✅ API is running!"
  DEMO_MODE=false
fi

echo ""
echo "=========================================="
echo "DEMO 1: Listing an Item"
echo "=========================================="
echo ""

if [ "$DEMO_MODE" = true ]; then
  echo "Agent: 'I want to sell my laptop'"
  echo "Owner: 'Great! Let me help you list it...'"
  echo ""
  echo "Simulating: ./scripts/list-item.sh"
  echo ""
  echo "Item details:"
  echo "  Title: MacBook Pro 2019"
  echo "  Price: 800 USDC"
  echo "  Condition: Excellent"
  echo "  Description: 15-inch, 16GB RAM, 512GB SSD"
  echo ""
  echo "✅ [SIMULATED] Listing created with ID: demo-listing-123"
else
  echo "Running: ./scripts/list-item.sh"
  ./scripts/list-item.sh \
    --title "Demo MacBook Pro 2019" \
    --description "15-inch, 16GB RAM, 512GB SSD, excellent condition" \
    --price 800 \
    --condition "excellent" \
    --category "electronics" \
    --confirmed
fi

echo ""
read -p "Press Enter to continue to browsing demo..."

echo ""
echo "=========================================="
echo "DEMO 2: Browsing the Marketplace"
echo "=========================================="
echo ""

if [ "$DEMO_MODE" = true ]; then
  echo "Agent: 'Let me search for laptops under $1000...'"
  echo ""
  echo "Simulating: ./scripts/browse.sh --category electronics --max-price 1000"
  echo ""
  echo "Found 3 listings:"
  echo "---"
  echo "ID: listing-001"
  echo "Title: MacBook Pro 2019"
  echo "Price: 800 USDC"
  echo "Condition: Excellent"
  echo "Seller Reputation: 92/100"
  echo "---"
  echo "ID: listing-002"
  echo "Title: Dell XPS 15"
  echo "Price: 650 USDC"
  echo "Condition: Good"
  echo "Seller Reputation: 88/100"
  echo "---"
  echo "ID: listing-003"
  echo "Title: ThinkPad X1"
  echo "Price: 500 USDC"
  echo "Condition: Fair"
  echo "Seller Reputation: 75/100"
else
  echo "Running: ./scripts/browse.sh --category electronics --max-price 1000"
  ./scripts/browse.sh --category electronics --max-price 1000 --limit 5
fi

echo ""
read -p "Press Enter to continue to purchase demo..."

echo ""
echo "=========================================="
echo "DEMO 3: Purchasing an Item"
echo "=========================================="
echo ""

echo "Agent: 'I found a great deal! MacBook Pro for 800 USDC from a seller"
echo "       with 92/100 reputation. The price is 20% below market average."
echo "       Would you like me to purchase it?'"
echo ""
echo "Owner: 'yes'"
echo ""

if [ "$DEMO_MODE" = true ]; then
  echo "Simulating: ./scripts/buy-item.sh --listing-id listing-001 --confirmed"
  echo ""
  echo "🛒 Purchase Confirmation"
  echo "========================"
  echo "Listing: MacBook Pro 2019"
  echo "Price: 800 USDC"
  echo "Seller Reputation: 92/100"
  echo ""
  echo "✅ [SIMULATED] Purchase request submitted!"
  echo "   - Funds sent to escrow: 800 USDC"
  echo "   - Seller notified"
  echo "   - Awaiting delivery"
  echo ""
  echo "Agent: 'I'll track the shipment and notify you when it arrives!'"
else
  echo "Note: This would purchase a real listing. Skipping for demo."
  echo "To test for real: ./scripts/buy-item.sh --listing-id <id> --confirmed"
fi

echo ""
read -p "Press Enter to continue to reputation check..."

echo ""
echo "=========================================="
echo "DEMO 4: Checking Reputation"
echo "=========================================="
echo ""

if [ "$DEMO_MODE" = true ]; then
  echo "Agent: 'Let me check your marketplace reputation...'"
  echo ""
  echo "Simulating: ./scripts/check-reputation.sh"
  echo ""
  echo "🏆 Reputation Report"
  echo "===================="
  echo "Score: 87/100"
  echo "Total Transactions: 12"
  echo "Successful: 12"
  echo "Success Rate: 100%"
  echo "Disputes: 0"
  echo ""
  echo "✅ Excellent reputation - highly trustworthy"
else
  echo "Running: ./scripts/check-reputation.sh"
  ./scripts/check-reputation.sh
fi

echo ""
echo "=========================================="
echo "DEMO 5: Delivery Confirmation (Simulated)"
echo "=========================================="
echo ""

echo "[3 days later...]"
echo ""
echo "Agent: '📦 Your package has arrived! Have you inspected the MacBook?"
echo "       Does it match the listing description?'"
echo ""
echo "Owner: 'Yes, it looks great!'"
echo ""

if [ "$DEMO_MODE" = true ]; then
  echo "Simulating: ./scripts/confirm-delivery.sh --listing-id listing-001 --confirmed"
  echo ""
  echo "✅ [SIMULATED] Delivery confirmed!"
  echo "   - Escrow funds released to seller: 800 USDC"
  echo "   - Your reputation: +10 (now 97/100)"
  echo "   - Seller reputation: +10 (now 102/100)"
  echo ""
  echo "Agent: 'Transaction complete! Enjoy your new MacBook! 💻'"
else
  echo "Note: This would release real escrow funds. Skipping for demo."
  echo "To test for real: ./scripts/confirm-delivery.sh --listing-id <id> --confirmed"
fi

echo ""
echo "=========================================="
echo "✅ Demo Complete!"
echo "=========================================="
echo ""
echo "Summary of what we demonstrated:"
echo "1. ✅ Listed an item (with owner confirmation)"
echo "2. ✅ Browsed marketplace listings"
echo "3. ✅ Purchased an item (with owner approval)"
echo "4. ✅ Checked reputation score"
echo "5. ✅ Confirmed delivery (released escrow)"
echo ""
echo "Key Safety Features:"
echo "- 🔒 Owner confirmation required for all purchases"
echo "- 💰 Funds held in escrow until delivery confirmed"
echo "- 🏆 Reputation system tracks trustworthiness"
echo "- ⚠️  Agents flag suspicious listings"
echo ""
echo "Next steps:"
echo "- Review plugin/SKILL.md for full documentation"
echo "- Check plugin/README.md for usage examples"
echo "- See plugin/INTEGRATION.md for agent integration"
echo "- Run ./scripts/browse.sh to explore live listings"
echo ""
echo "To connect to a real API:"
echo "  export MARKETPLACE_API_URL=https://your-api.com"
echo "  export MARKETPLACE_AGENT_ID=your-agent-id"
echo ""
echo "Happy trading! 🤝"
