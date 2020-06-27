#!/bin/bash

source ./00_setEnv.sh

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
	set -x
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	configtxgen -profile TwoOrgsChannel1 -outputCreateChannelTx ./channel-artifacts/${SECOND_CHANNEL_NAME}.tx -channelID $SECOND_CHANNEL_NAME
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate channel configuration transaction..."
		exit 1
	fi
	echo 
}

createAncorPeerTx() {
	for orgmsp in ArtistMSP BuyerMSP; do
		echo "#######    Generating anchor peer update for ${orgmsp}  ##########"
		set -x
		configtxgen -profile TwoOrgsChannel \
			-outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx \
			-channelID $CHANNEL_NAME \
			-asOrg ${orgmsp}
		res=$?
		set +x
		if [ $res -ne 0 ]; then
			echo "Failed to generate anchor peer update for ${orgmsp}..."
			exit 1
		fi
		echo
	done
		for orgmsp in ArtistMSP Buyer2MSP; do
		echo "#######    Generating anchor peer update for ${orgmsp}  ##########"
		set -x
		configtxgen -profile TwoOrgsChannel1 \
			-outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors2.tx \
			-channelID $SECOND_CHANNEL_NAME \
			-asOrg ${orgmsp}
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
			--ordererTLSHostnameOverride orderer.mediacoin.com \
			-f ./channel-artifacts/${CHANNEL_NAME}.tx \
			--outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
			--tls $CORE_PEER_TLS_ENABLED \
			--cafile $ORDERER_CA  
		peer channel create \
			-o localhost:7050 \
			-c $SECOND_CHANNEL_NAME \
			--ordererTLSHostnameOverride orderer.mediacoin.com \
			-f ./channel-artifacts/${SECOND_CHANNEL_NAME}.tx \
			--outputBlock ./channel-artifacts/${SECOND_CHANNEL_NAME}.block \
			--tls $CORE_PEER_TLS_ENABLED \
			--cafile $ORDERER_CA  			
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
	ORG=1
	setGlobals $ORG
	peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block 
	ORG=2
	setGlobals $ORG
	peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
	ORG=3
	setGlobals $ORG
	peer channel join -b ./channel-artifacts/$SECOND_CHANNEL_NAME.block
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
		peer channel update -o localhost:7050 \
			--ordererTLSHostnameOverride orderer.mediacoin.com \
			-c $CHANNEL_NAME \
			-f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx \
			--tls $CORE_PEER_TLS_ENABLED \
			--cafile $ORDERER_CA >&log.txt
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

updateAnchorPeers2() {
  
	setGlobals 3

	peer channel update -o localhost:7050 \
		--ordererTLSHostnameOverride orderer.mediacoin.com \
		-c $SECOND_CHANNEL_NAME \
		-f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors2.tx \
		--tls $CORE_PEER_TLS_ENABLED \
		--cafile $ORDERER_CA  
    
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
echo "Join Artist peers to the channel..."
joinChannel 

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for artist..."
updateAnchorPeers 1
echo "Updating anchor peers for buyer..."
updateAnchorPeers 2
updateAnchorPeers2

echo
echo "========= Channel successfully joined =========== "
echo

exit 0