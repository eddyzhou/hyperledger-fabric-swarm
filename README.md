hyperledger-fabric-swarm
===============

This project provisions a sample Fabric network consisting of
two organizations, each maintaining two peers, and a Kafka-based ordering service


初始化
-----

- 执行 init.sh，生成 configtxgen, cryptogen, idemixgen 等可执行文件，同时下载 fabric 的 docker images.

- 将 vars.env 的配置更新为你当前环境的 HOST 和 IP

- 将测试用的几台机器设置为相互免密登陆


生成证书和 docker-compose 文件
-----

执行 ./generateArtifacts.sh, ./createKafkakeystore.sh, ./copyArtifacts.sh


搭建swarm集群
-----

- 在其中一台机器上执行：```docker swarm init```，然后让其他机器加入集群

- 创建网络：```docker network create -d overlay fabric-network```


启动
-----

执行 ```docker stack deploy -c docker-compose.yml test```

确认环境搭建成功：

```docker service ls  (REPLICAS为1/1)```


测试
-----

启动 cli 容器: ```docker exec -it xxx bash```

```echo "yourip orderer0" >> /etc/hosts```

执行 test.sh 测试脚本的内容


配置出错重试
-----

- 在 master 上执行：```docker stack rm test```

- 在所有节点上执行：```docker volume rm $(docker volume ls)```

- 修改配置后, 重新生成证书

- 清除环境，记得清除 chaincode 生成的镜像 (docker images | grep dev)

