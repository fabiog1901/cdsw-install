#!/bin/bash
set -o errexit

if [ "$(whoami)" != "root" ]; then
  exec sudo $0
else
  exec > /var/log/cdsw-workshop/install-director.log 2>&1
fi

set -o xtrace

# Install wget and unzip
sudo yum -y update
sudo yum install -y wget unzip

# Install Director
sudo wget "http://archive.cloudera.com/director/redhat/7/x86_64/director/cloudera-director.repo" -O /etc/yum.repos.d/cloudera-director.repo
sudo yum install -y cloudera-director-server cloudera-director-client
sudo service cloudera-director-server start

# Install packer
wget https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip
unzip packer_0.10.1_linux_amd64.zip
sudo mv packer /usr/local/bin/

# Install aws cli (optional to copy logs later)
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
