#!/bin/bash

source ./00_setEnv.sh

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
  export CORE_PEER_LOCALMSPID="OrdererMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/mediacoin.com/orderers/orderer.mediacoin.com/msp/tlscacerts/tlsca.mediacoin.com-cert.pem
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/ordererOrganizations/mediacoin.com/users/Admin@mediacoin.com/msp
}

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  USING_ORG=$1
  echo "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="ArtistMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ARTIST_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com/msp
    export CORE_PEER_ADDRESS=localhost:7051

  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="Buyer2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BUYER2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/buyer2.mediacoin.com/users/Admin@buyer2.mediacoin.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    echo "================== ERROR !!! ORG Unknown =================="
    exit 1
  fi 
}

setGlobalsForPeer0Artist() {
    export CORE_PEER_LOCALMSPID="ArtistMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ARTIST_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/artist.mediacoin.com/users/Admin@artist.mediacoin.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
}
 
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

CC_RUNTIME_LANGUAGE=golang
CC_SRC_PATH="chaincode/$CC_NAME2/go/"

echo Vendoring Go dependencies ...
pushd chaincode/$CC_NAME2/go
GO111MODULE=on go mod vendor
popd
echo Finished vendoring Go dependencies

packageChaincode() {
  ORG=$1
  setGlobals $ORG
  
  peer lifecycle chaincode package ${CC_NAME2}.tar.gz \
    --path ${CC_SRC_PATH} \
    --lang ${CC_RUNTIME_LANGUAGE} \
    --label ${CC_NAME2}_${VERSION}  
  
  echo "===================== Chaincode is packaged on peer0.org${ORG} ===================== "
  
}

installChaincode() {
  ORG=$1
  setGlobals $ORG 
  peer lifecycle chaincode install $CC_NAME2.tar.gz  
  echo "===================== Chaincode is installed on peer0.org${ORG} ===================== "
  echo
}

# queryInstalled PEER ORG
queryInstalled() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
	PACKAGE_ID=$(sed -n "/$CC_NAME2_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt) 
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
      --channelID $SECOND_CHANNEL_NAME \
      --name $CC_NAME2 \
      --version ${VERSION} \
      --init-required \
      --package-id ${PACKAGE_ID} \
      --sequence ${VERSION}  
  
  echo "===================== Chaincode definition approved on peer0.org${ORG} on channel '$SECOND_CHANNEL_NAME' ===================== "
  echo
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  echo "===================== Checking the commit readiness of the chaincode definition on peer0.org${ORG} on channel '$SECOND_CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
  
  cat /dev/null > log.txt

	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to check the commit readiness of the chaincode definition on peer0.org${ORG} secs"
    set -x
    peer lifecycle chaincode checkcommitreadiness \
      --channelID $SECOND_CHANNEL_NAME \
      --name $CC_NAME2 \
      --version ${VERSION} \
      --sequence ${VERSION} \
      --output json \
      --init-required >&log.txt
    res=$?
    set +x
    let rc=0
    for var in "$@"
    do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
		COUNTER=$(expr $COUNTER + 1)
	done
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$SECOND_CHANNEL_NAME' ===================== "
  fi
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() { 
   
  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer lifecycle chaincode commit \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.mediacoin.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA \
    --channelID $SECOND_CHANNEL_NAME \
    --name $CC_NAME2 \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ARTIST_CA \
    --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_BUYER2_CA \
    --version ${VERSION} \
    --sequence ${VERSION} \
    --init-required >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$SECOND_CHANNEL_NAME' failed"
  echo "===================== Chaincode definition committed on channel '$SECOND_CHANNEL_NAME' ===================== "
  echo
}

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  EXPECTED_RESULT="Version: ${VERSION}, Sequence: ${VERSION}, Endorsement Plugin: escc, Validation Plugin: vscc"
  echo "===================== Querying chaincode definition on peer0.org${ORG} on channel '$SECOND_CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $SECOND_CHANNEL_NAME --name $CC_NAME2 >&log.txt
    res=$?
    set +x
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: [0-9], Sequence: [0-9], Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query chaincode definition successful on peer0.org${ORG} on channel '$SECOND_CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query chaincode definition result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

chaincodeInvokeInit() { 
  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.mediacoin.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA \
    -C $SECOND_CHANNEL_NAME \
    -n $CC_NAME2 \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ARTIST_CA \
    --peerAddresses localhost:11051 --tlsRootCertFiles $PEER0_BUYER2_CA \
    --isInit \
    -c '{"function":"initLedger","Args":[]}'   
  set +x
  echo "===================== Invoke transaction successful on $PEERS on channel '$SECOND_CHANNEL_NAME' ===================== "
  echo
}

chaincodeQuery() {
  ORG=$1
  setGlobals $ORG
  echo "===================== Querying on peer0.org${ORG} on channel '$SECOND_CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query peer0.org${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    # peer chaincode query -C $SECOND_CHANNEL_NAME -n $CC_NAME2 -c '{"Args":["QueryAllMediaContracts"]}' >&log.txt
    peer chaincode query -C $SECOND_CHANNEL_NAME -n $CC_NAME2 -c '{"Args":["QueryMedium", "CONTRACT0"]}' >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  cat log.txt
  echo   
}

chaincodeQuery 3

exit 0

## at first we package the chaincode
packageChaincode 1

## Install chaincode on peer0.artist and peer0.buyer2
echo "Installing chaincode on peer0.artist..."
installChaincode 1

echo "Install chaincode on peer0.buyer2..."
installChaincode 3

## query whether the chaincode is installed
queryInstalled 1
queryInstalled 3

## approve the definition for artist
approveForMyOrg 1

## check whether the chaincode definition is ready to be committed
## expect artist to have approved and buyer not to
checkCommitReadiness 1 "\"ArtistMSP\": true" "\"Buyer2MSP\": false"
checkCommitReadiness 3 "\"ArtistMSP\": true" "\"Buyer2MSP\": false"

## now approve also for buyer
approveForMyOrg 3

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 "\"ArtistMSP\": true" "\"Buyer2MSP\": true"
checkCommitReadiness 3 "\"ArtistMSP\": true" "\"Buyer2MSP\": true"

## now that we know for sure both orgs have approved, commit the definition
commitChaincodeDefinition 1 3

## query on both orgs to see that the definition committed successfully
queryCommitted 1
queryCommitted 3

## Invoke the chaincode
chaincodeInvokeInit

sleep 10

# Query chaincode on peer0.artist
echo "Querying chaincode on peer0.artist..."
chaincodeQuery 3

exit 0
