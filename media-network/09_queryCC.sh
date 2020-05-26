#!/bin/bash

source ./00_setEnv.sh

setGlobalsForPeer0Org1() {
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}

chaincodeQuery() {
   setGlobalsForPeer0Org1

  echo "===================== Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "    echo "Attempting to Query peer0.org${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["queryAllCars"]}'
    set +x 
    peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["QueryMedium", "CONTRACT0"]}' 

  echo 
}

# Query chaincode on peer0.org1
echo "Querying chaincode on peer0.org1..."
chaincodeQuery 1