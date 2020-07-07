#!/bin/bash

display()
{
  echo 
  echo $1
  echo
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx-new
export VERBOSE=false

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp/tlscacerts/tlsca.mediacoin.com-cert.pem
export PEER0_ARTIST_CA=${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/ca.crt
export PEER0_BUYER_CA=${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/ca.crt
export PEER0_BUYER2_CA=${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/ca.crt

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform, e.g., darwin-amd64 or linux-amd64
OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# Using crpto vs CA. default is cryptogen
CRYPTO="Certificate Authorities"
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
export MAX_RETRY=5
# default for delay between commands
export CLI_DELAY=3
# channel name defaults to "mychannel"
export CHANNEL_NAME="mediachannel"
export SECOND_CHANNEL_NAME="mediachannel2"
# use this as the default docker-compose yaml definition
export COMPOSE_FILE_BASE=docker/docker-compose-test-net.yaml
# docker-compose.yaml file if you are using couchdb
export COMPOSE_FILE_COUCH=docker/docker-compose-couch.yaml
# certificate authorities compose file
export COMPOSE_FILE_CA=docker/docker-compose-ca.yaml
# use this as the docker compose couch file for buyer2
export COMPOSE_FILE_COUCH_BUYER2=docker/docker-compose-couch-buyer2.yaml
# use this as the default docker-compose yaml definition for buyer2
export COMPOSE_FILE_BUYER2=docker/docker-compose-buyer2.yaml
# use golang as the default language for chaincode
export CC_SRC_LANGUAGE=golang
# Chaincode version
export VERSION=1
# default image tag
export IMAGETAG="latest"
# default database
DATABASE="couchdb"
# chaincode name
export CC_NAME="mediacoin"
export CC_NAME2="artistbuyer2"
export DELAY=3

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

display ">>>>>>>>>>>>>>> checking peer version <<<<<<<<<<<<<<<"

## Check if your have cloned the peer binaries and configuration files.
peer version > /dev/null 2>&1

if [[ $? -ne 0 || ! -d "../config" ]]; then
    echo "ERROR! Peer binary and configuration files not found.."
    echo
    exit 1
fi
echo "peer version: "
peer version
display ">>>>>>>>>>>>>>> checked peer version <<<<<<<<<<<<<<<"

echo ">>>>>>>>>>>>>>> checking binaries and docker images version <<<<<<<<<<<<<<<"
# use the fabric tools container to see if the samples and binaries match your
# docker images
LOCAL_VERSION=$(peer version | sed -ne 's/ Version: //p')
DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

echo "LOCAL_VERSION=$LOCAL_VERSION"
echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    echo "=================== WARNING ==================="
    echo "  Local fabric binaries and docker images are  "
    echo "  out of  sync. This may cause problems.       "
    echo "==============================================="
  fi

  for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
    echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match the versions supported by the test network."
      exit 1
    fi

    echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match the versions supported by the test network."
      exit 1
    fi
 done 
echo ">>>>>>>>>>>>>>> checked binaries and docker images version <<<<<<<<<<<<<<<"

function createArtist {

  display "Enroll the CA admin"
	mkdir -p organizations/peerOrganizations/artist.mediacoin.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/artist.mediacoin.com/
  
  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-artist --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
  set +x

  echo "Generating the ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/config.yaml file "
      echo 'NodeOUs:
      Enable: true
      ClientOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-artist.pem
        OrganizationalUnitIdentifier: client
      PeerOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-artist.pem
        OrganizationalUnitIdentifier: peer
      AdminOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-artist.pem
        OrganizationalUnitIdentifier: admin
      OrdererOUIdentifier:
        Certificate: cacerts/localhost-7054-ca-artist.pem
        OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/config.yaml

  display "Register peer0"
    set -x
    fabric-ca-client register --caname ca-artist --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    set +x

  display "Register user"
    set -x
    fabric-ca-client register --caname ca-artist --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    set +x

  display "Register the org admin"
  set -x
  fabric-ca-client register --caname ca-artist --id.name artistadmin --id.secret artistadminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/artist.mediacoin.com/peers
  mkdir -p organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com

  display "## Generate the peer0 msp"
    set -x
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-artist -M ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/msp --csr.hosts peer0.artist.mediacoin.com --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    set +x

  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/msp/config.yaml

  display "## Generate the peer0-tls certificates"
    set -x
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-artist -M ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls --enrollment.profile tls --csr.hosts peer0.artist.mediacoin.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    set +x


  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/tlsca/tlsca.artist.mediacoin.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/ca
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/ca/ca.artist.mediacoin.com-cert.pem
  echo "copying the ca.artist.mediacoin.com-cert.pem to /home/ubuntu/waller for the web application to use "
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/ca/ca.artist.mediacoin.com-cert.pem /home/ubuntu/wallet

  mkdir -p organizations/peerOrganizations/artist.mediacoin.com/users
  mkdir -p organizations/peerOrganizations/artist.mediacoin.com/users/User1@artist.mediacoin.com

  display "## Generate the user msp"
    set -x
    fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-artist -M ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/User1@artist.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    set +x

  mkdir -p organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com

  echo
  echo "## Generate the org admin msp"
    echo
    set -x
    fabric-ca-client enroll -u https://artistadmin:artistadminpw@localhost:7054 --caname ca-artist -M ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    set +x

  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com/msp/config.yaml

}

function createBuyer {

  display  "Enroll the CA admin"
	mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-buyer --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-buyer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-buyer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-buyer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-buyer.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/msp/config.yaml

  display "Register peer0"
  set -x
	fabric-ca-client register --caname ca-buyer --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-buyer --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-buyer --id.name buyeradmin2 --id.secret buyeradmin2pw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/peers
  mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com

 display "## Generate the peer0 msp"
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/msp --csr.hosts peer0.buyer.mediacoin.com --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/msp/config.yaml

 display "## Generate the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls --enrollment.profile tls --csr.hosts peer0.buyer.mediacoin.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/tlsca/tlsca.buyer.mediacoin.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/ca
  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/ca/ca.buyer.mediacoin.com-cert.pem

  mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/users
  mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/users/User1@buyer.mediacoin.com

display "## Generate the user msp"
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/User1@buyer.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com

display "## Generate the org admin msp"
  set -x
	fabric-ca-client enroll -u https://buyeradmin2:buyeradmin2pw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com/msp/config.yaml

}

function createBuyer2 {

display "Enroll the CA admin"
	mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:11054 --caname ca-buyer2\
   --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-buyer2.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-buyer2.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-buyer2.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-buyer2.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/config.yaml

display "Register peer0"
  set -x
	fabric-ca-client register --caname ca-buyer2 \
  --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
  set +x

  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname ca-buyer2 \
   --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
  set +x

display "Register the org admin"
  set -x
  fabric-ca-client register --caname ca-buyer2 --id.name buyeradmin2 --id.secret buyeradmin2pw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/peers
  mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com

display "## Generate the peer0 msp"
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:11054 --caname ca-buyer2 -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/msp --csr.hosts peer0.buyer2.mediacoin.com --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/msp/config.yaml

display "## Generate the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:11054 --caname ca-buyer2 -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls --enrollment.profile tls --csr.hosts peer0.buyer2.mediacoin.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/tlsca/tlsca.buyer2.mediacoin.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/ca
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/ca/ca.buyer2.mediacoin.com-cert.pem

  mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/users
  mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/users/User1@buyer2.mediacoin.com

display "## Generate the user msp"
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:11054 --caname ca-buyer2 -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/User1@buyer2.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
  set +x

  mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com

display "## Generate the org admin msp"
  set -x
	fabric-ca-client enroll -u https://buyeradmin2:buyeradmin2pw@localhost:11054 \
      --caname ca-buyer2 \
      -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com/msp/config.yaml

}

function createOrderer {

display "Enroll the CA admin"
	mkdir -p organizations/ordererOrganizations/mediacoin.com

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/mediacoin.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/ordererOrganizations/mediacoin.com/msp/config.yaml

  echo
	echo "Register orderer"
  echo
  set -x
	fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
    set +x

  echo
  echo "Register the orderer admin"
  echo
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

	mkdir -p organizations/ordererOrganizations/mediacoin.com/orderers
  mkdir -p organizations/ordererOrganizations/mediacoin.com/orderers/mediacoin.com

  mkdir -p organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com

  echo
  echo "## Generate the orderer msp"
  echo
  set -x
	fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp --csr.hosts orderer.mediacoin.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/mediacoin.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls --enrollment.profile tls --csr.hosts orderer.mediacoin.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls/keystore/* ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls/server.key

  mkdir ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp/tlscacerts/tlsca.mediacoin.com-cert.pem

  mkdir ${PWD}/organizations/ordererOrganizations/mediacoin.com/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/mediacoin.com/msp/tlscacerts/tlsca.mediacoin.com-cert.pem

  mkdir -p organizations/ordererOrganizations/mediacoin.com/users
  mkdir -p organizations/ordererOrganizations/mediacoin.com/users/Admin@mediacoin.com

  echo
  echo "## Generate the admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/mediacoin.com/users/Admin@mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  set +x

  cp ${PWD}/organizations/ordererOrganizations/mediacoin.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/mediacoin.com/users/Admin@mediacoin.com/msp/config.yaml
}

function createBuyer2old {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/
  fabric-ca-client enroll \
      -u https://admin:adminpw@localhost:11054 \
      --caname ca-buyer2 \
      --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
 
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-buyer2.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-buyer2.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-buyer2.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-buyer2.pem
    OrganizationalUnitIdentifier: orderer' > ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/config.yaml

  display "Register peer0"
	fabric-ca-client register \
        --caname ca-buyer2 \
        --id.name peer0 \
        --id.secret peer0pw \
        --id.type peer \
        --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
 
  echo
  echo "Register user"
  echo 
  fabric-ca-client register \
      --caname ca-buyer2 \
      --id.name user1 \
      --id.secret user1pw \
      --id.type client \
      --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem 

  echo
  echo "Register the org admin"
  echo 
  fabric-ca-client register \
      --caname ca-buyer2 \
      --id.name buyer2admin \
      --id.secret buyer2adminpw \
      --id.type admin \
      --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
 
	mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/peers
  mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com

  echo
  echo "## Generate the peer0 msp"
  echo 
	fabric-ca-client enroll \
    -u https://peer0:peer0pw@localhost:11054 \
    --caname ca-buyer2 \
    -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/msp \
    --csr.hosts peer0.buyer2.mediacoin.com \
    --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
 
  cp ${PWD}/../organizations/peerOrganizations/buyer2.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/msp/config.yaml

  display "## Generate the peer0-tls certificates"
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:11054 \
    --caname ca-buyer2 -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls \
    --enrollment.profile tls \
    --csr.hosts peer0.buyer2.mediacoin.com \
    --csr.hosts localhost \
    --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
 
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/tlsca/tlsca.buyer2.mediacoin.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/ca
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/ca/ca.buyer2.mediacoin.com-cert.pem

  mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/users
  mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/users/User1@buyer2.mediacoin.com

  display "## Generate the user msp"
	fabric-ca-client enroll \
    -u https://user1:user1pw@localhost:11054 \
    --caname ca-buyer2 \
    -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/User1@buyer2.mediacoin.com/msp \
    --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem

  mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com

display "## Generate the org admin msp"
	fabric-ca-client enroll -u https://buyer2admin:buyer2adminpw@localhost:11054 \
    --caname ca-buyer2 \
    -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com/msp \
    --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
 
  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com/msp/config.yaml
}

display "############ Deleting folders (org*s/*Organizations)       ##############"

if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
fi

display "############ Deleted folders (org*s/*Organizations)       ###############" 
 
display "############ Create crypto material using Fabric CAs      ###############" 
echo "Checking for Fabric CA client"
fabric-ca-client version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Fabric CA client not found locally"
    exit 0
fi
echo "fabric-ca-client: " $(fabric-ca-client version | sed -ne 's/ Version: //p')

IMAGE_TAG=$IMAGETAG 

docker-compose -f $COMPOSE_FILE_CA -f docker/docker-compose-ca-buyer2.yaml up -d 2>&1

sleep 20

echo "##########################################################"
echo "############ Create Artist Identities ####################"
echo "##########################################################"

createArtist

echo "##########################################################"
echo "############ Create Buyer Identities #####################"
echo "##########################################################"

createBuyer2

createBuyer

display "############ Creating Orderer Org Identities              ###############"

createOrderer

display "############ Created Orderer/Artist/Buyer Orgs Identities ###############"
display "############ Creating CCP Files                           ###############"
function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n        /g'
}

ORG=1
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/artist.mediacoin.com/tlsca/tlsca.artist.mediacoin.com-cert.pem
CAPEM=organizations/peerOrganizations/artist.mediacoin.com/ca/ca.artist.mediacoin.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/artist.mediacoin.com/connection-artist.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/artist.mediacoin.com/connection-artist.yaml

cp organizations/peerOrganizations/artist.mediacoin.com/connection-artist.json /home/ubuntu/wallet/
cp ${CAPEM} /home/ubuntu/wallet/

ORG=2
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/buyer.mediacoin.com/tlsca/tlsca.buyer.mediacoin.com-cert.pem
CAPEM=organizations/peerOrganizations/buyer.mediacoin.com/ca/ca.buyer.mediacoin.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/buyer.mediacoin.com/connection-buyer.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/buyer.mediacoin.com/connection-buyer.yaml

ORG=3
P0PORT=11051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/buyer2.mediacoin.com/tlsca/tlsca.buyer2.mediacoin.com-cert.pem
CAPEM=organizations/peerOrganizations/buyer2.mediacoin.com/ca/ca.buyer2.mediacoin.com-cert.pem

cp organizations/peerOrganizations/buyer2.mediacoin.com/connection-buyer2.json /home/ubuntu/wallet/
cp ${CAPEM} /home/ubuntu/wallet/

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/buyer2.mediacoin.com/connection-buyer2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/buyer2.mediacoin.com/connection-buyer2.yaml

display "############ Generating Orderer Genesis block             ###############" 
# Note: For some unknown reason (at least for now) the block file can't be
# named orderer.genesis.block or the orderer will fail to launch!
set -x
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
res=$?
set +x
if [ $res -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi
display "############ Generated Orderer Genesis block              ###############"

display "############ Starting the network with couchdb            ###############" 

COMPOSE_FILES="-f ${COMPOSE_FILE_BASE} -f ${COMPOSE_FILE_COUCH}"

IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES}  -f docker/docker-compose-couch-buyer2.yaml up -d 2>&1

docker ps -a

display "############ Creating the channel-artifacts folder        ###############" 
 
if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  echo "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="ArtistMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ARTIST_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="BuyerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="Buyer2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi
}

createChannelTx() {
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	configtxgen -profile TwoOrgsChannel1 -outputCreateChannelTx ./channel-artifacts/${SECOND_CHANNEL_NAME}.tx -channelID $SECOND_CHANNEL_NAME
}

createAncorPeerTx() {
	for orgmsp in ArtistMSP BuyerMSP; do 
	  display "############ Generating anchor peer update for ${orgmsp}  ###############"  
		configtxgen -profile TwoOrgsChannel \
			-outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx \
			-channelID $CHANNEL_NAME \
			-asOrg ${orgmsp}
		
	done
		for orgmsp in ArtistMSP Buyer2MSP; do
		  echo "#######    Generating anchor peer update for ${orgmsp}  ##########"
		 
		  configtxgen -profile TwoOrgsChannel1 \
        -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors2.tx \
        -channelID $SECOND_CHANNEL_NAME \
        -asOrg ${orgmsp} 
	done
}

createChannel() {
	setGlobals 1
 
	peer channel create \
			-o localhost:7050 \
			-c $CHANNEL_NAME \
			--ordererTLSHostnameOverride orderer.mediacoin.com \
			-f ./channel-artifacts/${CHANNEL_NAME}.tx \
			--outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
			--tls $CORE_PEER_TLS_ENABLED \
			--cafile $ORDERER_CA  
  display "===================== Channel '$CHANNEL_NAME' created ===================== "
	
  peer channel create \
			-o localhost:7050 \
			-c $SECOND_CHANNEL_NAME \
			--ordererTLSHostnameOverride orderer.mediacoin.com \
			-f ./channel-artifacts/${SECOND_CHANNEL_NAME}.tx \
			--outputBlock ./channel-artifacts/${SECOND_CHANNEL_NAME}.block \
			--tls $CORE_PEER_TLS_ENABLED \
			--cafile $ORDERER_CA  			
 
  display "===================== Channel '$SECOND_CHANNEL_NAME' created ===================== "
 
  
}

# queryCommitted ORG
joinChannel() {
  # Channel 1
    ORG=1
    setGlobals $ORG
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block 
    ORG=2
    setGlobals $ORG
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
  # Channel 2
    ORG=1
    setGlobals $ORG
    peer channel join -b ./channel-artifacts/$SECOND_CHANNEL_NAME.block 
    ORG=3
    setGlobals $ORG
    peer channel join -b ./channel-artifacts/$SECOND_CHANNEL_NAME.block
} 

updateAnchorPeers() {
  # Channel 1
    ORG=1
    setGlobals $ORG
	
    peer channel update \
      -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.mediacoin.com \
      -c $CHANNEL_NAME \
      -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx \
      --tls $CORE_PEER_TLS_ENABLED \
      --cafile $ORDERER_CA 

    
    ORG=2
    setGlobals $ORG
	
    peer channel update \
      -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.mediacoin.com \
      -c $CHANNEL_NAME \
      -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx \
      --tls $CORE_PEER_TLS_ENABLED \
      --cafile $ORDERER_CA 

  display "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "

  # Channel 2
    ORG=1
    setGlobals $ORG
	
	  peer channel update \
      -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.mediacoin.com \
      -c $SECOND_CHANNEL_NAME \
      -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors2.tx \
      --tls $CORE_PEER_TLS_ENABLED \
      --cafile $ORDERER_CA 

    setGlobals 3

    peer channel update \
      -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.mediacoin.com \
      -c $SECOND_CHANNEL_NAME \
      -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors2.tx \
      --tls $CORE_PEER_TLS_ENABLED \
      --cafile $ORDERER_CA  
    
  echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
  sleep $DELAY
  echo
 
}

## Create channeltx
echo "### Generating channel configuration transaction '${CHANNEL_NAME}.tx' ###"
createChannelTx

## Create anchorpeertx
echo "### Generating channel configuration transaction '${CHANNEL_NAME}.tx' ###"
createAncorPeerTx

## Create channel
echo "Creating channel "$CHANNEL_NAME
createChannel

## Join all the peers to the channel
echo "Join Artist peers to the channel..."
joinChannel 

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for artist..."
updateAnchorPeers 
 
display "========= Channel successfully joined =========== "