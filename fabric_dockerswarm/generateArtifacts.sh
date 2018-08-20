#!/bin/bash +x

#set -e

CHANNEL_NAME=$1
: ${CHANNEL_NAME:="mychannel"}
echo "Channel name : "$CHANNEL_NAME
export PATH=${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD
export VERBOSE=false

## Generates Org certs using cryptogen tool
function generateCerts (){
    rm -rf ./crypto-config
    CRYPTOGEN=./bin/cryptogen

    echo "Using cryptogen -> $CRYPTOGEN"

    echo
    echo "##########################################################"
    echo "##### Generate certificates using cryptogen tool #########"
    echo "##########################################################"
    $CRYPTOGEN generate --config=./crypto-config.yaml 
    echo
}

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {
    rm -rf ./channel-artifacts
    mkdir channel-artifacts

    CONFIGTXGEN=./bin/configtxgen
    echo "Using configtxgen -> $CONFIGTXGEN"

    echo "##########################################################"
    echo "#########  Generating Orderer Genesis block ##############"
    echo "##########################################################"
    # Note: For some unknown reason (at least for now) the block file can't be
    # named orderer.genesis.block or the orderer will fail to launch!
    $CONFIGTXGEN -profile TwoOrgsOrdererGenesis -channelID e2e-orderer-syschan -outputBlock ./channel-artifacts/genesis.block

    echo
    echo "#################################################################"
    echo "### Generating channel configuration transaction 'channel.tx' ###"
    echo "#################################################################"
    $CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for Org1MSP   ##########"
    echo "#################################################################"
    $CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for Org2MSP   ##########"
    echo "#################################################################"
    $CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
    echo
}

function replaceVars() {
    # sed on MacOSX does not support -i flag with a null extension. We will use
    # 't' for our back-up's extension and delete it at the end of the function
    ARCH=$(uname -s | grep Darwin)
    if [ "$ARCH" == "Darwin" ]; then
        OPTS="-it"
    else
        OPTS="-i"
    fi

    # Copy the template to the file that will be modified to add the private key
    cp docker-compose-template.yml docker-compose.yml

    # The next steps will replace the template's contents with the
    # actual values of the private key file names for the two CAs.
    CURRENT_DIR=$PWD
    cd crypto-config/peerOrganizations/org1.example.com/ca/
    PRIV_KEY=$(ls *_sk)
    cd "$CURRENT_DIR"
    sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml
    cd crypto-config/peerOrganizations/org2.example.com/ca/
    PRIV_KEY=$(ls *_sk)
    cd "$CURRENT_DIR"
    sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml

    source ./vars.env
    sed $OPTS "s/IMAGE_TAG/${IMAGE_TAG}/g" docker-compose.yml
    sed $OPTS "s/NODE1_HOSTNAME/${NODE1_HOSTNAME}/g" docker-compose.yml
    sed $OPTS "s/NODE2_HOSTNAME/${NODE2_HOSTNAME}/g" docker-compose.yml
    sed $OPTS "s/NODE3_HOSTNAME/${NODE3_HOSTNAME}/g" docker-compose.yml
    sed $OPTS "s/NODE1_IP/${NODE1_IP}/g" docker-compose.yml
    sed $OPTS "s/NODE2_IP/${NODE2_IP}/g" docker-compose.yml
    sed $OPTS "s/NODE3_IP/${NODE3_IP}/g" docker-compose.yml

    # If MacOSX, remove the temporary backup of the docker-compose file
    if [ "$ARCH" == "Darwin" ]; then
        rm docker-compose.ymlt
    fi
}

function generateIdemixMaterial (){
    CURDIR=`pwd`
    IDEMIXGEN=$CURDIR/bin/idemixgen
    IDEMIXMATDIR=$CURDIR/crypto-config/idemix

    echo "Using idemixgen -> $IDEMIXGEN"

    echo
    echo "####################################################################"
    echo "##### Generate idemix crypto material using idemixgen tool #########"
    echo "####################################################################"

    mkdir -p $IDEMIXMATDIR
    cd $IDEMIXMATDIR

    # Generate the idemix issuer keys
    $IDEMIXGEN ca-keygen

    # Generate the idemix signer keys
    $IDEMIXGEN signerconfig -u OU1 -e OU1 -r 1

    cd $CURDIR
}


generateCerts
generateIdemixMaterial
replaceVars
generateChannelArtifacts
