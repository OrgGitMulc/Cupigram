#!/usr/bin/env bash
# Check if there is instance running with the image name we are deploying
CURRENT_INSTANCE=${sudo docker ps -a -q --filter ancestor="$IMAGE_NAME" --format="{{.ID}}"}

# If an instance does exist stop the instance
if [ "$CURRENT_INSTANCE" ]
then
    echo "Stopping current instance"
    sudo docker rm $(sudo docker stop $CURRENT_INSTANCE)
fi

# Pull down the instance from dockerhub
sudo docker pull $IMAGE_NAME

# Check if a docker container exists with the name of $CONTAINER_NAME if it does remove the container
CONTAINER_EXISTS=$(sudo docker ps -a | grep $CONTAINER_NAME)
echo "Container Exists : " $CONTAINER_EXISTS
if [ "$CONTAINER_EXISTS" ]
then
    echo "Remove existing container"
	sudo docker stop $CONTAINER_NAME
    sudo docker rm $CONTAINER_NAME
fi

sudo docker run -p 3000:3000 -d --name $CONTAINER_NAME $IMAGE_NAME

#check that the container is actually up
sudo docker ps -a | grep $CONTAINER_NAME

# Clean up reduntant Docker
echo "Cleaning up Docker"
sudo docker system prune -f