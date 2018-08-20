#!/bin/bash

## 创建channel
peer channel create -o orderer0:7055 -c mychannel -f ./channel-artifacts/channel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer0/msp/tlscacerts/tlsca.example.com-cert.pem

## 加入channel
peer channel join -b mychannel.block 

## 查看channel列表
peer channel list

## 安装chaincode智能合约
peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/example02

## 初始化智能合约
peer chaincode instantiate -o orderer0:7055 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer0/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('Org1MSP.member','Org2MSP.member')" 

## 调用
peer chaincode invoke -o orderer0:7055  --tls true --cafile  /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer0/msp/tlscacerts/tlsca.example.com-cert.pem  -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}' 

## 查询
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
