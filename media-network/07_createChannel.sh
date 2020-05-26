#!/bin/bash

source ./00_setEnv.sh

# export CORE_PEER_TLS_ENABLED=true
# export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
# export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
# export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
# export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt

# CHANNEL_NAME="$1"
# DELAY="$2"
# MAX_RETRY="$3"
# VERBOSE="$4"
# : ${CHANNEL_NAME:="mychannel"}
# : ${DELAY:="3"}
# : ${MAX_RETRY:="5"}
# : ${VERBOSE:="false"}

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
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

createChannelTx() {

	set -x
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate channel configuration transaction..."
		exit 1
	fi
	echo

}

createAncorPeerTx() {

	for orgmsp in Org1MSP Org2MSP; do

	echo "#######    Generating anchor peer update for ${orgmsp}  ##########"
	set -x
	configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate anchor peer update for ${orgmsp}..."
		exit 1
	fi
	echo
	done
}

createChannel() {
	setGlobals 1
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create \
            -o localhost:7050 \
            -c $CHANNEL_NAME \
            --ordererTLSHostnameOverride orderer.example.com \
            -f ./channel-artifacts/${CHANNEL_NAME}.tx \
            --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
            --tls $CORE_PEER_TLS_ENABLED \
            --cafile $ORDERER_CA >&log.txt
		res=$?
		set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

# queryCommitted ORG
joinChannel() {
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	echo
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

updateAnchorPeers() {
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
		peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
  verifyResult $res "Anchor peer update failed"
  echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
  sleep $DELAY
  echo
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
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
echo "Join Org1 peers to the channel..."
joinChannel 1
echo "Join Org2 peers to the channel..."
joinChannel 2

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
updateAnchorPeers 1
echo "Updating anchor peers for org2..."
updateAnchorPeers 2

echo
echo "========= Channel successfully joined =========== "
echo

exit 0