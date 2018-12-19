#!/bin/bash
# file: create-users.sh
set -o errexit

if [ "$(whoami)" != "root" ]; then
  exec sudo $0
else
  exec > /var/log/cdsw-workshop/create-users.log 2>&1
fi

set -o xtrace

# Cluster post creation script

echo "Creating users"
useradd -U cdsw

for i in `seq -w 100`; 
   do 
   useradd -U user$i
   echo Cloudera1 | passwd --stdin user$i
done

groupadd supergroup
useradd -G supergroup -u 12354 hdfs_super
usermod -G supergroup cdsw
echo Cloudera1 | passwd --stdin cdsw

echo "All completed!"
