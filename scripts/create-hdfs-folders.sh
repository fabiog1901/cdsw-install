#!/bin/bash
# file: create-hdfs-folders.sh

set -o errexit

exec > /var/log/cdsw-workshop/create-hdfs-folders.log 2>&1
set -o xtrace

# Cluster post creation script

echo "kinit as hdfs_super"
echo "Cloudera1" | kinit hdfs_super

echo "Creating folders"

hadoop fs -mkdir /user/hdfs_super
hadoop fs -chown hdfs_super:hdfs_super /user/hdfs_super

hadoop fs -mkdir /user/cdsw
hadoop fs -chown cdsw:cdsw /user/cdsw

for i in `seq -w 100` ;
  do 
  hadoop fs -mkdir /user/user$i
  hadoop fs -chown user$i:user$i /user/user$i
done

echo "All completed!"
