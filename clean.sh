#!/bin/bash

yes | sudo docker container prune
yes | sudo docker image prune -a
yes | sudo docker-compose rm
echo "Done"