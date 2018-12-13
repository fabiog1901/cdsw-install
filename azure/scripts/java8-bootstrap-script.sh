#!/bin/bash
# file: java8-bootstrap-script.sh
set -o errexit

if [ "$(whoami)" != "root" ]; then
  exec sudo $0
else
  exec > /var/log/cdsw-workshop/java8-bootstrap-script.log 2>&1
fi

set -o xtrace

# We remove any natively installed JDKs, as both Cloudera Manager and Cloudera Director only support Oracle JDKs
sudo yum remove --assumeyes *openjdk* oracle-j2sdk1.7*

# Only install/update java if there isn't a java on the path or if the current version isn't 1.8
which java && java -version 2>&1 | grep -q 1.8.0_121 && { echo "Java 1.8 found. No need to install java"; exit 0; }

echo "Java 1.8 needs to be installed"
sudo rpm -ivh "https://archive.cloudera.com/director/redhat/7/x86_64/director/2.6.0/RPMS/x86_64/oracle-j2sdk1.8-1.8.0+update121-1.x86_64.rpm"

JAVA_HOME=/usr/java/jdk1.8.0_121-cloudera
sudo alternatives --install /usr/bin/java java ${JAVA_HOME:?}/bin/java 10
sudo alternatives --install /usr/bin/javac javac ${JAVA_HOME:?}/bin/javac 10
sudo ln -nfs ${JAVA_HOME:?} /usr/java/latest
sudo ln -nfs /usr/java/latest /usr/java/default


curl -v -j -k -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
yum -y install unzip
unzip -o -j -d ${JAVA_HOME:?}/jre/lib/security jce_policy-8.zip

