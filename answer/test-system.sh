#!/bin/bash

# Test script for Docker Compose Microservices Exercise
# This script tests the system according to the exercise requirements

echo "=== Docker Compose Microservices Exercise Test ==="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
if ! command_exists docker; then
    echo "❌ ERROR: Docker is not installed or not in PATH"
    echo "💡 On Linux, you may need to install Docker or add user to docker group:"
    echo "   sudo usermod -aG docker \$USER"
    exit 1
fi

if ! command_exists docker-compose; then
    echo "❌ ERROR: Docker Compose is not installed or not in PATH"
    exit 1
fi

# Test docker permissions (common issue on Linux)
if ! docker info >/dev/null 2>&1; then
    echo "❌ ERROR: Cannot connect to Docker daemon"
    echo "💡 On Linux, try one of these solutions:"
    echo "   1. Add user to docker group: sudo usermod -aG docker \$USER"
    echo "   2. Run with sudo: sudo $0"
    echo "   3. Start Docker service: sudo systemctl start docker"
    exit 1
fi

# Ensure vstorage directory exists
echo "1. Ensuring vstorage directory exists..."
mkdir -p ./vstorage
echo "✅ vstorage directory ready"

echo ""

# Start services
echo "2. Starting services..."
if ! docker-compose up -d; then
    echo "❌ Failed to start services"
    exit 1
fi

echo "Waiting for services to be ready..."
sleep 5

# Check if services are running
echo "3. Checking if services are running..."
docker-compose ps

echo ""
echo "4. Testing /status endpoint..."
echo "Making request to localhost:8199/status"
curl -s localhost:8199/status
echo ""
echo ""

echo "4. Testing /log endpoint..."
echo "Making request to localhost:8199/log"
curl -s localhost:8199/log
echo ""
echo ""

echo "5. Checking vStorage file content..."
echo "Content of ./vstorage/vstorage:"
cat ./vstorage/vstorage 2>/dev/null || echo "(file empty or doesn't exist)"
echo ""
echo ""

echo "6. Verifying data consistency..."
echo "Comparing vStorage file with /log endpoint output..."
VSTORAGE_CONTENT=$(cat ./vstorage/vstorage 2>/dev/null || echo "")
LOG_CONTENT=$(curl -s localhost:8199/log)

if [ "$VSTORAGE_CONTENT" = "$LOG_CONTENT" ]; then
    echo "✅ SUCCESS: vStorage and /log endpoint contain identical data"
else
    echo "❌ ERROR: vStorage and /log endpoint data differ"
    echo "vStorage content:"
    echo "$VSTORAGE_CONTENT"
    echo "Log endpoint content:"
    echo "$LOG_CONTENT"
fi

echo ""
echo "7. Testing system with multiple requests..."
echo "Making 3 additional /status requests to test persistence..."

for i in {1..3}; do
    echo "Request $i:"
    curl -s localhost:8199/status
    echo ""
    sleep 1
done

echo ""
echo "8. Final verification..."
echo "vStorage file now contains:"
cat ./vstorage/vstorage 2>/dev/null || echo "(file empty or doesn't exist)"
echo ""

echo "Log endpoint now contains:"
curl -s localhost:8199/log
echo ""

echo "=== Test Complete ==="
echo "Expected: Each /status request should add 2 lines to both storage solutions"
echo "Expected: vStorage file and /log endpoint should contain identical data"

echo ""
echo "9. Cleaning up test services..."
docker-compose down
