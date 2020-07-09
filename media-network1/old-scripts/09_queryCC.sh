#!/bin/bash

source ./00_setEnv.sh

setGlobalsForPeer0Artist() {
    export CORE_PEER_LOCALMSPID="ArtistMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ARTIST_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

chaincodeQuery() {
   setGlobalsForPeer0Artist

  echo "===================== Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "    echo "Attempting to Query peer0.org${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    # peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["queryAllCars"]}'
     
    peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["QueryMedium", "CONTRACT90"]}' 
    peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["QueryAllMediaContracts"]}' 
    set +x
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
    -c '{"function":"CreateAlbumContract","Args":["CONTRACT90", "THINGS WILL IMPROVE", "1000", "OPEN"]}' >&log.txt

cat log.txt

 peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.mediacoin.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA \
    -C $CHANNEL_NAME \
    -n $CC_NAME \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ARTIST_CA \
    --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_BUYER_CA \
    -c '{"function":"CreateAlbumContract","Args":["CONTRACT91", "World is different!", "2000", "OPEN"]}' >&log.txt

cat log.txt

peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["QueryMedium", "CONTRACT91"]}' 

# Query chaincode on peer0.artist
echo "Querying chaincode on peer0.artist..."
chaincodeQuery 1