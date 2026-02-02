# Troubleshooting Guide - Agent Marketplace

Common issues and solutions when running the Agent Marketplace locally.

---

## Table of Contents

1. [Docker Issues](#docker-issues)
2. [MongoDB Problems](#mongodb-problems)
3. [Hardhat Node Issues](#hardhat-node-issues)
4. [API Server Problems](#api-server-problems)
5. [Test Failures](#test-failures)
6. [Performance Issues](#performance-issues)
7. [Network & Port Conflicts](#network--port-conflicts)

---

## Docker Issues

### Problem: Docker daemon not running

**Symptom:**
```bash
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solution:**
1. Open Docker Desktop
2. Wait for Docker to fully start (whale icon in menu bar)
3. Verify: `docker ps`

---

### Problem: Container won't start

**Symptom:**
```bash
Error response from daemon: Conflict. The container name "/marketplace-mongodb" is already in use
```

**Solution:**
```bash
# Stop and remove old containers
docker-compose down

# Force remove if needed
docker rm -f marketplace-mongodb marketplace-hardhat marketplace-api marketplace-redis

# Restart
./scripts/setup-local.sh
```

---

### Problem: Containers use too much disk space

**Symptom:**
Slow performance, disk full warnings

**Solution:**
```bash
# Remove old containers and images
docker system prune -a

# Remove volumes (WARNING: deletes all data)
docker volume prune

# Check disk usage
docker system df
```

---

## MongoDB Problems

### Problem: MongoDB connection refused

**Symptom:**
```bash
MongoServerError: Authentication failed
Error: connect ECONNREFUSED 127.0.0.1:27017
```

**Solution:**
```bash
# Check if MongoDB is running
docker ps | grep mongodb

# Check MongoDB logs
docker logs marketplace-mongodb

# Restart MongoDB
docker-compose restart mongodb

# Test connection
docker exec marketplace-mongodb mongosh --eval "db.runCommand('ping')"
```

---

### Problem: MongoDB data corrupted

**Symptom:**
Tests fail with database errors, inconsistent data

**Solution:**
```bash
# Complete database reset
docker-compose down -v
./scripts/setup-local.sh --clean

# Re-seed data
./scripts/seed-data.sh
```

---

### Problem: Can't connect with MongoDB Compass

**Symptom:**
Connection timeout or authentication failure in Compass

**Solution:**
Use this connection string:
```
mongodb://admin:admin123@localhost:27017/marketplace?authSource=admin
```

Make sure MongoDB container is running: `docker ps | grep mongodb`

---

## Hardhat Node Issues

### Problem: Hardhat node not responding

**Symptom:**
```bash
Error: could not detect network (event="noNetwork", code=NETWORK_ERROR)
```

**Solution:**
```bash
# Check if Hardhat is running
docker ps | grep hardhat

# Check logs for errors
docker logs marketplace-hardhat

# Test JSON-RPC endpoint
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Restart Hardhat
docker-compose restart hardhat

# Wait for it to be ready (takes ~10 seconds)
sleep 10
```

---

### Problem: Contracts not deployed

**Symptom:**
Tests fail with "contract not found" or invalid address

**Solution:**
```bash
# Deploy contracts manually
docker exec marketplace-hardhat npx hardhat run scripts/deploy.js --network localhost

# Check deployment
cat contracts/deployments/localhost.json

# If no deployment script exists, check contracts/ directory setup
ls -la contracts/
```

---

### Problem: Account balance issues

**Symptom:**
Transaction fails with "insufficient funds"

**Solution:**
```bash
# Enter Hardhat console
docker exec -it marketplace-hardhat npx hardhat console --network localhost

# Check balance
await ethers.provider.getBalance("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")

# Should return: 10000000000000000000000n (10000 ETH)
```

Hardhat accounts are pre-funded with 10,000 ETH. If balance is low, restart Hardhat node.

---

## API Server Problems

### Problem: API server not starting

**Symptom:**
```bash
Cannot GET /health
Error: API server not responding
```

**Solution:**
```bash
# Check if API container is running
docker ps | grep api

# View API logs
docker logs marketplace-api -f

# Check for errors
docker logs marketplace-api --tail 50

# Restart API
docker-compose restart api

# Test health endpoint
curl http://localhost:3000/health
```

---

### Problem: API returns 500 errors

**Symptom:**
API endpoints return internal server errors

**Solution:**
```bash
# Check API logs for stack trace
docker logs marketplace-api --tail 100

# Common causes:
# 1. MongoDB not connected
docker logs marketplace-api | grep -i mongo

# 2. Contract address not configured
docker logs marketplace-api | grep -i contract

# 3. Environment variables missing
docker exec marketplace-api printenv | grep -E 'MONGODB_URI|RPC_URL'
```

---

### Problem: API can't connect to MongoDB

**Symptom:**
```bash
MongooseError: Operation `listings.find()` buffering timed out
```

**Solution:**
```bash
# Check MongoDB is reachable from API container
docker exec marketplace-api ping -c 3 mongodb

# Verify MongoDB is ready
docker exec marketplace-mongodb mongosh --eval "db.runCommand('ping')"

# Check connection string in API
docker exec marketplace-api printenv | grep MONGODB_URI

# Restart both services
docker-compose restart mongodb api
```

---

## Test Failures

### Problem: Tests timeout

**Symptom:**
```bash
Timeout - Async callback was not invoked within the 60000 ms timeout
```

**Solution:**
1. Increase timeout in `jest.config.js`:
```javascript
testTimeout: 120000  // 2 minutes
```

2. Check if services are running:
```bash
docker-compose ps
```

3. Check service logs:
```bash
docker-compose logs -f
```

---

### Problem: Tests fail with "Connection refused"

**Symptom:**
```bash
Error: connect ECONNREFUSED 127.0.0.1:3000
```

**Solution:**
```bash
# Verify all services are healthy
docker-compose ps

# Wait for services to fully start
sleep 15

# Check each service individually
curl http://localhost:3000/health  # API
curl -X POST http://localhost:8545 -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'  # Hardhat
docker exec marketplace-mongodb mongosh --eval "db.runCommand('ping')"  # MongoDB
```

---

### Problem: Tests pass locally but fail in CI

**Symptom:**
GitHub Actions or CI pipeline shows failures

**Solution:**
1. Add longer startup wait times in CI:
```yaml
- name: Wait for services
  run: sleep 30
```

2. Check CI logs for resource constraints (memory, CPU)

3. Verify Docker Compose works in CI environment

4. Use health checks in `docker-compose.yml` (already configured)

---

### Problem: Tests fail after data changes

**Symptom:**
Test expects certain data but database has different records

**Solution:**
```bash
# Reset database and re-seed
./scripts/setup-local.sh --clean

# Run tests
cd tests/e2e && npm test

# For quick resets during development
./scripts/seed-data.sh
```

---

## Performance Issues

### Problem: Tests run very slowly

**Symptom:**
Test suite takes >60 seconds

**Solution:**
1. **Check Docker resources:**
   - Docker Desktop → Settings → Resources
   - Increase CPU: 4+ cores
   - Increase Memory: 4GB+ RAM

2. **Reduce logging:**
```bash
# Run tests with less verbose output
npm test -- --silent
```

3. **Use faster storage:**
   - Ensure Docker isn't using network drives
   - Use SSD instead of HDD

4. **Prune unused Docker data:**
```bash
docker system prune -a
```

---

### Problem: API responses are slow

**Symptom:**
API endpoints take >2 seconds to respond

**Solution:**
1. **Check MongoDB indexes:**
```javascript
// Connect to MongoDB
docker exec -it marketplace-mongodb mongosh marketplace

// Check indexes
db.listings.getIndexes()

// Rebuild indexes if needed
db.listings.reIndex()
```

2. **Enable Redis caching:**
```bash
# Verify Redis is running
docker ps | grep redis

# Check Redis connectivity from API
docker exec marketplace-api redis-cli -h redis ping
```

3. **Monitor container resources:**
```bash
docker stats
```

---

## Network & Port Conflicts

### Problem: Port already in use

**Symptom:**
```bash
Error: bind: address already in use
```

**Solution:**
```bash
# Find what's using the port (example for 3000)
lsof -i :3000

# Kill the process
kill -9 [PID]

# Or use different ports in docker-compose.yml:
ports:
  - "3001:3000"  # Map to different host port
```

---

### Problem: Can't access services from host

**Symptom:**
`curl` commands work in container but not from host machine

**Solution:**
1. **Verify port mappings:**
```bash
docker-compose ps
```

2. **Check firewall:**
   - macOS: System Preferences → Security → Firewall
   - Ensure Docker is allowed

3. **Try 127.0.0.1 instead of localhost:**
```bash
curl http://127.0.0.1:3000/health
```

---

### Problem: Containers can't talk to each other

**Symptom:**
API can't connect to MongoDB or Hardhat

**Solution:**
```bash
# Check Docker network
docker network inspect agent-marketplace_default

# Verify container names
docker ps --format "table {{.Names}}\t{{.Networks}}"

# Test connectivity
docker exec marketplace-api ping -c 3 mongodb
docker exec marketplace-api ping -c 3 hardhat
```

---

## Advanced Debugging

### Enable Debug Logging

**API Server:**
```bash
# Set DEBUG environment variable
docker-compose exec api sh -c "export DEBUG=* && npm run dev"
```

**Hardhat:**
```bash
docker exec marketplace-hardhat npx hardhat node --verbose
```

---

### Inspect Container Internals

```bash
# Enter container shell
docker exec -it marketplace-api sh

# Check running processes
ps aux

# Check network connectivity
ping mongodb
nc -zv mongodb 27017

# Check environment variables
printenv | grep -E 'MONGO|RPC'

# Check file system
ls -la /app
```

---

### Check Docker Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api

# Last N lines
docker-compose logs --tail=50 hardhat

# Since specific time
docker-compose logs --since="2026-02-02T00:00:00"
```

---

## Emergency Reset

If nothing works, nuclear option:

```bash
# Stop everything
docker-compose down -v

# Remove all marketplace containers
docker rm -f $(docker ps -a | grep marketplace | awk '{print $1}')

# Remove all volumes
docker volume rm $(docker volume ls | grep marketplace | awk '{print $2}')

# Clean Docker system
docker system prune -a --volumes

# Start fresh
./scripts/setup-local.sh --clean
```

---

## Getting Help

If you're still stuck:

1. **Check logs thoroughly:**
   ```bash
   docker-compose logs > debug.log
   ```

2. **Gather system info:**
   ```bash
   docker version
   docker-compose version
   node --version
   npm --version
   ```

3. **Create issue with:**
   - Error messages (full stack trace)
   - Steps to reproduce
   - Docker logs
   - System information

4. **Useful debugging commands:**
   ```bash
   # Service status
   docker-compose ps
   
   # Resource usage
   docker stats --no-stream
   
   # Network info
   docker network ls
   docker network inspect agent-marketplace_default
   
   # Volume info
   docker volume ls | grep marketplace
   ```

---

## Common Error Messages

### "EADDRINUSE: address already in use"
→ Port conflict, see [Port Conflicts](#problem-port-already-in-use)

### "MongoServerError: Authentication failed"
→ Wrong credentials, see [MongoDB Connection](#problem-mongodb-connection-refused)

### "Error: could not detect network"
→ Hardhat not ready, see [Hardhat Not Responding](#problem-hardhat-node-not-responding)

### "Cannot find module"
→ Run `npm install` in relevant directory

### "Permission denied"
→ Check Docker permissions or run with sudo (not recommended)

### "Transaction reverted"
→ Smart contract issue, check Hardhat logs

---

## Preventive Measures

To avoid issues:

1. ✅ Always run `./scripts/setup-local.sh` before testing
2. ✅ Keep Docker Desktop updated
3. ✅ Allocate enough resources to Docker (4GB+ RAM)
4. ✅ Regularly clean Docker: `docker system prune`
5. ✅ Don't modify running containers (use volumes for persistence)
6. ✅ Check service health before running tests
7. ✅ Use `--clean` flag when switching branches

---

**Still having issues?** Open an issue with full error logs and steps to reproduce.
