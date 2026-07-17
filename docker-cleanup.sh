#!/bin/bash

# Safely remove all containers (running or stopped)
containers=$(docker ps -aq)
if [ -n "$containers" ]; then
  docker rm -f $containers
else
  echo "No containers to remove."
fi

# Safely remove all images
images=$(docker images -aq)
if [ -n "$images" ]; then
  docker rmi -f $images
else
  echo "No images to remove."
fi

# Safely remove unused networks
docker network prune -f

# Safely remove unused volumes
docker volume prune -f
