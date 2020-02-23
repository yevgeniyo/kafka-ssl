#!/bin/bash -x

PASSWORD=<set your certificates password here>

if [ ! -f /cert/server.keystore.jks ]; then
    cd /cert

  openssl pkcs12 \
          -export \
          -in /cert/cert \
          -inkey /cert/key \
          -name $HOSTNAME \
          -out $HOSTNAME-PKCS-12.p12 \
          -password pass:$PASSWORD

  keytool -importkeystore \
          -srcstorepass $PASSWORD \
          -deststorepass $PASSWORD \
          -destkeystore server.keystore.jks \
          -srckeystore $HOSTNAME-PKCS-12.p12 \
          -srcstoretype PKCS12

  keytool -importcert \
          -keystore server.keystore.jks \
          -alias rootCa -file /cert/CA.pem \
          -noprompt \
          -storepass $PASSWORD

    keytool -keystore server.truststore.jks -import -file CA.pem -storepass $PASSWORD -noprompt


    cd /kafka

    echo " " >> /kafka/config/server.properties
    echo "ssl.keystore.location=/cert/server.keystore.jks" >> /kafka/config/server.properties
    echo "ssl.keystore.password=$PASSWORD" >> /kafka/config/server.properties
    echo "ssl.key.password=$PASSWORD" >> /kafka/config/server.properties
    echo "ssl.truststore.location=/cert/server.truststore.jks" >> /kafka/config/server.properties
    echo "ssl.truststore.password=$PASSWORD" >> /kafka/config/server.properties
    echo "#security.inter.broker.protocol=SASL_PLAINTEXT" >> /kafka/config/server.properties
    echo "inter.broker.listener.name=PLAINTEXT" >> /kafka/config/server.properties
    echo "sasl.enabled.mechanisms=PLAIN" >> /kafka/config/server.properties
    echo "#sasl.mechanism.inter.broker.protocol=PLAIN" >> /kafka/config/server.properties
    echo "zookeeper.set.acl=false" >> /kafka/config/server.properties


    cat <<EOT >> /kafka/config/kafka_server_jaas.conf
    KafkaServer {
        org.apache.kafka.common.security.plain.PlainLoginModule required
        username="admin"
        password="$PASSWORD"
        user_admin="$PASSWORD"
        user_user="password";
    };
EOT


fi

#Removing hostname entry under /etc/hosts
grep -v $HOSTNAME /etc/hosts > /tmp/hosts.tmp ; cp /tmp/hosts.tmp /etc/hosts

sed -i "s/localhost:2181/${ZOOKEEPER_ADD}/g" /kafka/config/server.properties
sed -i "s/broker.id=0/broker.id=${BROKER_ID}/g" /kafka/config/server.properties
sed -i "s/#listeners=PLAINTEXT:\/\/:9092/listeners=PLAINTEXT:\/\/:9092,SASL_SSL:\/\/:9093/g" /kafka/config/server.properties
sed -i "s/#advertised.listeners=PLAINTEXT:\/\/your.host.name:9092/advertised.listeners=PLAINTEXT:\/\/${ADV_ADD}:${ADV_PORT_PLAIN},SASL_SSL:\/\/${HOSTNAME}:${ADV_PORT_SSL}/g" /kafka/config/server.properties
sed -i "s/log.dirs=\/tmp\/kafka-logs/log.dirs=\/data\/kafka-logs/g" /kafka/config/server.properties




export KAFKA_OPTS="$KAFKA_OPTS -javaagent:/kafka/jmx_prometheus_javaagent-0.6.jar=7071:/kafka/kafka-0-8-2.yml"
export KAFKA_OPTS="$KAFKA_OPTS -Djava.security.auth.login.config=/kafka/config/kafka_server_jaas.conf"



exec ./bin/kafka-server-start.sh /kafka/config/server.properties





