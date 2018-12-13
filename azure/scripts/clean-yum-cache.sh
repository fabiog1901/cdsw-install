#!/bin/bash
set -o errexit

if [ "$(whoami)" != "root" ]; then
  exec sudo $0
else
  exec > /var/log/cdsw-workshop/clean-yum-cache.log 2>&1
fi

set -o xtrace

# Clean up the yum cache - found to be necessary when upgrading from one minor release to another ...

yum clean all
rm -rf /var/cache/yum
