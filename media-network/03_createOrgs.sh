#!/bin/bash

source ./00_setEnv.sh

function createArtist {

  echo
	echo "Enroll the CA admin"
  echo
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

  echo
  echo "Register peer0"
    echo
    set -x
    fabric-ca-client register --caname ca-artist --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    set +x

  echo
  echo "Register user"
    echo
    set -x
    fabric-ca-client register --caname ca-artist --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    set +x

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname ca-artist --id.name artistadmin --id.secret artistadminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/artist.mediacoin.com/peers
  mkdir -p organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com

  echo
  echo "## Generate the peer0 msp"
    echo
    set -x
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-artist -M ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/msp --csr.hosts peer0.artist.mediacoin.com --tls.certfiles ${PWD}/organizations/fabric-ca/artist/tls-cert.pem
    set +x

  cp ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/artist.mediacoin.com/peers/peer0.artist.mediacoin.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
    echo
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

  echo
  echo "## Generate the user msp"
    echo
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

  echo
	echo "Enroll the CA admin"
  echo
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

  echo
	echo "Register peer0"
  echo
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
  fabric-ca-client register --caname ca-buyer --id.name buyeradmin --id.secret buyeradminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

	mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/peers
  mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com

  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/msp --csr.hosts peer0.buyer.mediacoin.com --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/peers/peer0.buyer.mediacoin.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
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

  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/User1@buyer.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  mkdir -p organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://buyeradmin:buyeradminpw@localhost:8054 --caname ca-buyer -M ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com/msp --tls.certfiles ${PWD}/organizations/fabric-ca/buyer/tls-cert.pem
  set +x

  cp ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/msp/config.yaml ${PWD}/organizations/peerOrganizations/buyer.mediacoin.com/users/Admin@buyer.mediacoin.com/msp/config.yaml

}

function createOrderer {

  echo
	echo "Enroll the CA admin"
  echo
	mkdir -p organizations/ordererOrganizations/mediacoin.com

	export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/mediacoin.com
  #  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
  #  rm -rf $FABRIC_CA_CLIENT_HOME/msp

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


echo ">>>>>>>>>>>>>>> Deleting the old folders (organizations/peerOrganizations) <<<<<<<<<<<<<<<"
echo 
if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
fi
echo
echo ">>>>>>>>>>>>>>> Deleted the old folders (organizations/peerOrganizations) <<<<<<<<<<<<<<<"

echo
echo ">>>>>>>>>>>>>>> Create crypto material using Fabric CAs  <<<<<<<<<<<<<<<" 
echo 
echo "Checking for Fabric CA client"
fabric-ca-client version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Fabric CA client not found locally"
    exit 0
fi
echo "fabric-ca-client: " $(fabric-ca-client version | sed -ne 's/ Version: //p')

IMAGE_TAG=$IMAGETAG 

docker-compose -f $COMPOSE_FILE_CA up -d 2>&1

sleep 10

echo "##########################################################"
echo "############ Create Artist Identities ######################"
echo "##########################################################"

createArtist

echo "##########################################################"
echo "############ Create Buyer Identities ######################"
echo "##########################################################"

createBuyer

echo "##########################################################"
echo "############ Create Orderer Org Identities ###############"
echo "##########################################################"

createOrderer

echo "##########################################################"
echo "############ Created Orderer/Artist/Buyer Orgs Identities ###############"
echo "##########################################################"