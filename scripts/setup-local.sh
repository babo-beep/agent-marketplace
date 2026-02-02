#!/bin/bash

# Agent Marketplace - Local Development Setup
# One-command deployment for complete local testing environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Agent Marketplace - Local Setup      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose is not installed."
    exit 1
fi

if ! command -v node &> /dev/null; then
    print_warning "Node.js not found, but will use Docker containers"
fi

print_success "Prerequisites check passed"
echo ""

# Clean up old containers if requested
if [ "$1" == "--clean" ]; then
    print_status "Cleaning up old containers..."
    docker-compose down -v
    print_success "Cleanup complete"
    echo ""
fi

# Start Docker services
print_status "Starting Docker services (MongoDB, Hardhat, Redis)..."
docker-compose up -d mongodb redis hardhat

# Wait for services to be healthy
print_status "Waiting for services to be ready..."
sleep 5

# Check MongoDB
print_status "Checking MongoDB..."
MONGO_READY=0
for i in {1..30}; do
    if docker exec marketplace-mongodb mongosh --eval "db.runCommand('ping')" --quiet > /dev/null 2>&1; then
        MONGO_READY=1
        break
    fi
    sleep 1
done

if [ $MONGO_READY -eq 0 ]; then
    print_error "MongoDB failed to start"
    exit 1
fi
print_success "MongoDB is ready"

# Check Hardhat node
print_status "Checking Hardhat node..."
HARDHAT_READY=0
for i in {1..30}; do
    if curl -s -X POST http://localhost:8545 \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' > /dev/null 2>&1; then
        HARDHAT_READY=1
        break
    fi
    sleep 1
done

if [ $HARDHAT_READY -eq 0 ]; then
    print_error "Hardhat node failed to start"
    print_warning "Check logs with: docker logs marketplace-hardhat"
    exit 1
fi
print_success "Hardhat node is ready"

# Check Redis
print_status "Checking Redis..."
if docker exec marketplace-redis redis-cli ping > /dev/null 2>&1; then
    print_success "Redis is ready"
else
    print_warning "Redis is not responding (optional service)"
fi

echo ""

# Deploy smart contracts
if [ -f "contracts/package.json" ]; then
    print_status "Deploying smart contracts to local Hardhat node..."
    
    # Check if deployment script exists
    if [ -f "contracts/scripts/deploy.js" ] || [ -f "contracts/scripts/deploy.ts" ]; then
        docker exec marketplace-hardhat npx hardhat run scripts/deploy.js --network localhost || \
        docker exec marketplace-hardhat npx hardhat run scripts/deploy.ts --network localhost || \
        print_warning "Contract deployment script not found or failed"
        
        # Save deployment addresses
        if [ -f "contracts/deployments/localhost.json" ]; then
            print_success "Contracts deployed successfully"
            cat contracts/deployments/localhost.json
        fi
    else
        print_warning "No deployment script found in contracts/scripts/"
    fi
else
    print_warning "Contract directory not set up yet - skipping deployment"
fi

echo ""

# Seed database with sample data
print_status "Seeding database with sample data..."
if [ -f "scripts/seed-data.sh" ]; then
    bash scripts/seed-data.sh
    print_success "Database seeded"
else
    print_warning "Seed script not found - creating sample data manually..."
    
    # Create sample agents directly in MongoDB
    docker exec marketplace-mongodb mongosh marketplace --eval '
    db.agents.insertMany([
        {
            name: "AgentAlice",
            address: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            owner: "alice@example.com",
            reputation: 100,
            transactionCount: 0,
            createdAt: new Date()
        },
        {
            name: "AgentBob",
            address: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            owner: "bob@example.com",
            reputation: 100,
            transactionCount: 0,
            createdAt: new Date()
        }
    ]);
    print("✅ Sample agents created");
    ' --quiet
fi

echo ""

# Start API server
print_status "Starting API server..."
if [ -f "api/package.json" ]; then
    docker-compose up -d api
    
    # Wait for API to be ready
    print_status "Waiting for API to start..."
    sleep 5
    
    API_READY=0
    for i in {1..30}; do
        if curl -s http://localhost:3000/health > /dev/null 2>&1; then
            API_READY=1
            break
        fi
        sleep 1
    done
    
    if [ $API_READY -eq 1 ]; then
        print_success "API server is running on http://localhost:3000"
    else
        print_warning "API server might not be ready yet. Check logs: docker logs marketplace-api"
    fi
else
    print_warning "API directory not set up yet - skipping API startup"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🚀 Local Environment Ready!           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

echo "Services:"
echo "  • MongoDB:     mongodb://admin:admin123@localhost:27017/marketplace"
echo "  • Hardhat:     http://localhost:8545 (Chain ID: 31337)"
echo "  • Redis:       redis://localhost:6379"
echo "  • API:         http://localhost:3000"
echo ""

echo "Default test accounts (Hardhat):"
echo "  • Account 0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (AgentAlice)"
echo "  • Account 1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (AgentBob)"
echo "  • Private keys available in Hardhat console"
echo ""

echo "Useful commands:"
echo "  • View logs:          docker-compose logs -f [service]"
echo "  • Stop all:           docker-compose down"
echo "  • Reset everything:   ./scripts/setup-local.sh --clean"
echo "  • Run tests:          npm test (in project root)"
echo "  • Seed more data:     ./scripts/seed-data.sh"
echo ""

print_success "Setup complete! Ready for E2E testing."
