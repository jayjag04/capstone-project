#!/bin/bash

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp/tlscacerts/tlsca.mediacoin.com-cert.pem
export PEER0_ARTIST_CA=${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/ca.crt
export PEER0_BUYER_CA=${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls/ca.crt
# channel name defaults to "mychannel"
export CHANNEL_NAME="mediachannel"
# use this as the default docker-compose yaml definition
export COMPOSE_FILE_BASE=docker/docker-compose-test-net.yaml
# docker-compose.yaml file if you are using couchdb
export COMPOSE_FILE_COUCH=docker/docker-compose-couch.yaml
# certificate authorities compose file
export COMPOSE_FILE_CA=docker/docker-compose-ca.yaml 
# use golang as the default language for chaincode
export CC_SRC_LANGUAGE=golang
# Chaincode version
export VERSION=1
# default image tag
export IMAGETAG="latest"
# default database
DATABASE="leveldb"
# chaincode name
export CC_NAME="mediacoin"
export DELAY=3

function networkDown() {
    docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA down --volumes --remove-orphans
    docker rm -f $(docker ps -aq)
    docker rmi -f $(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')

    # remove orderer block and other channel configuration transactions and certs
    sudo rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations
    ## remove fabric ca artifacts
    sudo rm -rf organizations/fabric-ca/artist/msp organizations/fabric-ca/artist/tls-cert.pem organizations/fabric-ca/artist/ca-cert.pem organizations/fabric-ca/artist/IssuerPublicKey organizations/fabric-ca/artist/IssuerRevocationPublicKey organizations/fabric-ca/artist/fabric-ca-server.db
    sudo rm -rf organizations/fabric-ca/buyer/msp organizations/fabric-ca/buyer/tls-cert.pem organizations/fabric-ca/buyer/ca-cert.pem organizations/fabric-ca/buyer/IssuerPublicKey organizations/fabric-ca/buyer/IssuerRevocationPublicKey organizations/fabric-ca/buyer/fabric-ca-server.db
    sudo rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db
    
    # remove channel and script artifacts
    sudo rm -rf channel-artifacts log.txt log.txt1 ${CC_NAME}.tar.gz ${CC_NAME}
  
}
networkDown

function createArtist {
	echo "Enroll the CA admin"
	mkdir -p organizations/peerOrganizations/artist.mediacoin.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/artist.mediacoin.com/
  fabric-ca-client enroll \
      -u https://admin:adminpw@localhost:7054 \
      --caname ca-artist \
      --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
  
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


  echo "Register peer0"
  fabric-ca-client register --caname ca-artist --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
  
  echo "Register user" 
  fabric-ca-client register --caname ca-artist --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
   
  echo "Register the org admin"
  fabric-ca-client register --caname ca-artist --id.name artistadmin --id.secret artistadminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem

	mkdir -p organizations/peerOrganizations/artist.mediacoin.com/peers
  mkdir -p organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com

  echo "## Generate the peer0 msp"
    echo 
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-artist -M ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/msp --csr.hosts peer0.artist.mediacoin.com --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/msp/config.yaml

  echo "## Generate the peer0-tls certificates"
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-artist -M ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls --enrollment.profile tls --csr.hosts peer0.artist.mediacoin.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem

  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/signcerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/keystore/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/server.key

  mkdir ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/tlsca
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/tlsca/tlsca.artist.mediacoin.com-cert.pem

  mkdir ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/ca
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/msp/cacerts/* ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/ca/ca.artist.mediacoin.com-cert.pem
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/ca/ca.artist.mediacoin.com-cert.pem /home/ubuntu/wallet

  mkdir -p organizations/peerOrganizations/artist.mediacoin.com/users
  mkdir -p organizations/peerOrganizations/artist.mediacoin.com/users/User1@artist.mediacoin.com
  echo "## Generate the user msp"
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 \
      --caname ca-artist \
      -M ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/User1@artist.mediacoin.com/msp \
      --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    
  mkdir -p organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com

  echo
  echo "## Generate the org admin msp"

  fabric-ca-client enroll \
      -u https://artistadmin:artistadminpw@localhost:7054 \
      --caname ca-artist \
      -M ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com/msp \
      --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem 
  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com/msp/config.yaml
}

function createBuyer {
  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/

  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-buyer --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem

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

  echo
	echo "Register peer0"
  echo
  
	fabric-ca-client register --caname ca-buyer --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  

  echo
  echo "Register user"
  echo
  
  fabric-ca-client register --caname ca-buyer --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  

  echo
  echo "Register the org admin"
  echo
  
  fabric-ca-client register --caname ca-buyer --id.name buyeradmin --id.secret buyeradminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  

	mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/peers
  mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com

  echo
  echo "## Generate the peer0 msp"
  echo
  
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/msp --csr.hosts peer0.buyer.mediacoin.com --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  
  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/tls --enrollment.profile tls --csr.hosts peer0.buyer.mediacoin.com --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  

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

  echo
  echo "## Generate the user msp"
  echo
  
	fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/User1@buyer.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  

  mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com

  echo
  echo "## Generate the org admin msp"
  echo
  
	fabric-ca-client enroll -u https://buyeradmin:buyeradminpw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  

  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com/msp/config.yaml

}

function createOrderer {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/ordererOrganizations/mediacoin.com

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/mediacoin.com
  
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  

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
  
	fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
    

  echo
  echo "Register the orderer admin"
  echo
  
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem

	mkdir -p organizations/ordererOrganizations/mediacoin.com/orderers
  mkdir -p organizations/ordererOrganizations/mediacoin.com/orderers/mediacoin.com

  mkdir -p organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com

  echo
  echo "## Generate the orderer msp"
  echo
  
	fabric-ca-client enroll \
      -u https://orderer:ordererpw@localhost:9054 \
      --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp \
      --csr.hosts orderer.mediacoin.com --csr.hosts localhost \
      --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem

  cp ${PWD}/organizations/ordererOrganizations/mediacoin.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  
  fabric-ca-client enroll \
      -u https://orderer:ordererpw@localhost:9054 \
      --caname ca-orderer \
      -M ${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/tls \
      --enrollment.profile tls \
      --csr.hosts orderer.mediacoin.com \
      --csr.hosts localhost \
      --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem 

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
  
	fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/mediacoin.com/users/Admin@mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  

  cp ${PWD}/organizations/ordererOrganizations/mediacoin.com/msp/config.yaml ${PWD}/organizations/ordererOrganizations/mediacoin.com/users/Admin@mediacoin.com/msp/config.yaml
}

echo ">>>>>>>>>>>>>>> Deleting the old folders (organizations/peerOrganizations) <<<<<<<<<<<<<<<"
if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
fi

IMAGE_TAG=$IMAGETAG 
docker-compose -f $COMPOSE_FILE_CA up -d 2>&1
sleep 10

echo "############ Create Artist Identities #####################" 
createArtist

echo "############ Create Buyer Identities ######################" 
createBuyer

echo "############ Create Orderer Org Identities ###############" 
createOrderer

echo "############ Created Orderer/Artist/Buyer Orgs Identities ###############" 

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
echo "#########  Generating Orderer Genesis block ##############"

# Note: For some unknown reason (at least for now) the block file can't be
# named orderer.genesis.block or the orderer will fail to launch!
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block 
echo "#########  Starting the network with couchdb ##############"

COMPOSE_FILES="${COMPOSE_FILES} -f ${COMPOSE_FILE_COUCH}"
IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1
docker ps -a
echo
echo "#########  Started the network with couchdb ##############"
echo 
echo "Creating the channel-artifacts folder"
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
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi
}

createChannelTx() {
	configtxgen -profile TwoOrgsChannel \
    -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx \
    -channelID $CHANNEL_NAME
}

createAncorPeerTx() {
	for orgmsp in ArtistMSP BuyerMSP; do
	  echo "#######    Generating anchor peer update for ${orgmsp}  ##########"
	  configtxgen -profile TwoOrgsChannel \
      -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx \
      -channelID $CHANNEL_NAME \
      -asOrg ${orgmsp}
	  echo
	done
}

createChannel() {
	setGlobals 1
		sleep $DELAY		
		peer channel create \
        -o localhost:7050 \
        -c $CHANNEL_NAME \
        --ordererTLSHostnameOverride orderer.mediacoin.com \
        -f ./channel-artifacts/${CHANNEL_NAME}.tx \
        --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
        --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA 
	echo
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
}

joinChannel() {
  ORG=$1
  setGlobals $ORG
  peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block   
}

updateAnchorPeers() {
  ORG=$1
  setGlobals $ORG
  peer channel update \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.mediacoin.com \
    -c $CHANNEL_NAME \
    -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA  
  echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
  sleep $DELAY
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
joinChannel 1
echo "Join Buyer peers to the channel..."
joinChannel 2

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for artist..."
updateAnchorPeers 1
echo "Updating anchor peers for buyer..."
updateAnchorPeers 2

echo
echo "========= Channel successfully joined =========== "

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
  export CORE_PEER_LOCALMSPID="OrdererMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp/tlscacerts/tlsca.mediacoin.com-cert.pem
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/ordererOrganizations/mediacoin.com/users/Admin@mediacoin.com/msp
}

setGlobalsForPeer0Artist() {
    export CORE_PEER_LOCALMSPID="ArtistMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ARTIST_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}
 
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

if [ "$CC_SRC_LANGUAGE" = "go" -o "$CC_SRC_LANGUAGE" = "golang" ] ; then
	CC_RUNTIME_LANGUAGE=golang
	CC_SRC_PATH="chaincode/$CC_NAME/go/"

	echo Vendoring Go dependencies ...
	pushd chaincode/$CC_NAME/go
	GO111MODULE=on go mod vendor
	popd
	echo Finished vendoring Go dependencies

elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
	CC_SRC_PATH="../chaincode/$CC_NAME/javascript/"

else
	echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
	echo Supported chaincode languages are: go, java, javascript, and typescript
	exit 1
fi

packageChaincode() {
  ORG=$1
  setGlobals $ORG
  
  peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path ${CC_SRC_PATH} \
    --lang ${CC_RUNTIME_LANGUAGE} \
    --label ${CC_NAME}_${VERSION}  
  echo "===================== Chaincode is packaged on peer0.org${ORG} ===================== "
  echo
}

# installChaincode PEER ORG
installChaincode() {
  ORG=$1
  setGlobals $ORG 
  peer lifecycle chaincode install $CC_NAME.tar.gz 
  echo "===================== Chaincode is installed on peer0.org${ORG} ===================== "
  echo
}

# queryInstalled PEER ORG
queryInstalled() {
  ORG=$1
  setGlobals $ORG
  
  peer lifecycle chaincode queryinstalled >&log.txt
  
  cat log.txt
	PACKAGE_ID=$(sed -n "/$CC_NAME_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
   
  echo PackageID is ${PACKAGE_ID}
  echo "===================== Query installed successful on peer0.org${ORG} on channel ===================== "
  echo
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {
  ORG=$1
  setGlobals $ORG
  
  peer lifecycle chaincode approveformyorg \
      -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.mediacoin.com \
      --tls $CORE_PEER_TLS_ENABLED \
      --cafile $ORDERER_CA \
      --channelID $CHANNEL_NAME \
      --name $CC_NAME \
      --version ${VERSION} \
      --init-required \
      --package-id ${PACKAGE_ID} \
      --sequence ${VERSION}  

  echo "===================== Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  echo "======= Checking the commit readiness of the chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'... ========= "
  peer lifecycle chaincode checkcommitreadiness \
      --channelID $CHANNEL_NAME \
      --name $CC_NAME \
      --version ${VERSION} \
      --sequence ${VERSION} \
      --output json \
      --init-required 
  echo "======= Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ========= "
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
   
  peer lifecycle chaincode commit \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.mediacoin.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA \
    --channelID $CHANNEL_NAME \
    --name $CC_NAME \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ARTIST_CA \
    --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_BUYER_CA \
    --version ${VERSION} \
    --sequence ${VERSION} \
    --init-required  
  echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
}

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG 
  echo "===================== Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== " 
  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME  
  echo "===================== Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
	
}

chaincodeInvokeInit() { 
   
  peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.mediacoin.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA \
    -C $CHANNEL_NAME \
    -n $CC_NAME \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ARTIST_CA \
    --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_BUYER_CA \
    --isInit \
    -c '{"function":"initLedger","Args":[]}'  
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
 
}

chaincodeQuery() {
  ORG=$1
  setGlobals $ORG
  echo "===================== Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["queryAllCars"]}'  
  echo "===================== Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
}

## at first we package the chaincode
packageChaincode 1

## Install chaincode on peer0.artist and peer0.buyer
echo "Installing chaincode on peer0.artist..."
installChaincode 1
echo "Install chaincode on peer0.buyer..."
installChaincode 2

## query whether the chaincode is installed
queryInstalled 1

## approve the definition for artist
approveForMyOrg 1

## check whether the chaincode definition is ready to be committed
## expect artist to have approved and buyer not to
checkCommitReadiness 1 "\"ArtistMSP\": true" "\"BuyerMSP\": false"
checkCommitReadiness 2 "\"ArtistMSP\": true" "\"BuyerMSP\": false"

## now approve also for buyer
approveForMyOrg 2

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 "\"ArtistMSP\": true" "\"BuyerMSP\": true"
checkCommitReadiness 2 "\"ArtistMSP\": true" "\"BuyerMSP\": true"

## now that we know for sure both orgs have approved, commit the definition
commitChaincodeDefinition 1 2

## query on both orgs to see that the definition committed successfully
queryCommitted 1
queryCommitted 2

## Invoke the chaincode
chaincodeInvokeInit 1 2

sleep 10

echo "Querying chaincode on peer0.artist..."
chaincodeQuery 1

chaincodeQuery() {
  setGlobalsForPeer0Artist
  echo "===================== Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["queryAllCars"]}' 
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["QueryMedium", "CONTRACT90"]}' 
  peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["QueryAllMediaContracts"]}' 
  echo
}

setGlobalsForPeer0Artist

 peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.mediacoin.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA \
    -C $CHANNEL_NAME \
    -n $CC_NAME \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ARTIST_CA \
    --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_BUYER_CA \
    -c '{"function":"CreateAlbumContract","Args":["CONTRACT90", "THINGS WILL IMPROVE", "1000", "OPEN"]}'  

  peer chaincode query \
      -C $CHANNEL_NAME \
      -n $CC_NAME \
      -c '{"Args":["QueryMedium", "CONTRACT91"]}' 

echo "Querying chaincode on peer0.artist..."
chaincodeQuery 1