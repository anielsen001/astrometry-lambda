#!/bin/sh
#
# this script should be run with sudo for docker

# Run dockerfile
docker build -f Dockerfile --tag lambda:latest .
# Copying the package locally
docker run --name lambda -itd lambda:latest
docker cp lambda:/tmp/package.zip package.zip
docker stop lambda
docker rm lambda
