#!/bin/bash

# Function to check if MongoDB is ready
check_mongodb_ready() {
    local max_attempts=30
    local attempt=1
    local wait_seconds=2

    echo "Waiting for MongoDB to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if docker compose exec mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
            echo "MongoDB is ready!"
            return 0
        fi
        echo "Attempt $attempt of $max_attempts: MongoDB not ready yet, waiting ${wait_seconds}s..."
        sleep $wait_seconds
        attempt=$((attempt + 1))
    done

    echo "MongoDB failed to become ready in time"
    return 1
}

# Function to start the Docker environment
start() {
    echo "Starting MongoDB container..."
    docker compose up -d
    
    # Wait for MongoDB to be ready
    if ! check_mongodb_ready; then
        echo "Failed to start MongoDB properly"
        exit 1
    fi
    
    echo "MongoDB is running on mongodb://localhost:27017"
}

# Function to stop the Docker environment
stop() {
    echo "Stopping MongoDB container..."
    docker compose down
    echo "MongoDB container stopped"
}

# Function to restart the Docker environment
restart() {
    stop
    start
}

# Function to show the status of the Docker environment
status() {
    echo "Checking MongoDB container status..."
    docker compose ps
}

# Function to show logs
logs() {
    docker compose logs -f
}

# Function to clean up (remove containers, networks, and volumes)
cleanup() {
    echo "Cleaning up Docker environment..."
    docker compose down -v
    echo "Cleanup complete"
}

# Main script logic
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    cleanup)
        cleanup
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|cleanup}"
        exit 1
        ;;
esac

exit 0 