#!/bin/bash

# Cleanup script for Docker Compose Microservices Exercise
# This script safely cleans up the system after testing

set -e  # Exit on any error

echo "=== Docker Compose Microservices Exercise Cleanup ==="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if docker and docker-compose are available
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

# Step 1: Stop and remove containers
echo "1. Stopping and removing containers..."
if docker-compose ps -q | grep -q .; then
    docker-compose down
    echo "✅ Services stopped and containers removed"
else
    echo "ℹ️  No running services to stop"
fi

echo ""

# Step 2: Clean up vStorage data
echo "2. Cleaning up vStorage data..."
if [ -d "./vstorage" ]; then
    if [ -f "./vstorage/vstorage" ]; then
        rm -f ./vstorage/vstorage
        echo "✅ Removed vStorage data file"
    else
        echo "ℹ️  No vStorage data file found"
    fi

    if [ -f "./vstorage/storage.log" ]; then
        rm -f ./vstorage/storage.log
        echo "✅ Removed storage service log file"
    else
        echo "ℹ️  No storage log file found"
    fi

    # Keep vstorage directory (required for Docker bind mounts)
    echo "ℹ️  Keeping vstorage directory structure"
else
    echo "ℹ️  No vstorage directory found"
fi

echo ""

# Step 3: Optional Docker cleanup
echo "3. Optional Docker cleanup..."
read -p "Do you want to remove unused Docker resources? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing unused Docker resources..."

    # Remove unused containers
    if docker container ls -a -q | grep -q .; then
        docker container prune -f
        echo "✅ Removed unused containers"
    else
        echo "ℹ️  No unused containers to remove"
    fi

    # Remove unused images
    if docker image ls -q | grep -q .; then
        docker image prune -f
        echo "✅ Removed unused images"
    else
        echo "ℹ️  No unused images to remove"
    fi

    # Remove unused networks
    if docker network ls --format "table {{.Name}}" | grep -q bridge; then
        docker network prune -f
        echo "✅ Removed unused networks"
    fi

    # Remove unused volumes (including bind mount volumes)
    if docker volume ls -q | grep -q .; then
        docker volume prune -f
        echo "✅ Removed unused volumes"
    else
        echo "ℹ️  No unused volumes to remove"
    fi
else
    echo "ℹ️  Skipping optional Docker cleanup"
fi

echo ""
echo "=== Cleanup Complete ==="
echo "The system has been safely cleaned up."
echo "You can restart the system with: docker-compose up --build"
echo ""

# Final status check
echo "Final status:"
docker-compose ps
