#!/bin/bash

source ./00_setEnv.sh

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

ORG=3
P0PORT=11051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/buyer2.mediacoin.com/tlsca/tlsca.buyer2.mediacoin.com-cert.pem
CAPEM=organizations/peerOrganizations/buyer2.mediacoin.com/ca/ca.buyer2.mediacoin.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/buyer2.mediacoin.com/connection-buyer2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/buyer2.mediacoin.com/connection-buyer2.yaml