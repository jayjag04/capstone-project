#!/bin/bash

source ./00_setEnv.sh

# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
# This function is called when you bring a network down
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
   CONTAINER_IDS=$(docker ps -aq)
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# This function is called when you bring the network down
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

function networkDown() {
  # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
  docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA down --volumes --remove-orphans
  # docker-compose -f $COMPOSE_FILE_COUCH_ORG3 -f $COMPOSE_FILE_ORG3 down --volumes --remove-orphans
  # Don't remove the generated artifacts -- note, the ledgers are always removed
  
    # Bring down the network, deleting the volumes
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove orderer block and other channel configuration transactions and certs
    sudo rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations
    ## remove fabric ca artifacts
    sudo rm -rf organizations/fabric-ca/org1/msp organizations/fabric-ca/org1/tls-cert.pem organizations/fabric-ca/org1/ca-cert.pem organizations/fabric-ca/org1/IssuerPublicKey organizations/fabric-ca/org1/IssuerRevocationPublicKey organizations/fabric-ca/org1/fabric-ca-server.db
    sudo rm -rf organizations/fabric-ca/org2/msp organizations/fabric-ca/org2/tls-cert.pem organizations/fabric-ca/org2/ca-cert.pem organizations/fabric-ca/org2/IssuerPublicKey organizations/fabric-ca/org2/IssuerRevocationPublicKey organizations/fabric-ca/org2/fabric-ca-server.db
    sudo rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db
    #sudo rm -rf addOrg3/fabric-ca/org3/msp addOrg3/fabric-ca/org3/tls-cert.pem addOrg3/fabric-ca/org3/ca-cert.pem addOrg3/fabric-ca/org3/IssuerPublicKey addOrg3/fabric-ca/org3/IssuerRevocationPublicKey addOrg3/fabric-ca/org3/fabric-ca-server.db

    # remove channel and script artifacts
    sudo rm -rf channel-artifacts log.txt log.txt1 ${CC_NAME}.tar.gz ${CC_NAME}
  
}

networkDown