#!/bin/bash
# file: kerberos-client.sh

set -o errexit

if [ "$(whoami)" != "root" ]; then
  exec sudo $0
else
  exec > /var/log/cdsw-workshop/kerberos-client.log 2>&1
fi

set -o xtrace

yum -y install krb5-workstation openldap-clients unzip
