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
kadmin.local addprinc -pw cloudera hdfs_super
kadmin.local addprinc -pw cloudera cdsw 

for i in `seq -w 30`;
    do
    kadmin.local addprinc -pw cloudera user$i
done

echo "All principals created"
exit 0
