#!/bin/bash

source ./00_setEnv.sh
echo
 echo "#########  Starting the network with couchdb ##############"
echo

COMPOSE_FILES="-f ${COMPOSE_FILE_BASE} -f ${COMPOSE_FILE_COUCH}"

IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES}  -f docker/docker-compose-couch-buyer2.yaml up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  fi
echo
  echo "#########  Started the network with couchdb ##############"
  echo