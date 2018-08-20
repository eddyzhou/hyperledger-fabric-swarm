#!/bin/bash

node_num=2

ip_node0=10.2.10.52
ip_node1=10.2.10.53

user_node0=root
user_node1=root

local_path=$PWD
dest_path_node0=/usr/local/fabric/e2e_cli
dest_path_node1=/usr/local/fabric/e2e_cli

node0=(ca0 kafka1 kafka2 orderer1 peer0Org1 peer1Org1)
node1=(ca1 kafka3 orderer2 peer0Org2 peer1Org2)

removeOldCertFiles () {
  for ((i=0; i<${node_num}; i++)); do
    eval ip=\${ip_node${i}[@]}
    eval user=\${user_node${i}[@]}
    eval dest_path=\${dest_path_node${i}[@]}
    ssh ${user}@${ip} 'rm -rf '${dest_path}
  done
}

copyCertFiles () {
  for ((i=0; i<${node_num}; i++)); do
    eval node=\${node${i}[@]}
    eval ip=\${ip_node${i}[@]}
    eval user=\${user_node${i}[@]}
    eval dest_path=\${dest_path_node${i}[@]}
    for service in ${node}; do
      if [[ ${service} =~ "ca" ]]; then
        if [[ ${service} =~ "ca0" ]]; then
          org_name=org1.example.com
        elif [[ ${service} =~ "ca1" ]]; then 
          org_name=org2.example.com
        fi
        ssh ${user}@${ip} 'mkdir -p '${dest_path}/crypto-config/peerOrganizations/${org_name}
        scp -r ${local_path}/crypto-config/peerOrganizations/${org_name}/ca ${user}@${ip}:${dest_path}/crypto-config/peerOrganizations/${org_name}
      elif [[ ${service} =~ "kafka" ]]; then
        echo ""
        ssh ${user}@${ip} 'mkdir -p '${dest_path}/kafkaKeystore
        scp ${local_path}/kafkaKeystore/*${service} ${user}@${ip}:${dest_path}/kafkaKeystore
      elif [[ ${service} =~ "orderer" ]]; then
        echo ""
        ssh ${user}@${ip} 'mkdir -p '${dest_path}/channel-artifacts
        ssh ${user}@${ip} 'mkdir -p '${dest_path}/crypto-config/ordererOrganizations/example.com/orderers/${service}
        ssh ${user}@${ip} 'mkdir -p '${dest_path}/kafkaKeystore
        scp ${local_path}/channel-artifacts/genesis.block ${user}@${ip}:${dest_path}/channel-artifacts
        scp -r ${local_path}/crypto-config/ordererOrganizations/example.com/orderers/${service}/msp ${user}@${ip}:${dest_path}/crypto-config/ordererOrganizations/example.com/orderers/${service}
        scp -r ${local_path}/crypto-config/ordererOrganizations/example.com/orderers/${service}/tls ${user}@${ip}:${dest_path}/crypto-config/ordererOrganizations/example.com/orderers/${service}
        scp ${local_path}/kafkaKeystore/*${service}* ${user}@${ip}:${dest_path}/kafkaKeystore
        scp ${local_path}/kafkaKeystore/ca-cert.pem ${user}@${ip}:${dest_path}/kafkaKeystore
      elif [[ ${service} =~ "peer" ]]; then
        if [[ ${service} =~ "Org1" ]]; then
          org_name=org1.example.com
        elif [[ ${service} =~ "Org2" ]]; then
          org_name=org2.example.com
        fi
        echo ""
        ssh ${user}@${ip} 'mkdir -p '${dest_path}/crypto-config/peerOrganizations/${org_name}/peers/${service}
        scp -r ${local_path}/crypto-config/peerOrganizations/${org_name}/peers/${service}/msp ${user}@${ip}:${dest_path}/crypto-config/peerOrganizations/${org_name}/peers/${service}
        scp -r ${local_path}/crypto-config/peerOrganizations/${org_name}/peers/${service}/tls ${user}@${ip}:${dest_path}/crypto-config/peerOrganizations/${org_name}/peers/${service}
      fi
    done
  done
}

removeOldCertFiles
copyCertFiles 
