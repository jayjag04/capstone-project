#!/bin/bash

# before creating a channl we need to ensure the MSP for all orgs are present

function createBuyer2 {

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

  echo
	echo "Register peer0"
  echo 
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

  echo
  echo "## Generate the peer0-tls certificates"
  echo 
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

  echo
  echo "## Generate the user msp"
  echo
 
	fabric-ca-client enroll \
    -u https://user1:user1pw@localhost:11054 \
    --caname ca-buyer2 \
    -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/User1@buyer2.mediacoin.com/msp \
    --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem

  mkdir -p organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com

  echo
  echo "## Generate the org admin msp"
  echo 
	fabric-ca-client enroll -u https://buyer2admin:buyer2adminpw@localhost:11054 \
    --caname ca-buyer2 \
    -M ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com/msp \
    --tls.certfiles ${PWD}/organizations/fabric-ca/buyer2/tls-cert.pem
 

  cp ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com/msp/config.yaml
}

export PATH=${PWD}/../bin:${PWD}:$PATH
export CHANNEL_NAME=sec-channel
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp/tlscacerts/tlsca.mediacoin.com-cert.pem
# default image tag
export IMAGETAG="latest"
# default ca image tag
export CA_IMAGETAG="latest"
export COMPOSE_FILE_CA_BUYER2=docker/docker-compose-ca-buyer2.yaml
export FABRIC_CFG_PATH=./fabric-cfg
export CORE_PEER_TLS_ENABLED=true
IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA_BUYER2 up -d 2>&1

# start the network
IMAGE_TAG=$IMAGETAG docker-compose -f docker/docker-compose-buyer2.yaml -f docker/docker-compose-couch-buyer2.yaml up -d 2>&1

createBuyer2

exit 0

if [[ -e "./channel-artifacts/${CHANNEL_NAME}.tx" ]]
then
   rm ./channel-artifacts/${CHANNEL_NAME}.tx
fi

configtxgen -profile TwoOrgsOrdererGenesis1 -channelID system-channel -outputBlock ./system-genesis-block/genesis.block

configtxgen -profile TwoOrgsChannel1 \
		-outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx \
		-channelID $CHANNEL_NAME 2> out-err.txt

if [[ "${?}" -ne 0 ]]
then
    cat "<<<<<<<< (1) >>>>>>>>>"
      cat out-err.txt
      exit 1
fi
export PEER0_BUYER2_CA=${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/peers/peer0.buyer2.mediacoin.com/tls/ca.crt

export CORE_PEER_LOCALMSPID="Buyer2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER2_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com/msp
export CORE_PEER_ADDRESS=localhost:11051

peer channel create \
    -o localhost:7050 \
    -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.mediacoin.com \
    -f ./channel-artifacts/${CHANNEL_NAME}.tx \
    --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA  2> out-err.txt

if [ "${?}" -ne 0 ]
then
  echo "<<<<<<<< (2) >>>>>>>>>"
  cat out-err.txt
  exit 1
fi