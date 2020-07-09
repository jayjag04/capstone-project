#!/bin/bash

source ./00_setEnv.sh

echo ">>>>>>>>>>>>>>> checking peer version <<<<<<<<<<<<<<<"
echo
## Check if your have cloned the peer binaries and configuration files.
peer version > /dev/null 2>&1

if [[ $? -ne 0 || ! -d "../config" ]]; then
    echo "ERROR! Peer binary and configuration files not found.."
    echo
    exit 1
fi
echo "peer version: "
peer version
echo ">>>>>>>>>>>>>>> checked peer version <<<<<<<<<<<<<<<"

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