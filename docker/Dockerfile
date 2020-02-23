FROM ubuntu:18.04

# Update for apt and installing soft
RUN apt-get update -y && \
    apt-get -y install wget vim software-properties-common && \
    apt install -y openjdk-8-jdk openjdk-8-jre

RUN mkdir /kafka /data /logs /cert

RUN  wget http://apache.mivzakim.net/kafka/2.3.0/kafka_2.12-2.3.0.tgz && \
     tar -xz  --strip-components=1 -C /kafka -f kafka_2.12-2.3.0.tgz && \
     rm -rf kafka_* && \
     cd /kafka && \
     wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.6/jmx_prometheus_javaagent-0.6.jar && \
     wget https://raw.githubusercontent.com/prometheus/jmx_exporter/master/example_configs/kafka-0-8-2.yml



ADD start.sh /start.sh

RUN chmod +x /start.sh

#USER kafka
ENV PATH /kafka/bin:$PATH

WORKDIR /kafka

VOLUME [ "/data"]

CMD ["/start.sh"]
