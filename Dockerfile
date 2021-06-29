# select operating system
FROM ubuntu:18.04

ENV LIVY_VERSION=0.7.1-incubating
ENV SPARK_VERSION=3.1.2
ENV HADDOP_VERSION=3.2

# install operating system packages 
RUN apt-get update -y &&  apt-get install git curl gettext unzip wget python-pip python3-pip dnsutils make -y 

## add more packages, if necessary
# install Java8
RUN apt install -y software-properties-common
RUN add-apt-repository ppa:webupd8team/java -y && apt-get update && apt-get -y install openjdk-8-jdk-headless

# install boto3 library for PySpark applications to connect to S3
RUN pip install boto3


# use bpkg to handle complex bash entrypoints
# setting this env explicitly is required to get the bpkg install script working 
ENV USER=root
RUN curl -Lo- "https://raw.githubusercontent.com/bpkg/bpkg/master/setup.sh" | bash
RUN bpkg install cha87de/bashutil -g
## add more bash dependencies, if necessary 

# add config, init and source files 
# entrypoint
COPY entrypoint.sh /opt/docker-init/entrypoint.sh
COPY livy.conf /opt/docker-conf/livy.conf 
COPY log4j.properties /opt/apache-livy-${LIVY_VERSION}-bin/conf/log4j.properties

# folders
RUN mkdir /opt/apache-livy
RUN mkdir /var/apache-spark-binaries/

# binaries
# apache livy
RUN wget http://archive.apache.org/dist/incubator/livy/${LIVY_VERSION}/apache-livy-${LIVY_VERSION}-bin.zip

RUN unzip /tmp/livy.zip -d /opt/
# Logging dir
RUN mkdir /opt/apache-${LIVY_VERSION}-bin/logs

# apache spark
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADDOP_VERSION}.tgz -O /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADDOP_VERSION}.tgz
RUN  tar -xvzf /tmp/spark-${SPARK_VERSION}-bin-hadoop${HADDOP_VERSION}.tgz -C /opt/

# set Python3 as default
RUN rm  /usr/bin/python
RUN ln -s /usr/bin/python3 /usr/bin/python

# expose ports
EXPOSE 8998

# start from init folder
WORKDIR /opt/docker-init
ENTRYPOINT ["./entrypoint.sh"]
