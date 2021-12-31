#!/bin/bash
CONTAINER_NAME=$(docker ps -q -f name=integration-substrate-node);
docker stop $CONTAINER_NAME;
docker start $CONTAINER_NAME;
