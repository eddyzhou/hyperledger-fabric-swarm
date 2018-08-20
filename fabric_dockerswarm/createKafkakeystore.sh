#!/bin/bash

PASSWD=adminpw
DEST=kafkaKeystore

[ -d "$DEST" ] && rm -rf $DEST
[ -d "$DEST" ] || mkdir -p $DEST
cd $DEST

echo "# generate client private key and keystore"
keytool -keystore client.keystore.jks -alias orderer -validity 365 -genkey -keyalg EC -keysize 256 -storepass $PASSWD -dname "cn=orderer" -keypass $PASSWD

echo "# create self signed certificate for certificate authority"
openssl req -new -x509 -keyout ca-key.pem -out ca-cert.pem -days 365 -subj "/CN=kafkaCA" -nodes

#echo "# create client truststore"
#keytool -keystore client.truststore.jks -alias CARoot -import -file ca-cert.pem -storepass $PASSWD -noprompt

for i in `seq 0 3`
do
    echo "# ***** processing kafka$i *****"

    echo "# generate server private key and keystore"
    keytool -keystore server.keystore.jks -alias kafka -validity 365 -genkey -keyalg EC -keysize 256 -storepass $PASSWD -dname "cn=kafka" -keypass $PASSWD

    echo "# create truststores for server"
    keytool -keystore server.truststore.jks -alias CARoot -import -file ca-cert.pem -storepass $PASSWD -noprompt

    echo "# create server certificate signing request"
    keytool -keystore server.keystore.jks -alias kafka -certreq -file server-cert-signing-request.pem -storepass $PASSWD -dname "cn=kafka$i"

    echo "# sign the server certificate"
    openssl x509 -req -CA ca-cert.pem -CAkey ca-key.pem -in server-cert-signing-request.pem -out server-cert-signed.pem -days 365 -CAcreateserial -passin pass:$PASSWD

    echo "# import server signed certificate and certificate authority certificate to server keystore"
    keytool -keystore server.keystore.jks -alias CARoot -import -file ca-cert.pem -storepass $PASSWD -noprompt
    keytool -keystore server.keystore.jks -alias kafka -import -file server-cert-signed.pem -storepass $PASSWD -noprompt

    mv server.keystore.jks server.keystore.jks.kafka$i
    mv server.truststore.jks server.truststore.jks.kafka$i
    rm server-cert-signing-request.pem
    rm server-cert-signed.pem

done

for i in `seq 0 2`
do
    echo "# create client certificate signing request"
    keytool -keystore client.keystore.jks -alias orderer -certreq -file client-cert-signing-request.pem -storepass $PASSWD

    echo "# sign the client certificate"
    openssl x509 -req -CA ca-cert.pem -CAkey ca-key.pem -in client-cert-signing-request.pem -out client-cert-signed-orderer$i.pem -days 365 -CAcreateserial -passin pass:$PASSWD

    echo "# convert JKS client keystore to PKCS12"
    keytool -importkeystore -srckeystore client.keystore.jks -destkeystore client.keystore.p12 -deststoretype PKCS12 -storepass $PASSWD -srcstorepass $PASSWD

    echo "# export client private key to pem file"
    openssl pkcs12 -in client.keystore.p12 -nodes -nocerts -out client-key-orderer$i.pem -passin pass:$PASSWD

    rm client.keystore.p12
    rm client-cert-signing-request.pem

done

cd -
