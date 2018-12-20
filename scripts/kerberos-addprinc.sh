#!/bin/bash
# file: kerberos-addprinc-sh
set -o errexit

if [ "$(whoami)" != "root" ]; then
  exec sudo $0
else
  exec > /var/log/cdsw-workshop/kerberos-addprinc.log 2>&1
fi

set -o xtrace

echo "Create principals"
kadmin.local addprinc -pw Cloudera1 hdfs_super
kadmin.local addprinc -pw Cloudera1 cdsw 

for i in `seq -w 0 99`;
    do
    kadmin.local addprinc -pw Cloudera1 user$i
done

echo "All principals created"
exit 0
