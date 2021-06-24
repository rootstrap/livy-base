# select operating system
FROM ubuntu:18.04

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
COPY log4j.properties /opt/apache-livy-0.7.0-incubating-bin/conf/log4j.properties

# folders
RUN mkdir /opt/apache-livy
RUN mkdir /var/apache-spark-binaries/

# binaries
# apache livy
RUN wget https://downloads.apache.org/incubator/livy/0.7.1-incubating/apache-livy-0.7.1-incubating-bin.zip -O /tmp/livy.zip
RUN unzip /tmp/livy.zip -d /opt/
# Logging dir
RUN mkdir /opt/apache-livy-0.7.1-incubating-bin/logs

# apache spark
RUN wget https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz -O /tmp/spark-3.1.2-bin-hadoop3.2.tgz
RUN  tar -xvzf /tmp/spark-3.1.2-bin-hadoop3.2.tgz -C /opt/

# set Python3 as default
RUN rm  /usr/bin/python
RUN ln -s /usr/bin/python3 /usr/bin/python

# expose ports
EXPOSE 8998

# start from init folder
WORKDIR /opt/docker-init
ENTRYPOINT ["./entrypoint.sh"]
