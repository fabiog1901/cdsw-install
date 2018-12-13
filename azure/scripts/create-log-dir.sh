#!/bin/bash
set -o errexit

user_id=${1:-$(id -u)}
group_id=${2:-$(id -g)}

if [ "$(whoami)" != "root" ]; then
  exec sudo $0 $user_id $group_id
fi

mkdir -p /var/log/cdsw-workshop
chown $user_id:$group_id /var/log/cdsw-workshop
