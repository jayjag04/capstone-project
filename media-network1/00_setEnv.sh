#!/bin/bash

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
CRYPTO="cryptogen"
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