#!/bin/bash

source ./00_setEnv.sh


function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
   CONTAINER_IDS=$(docker ps -aq)
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

function networkDown() {
  # stop buyer2 containers also in addition to artist and buyer, in case we were running sample to add buyer2
  docker-compose \
    -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA \
    -f docker/docker-compose-buyer2.yaml -f docker/docker-compose-couch-buyer2.yaml -f docker/docker-compose-ca-buyer2.yaml \
    down --volumes --remove-orphans
  
    # Bring down the network, deleting the volumes
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove orderer block and other channel configuration transactions and certs
    sudo rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations
    ## remove fabric ca artifacts
    sudo rm -rf organizations/fabric-ca/artist/msp organizations/fabric-ca/artist/tls-cert.pem organizations/fabric-ca/artist/ca-cert.pem organizations/fabric-ca/artist/IssuerPublicKey organizations/fabric-ca/artist/IssuerRevocationPublicKey organizations/fabric-ca/artist/fabric-ca-server.db
    sudo rm -rf organizations/fabric-ca/buyer/msp organizations/fabric-ca/buyer/tls-cert.pem organizations/fabric-ca/buyer/ca-cert.pem organizations/fabric-ca/buyer/IssuerPublicKey organizations/fabric-ca/buyer/IssuerRevocationPublicKey organizations/fabric-ca/buyer/fabric-ca-server.db
    sudo rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db
    sudo rm -rf organizations/fabric-ca/buyer2/msp organizations/fabric-ca/buyer2/tls-cert.pem organizations/fabric-ca/buyer2/ca-cert.pem organizations/fabric-ca/buyer2/IssuerPublicKey organizations/fabric-ca/buyer2/IssuerRevocationPublicKey organizations/fabric-ca/buyer2/fabric-ca-server.db

    # remove channel and script artifacts
    sudo rm -rf channel-artifacts log.txt log.txt1 ${CC_NAME}.tar.gz ${CC_NAME} ${CC_NAME2}.tar.gz
}

networkDown

networkDown