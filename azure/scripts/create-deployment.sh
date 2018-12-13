#!/bin/bash
set -o errexit

exec > /var/log/cdsw-workshop/create-deployment.log 2>&1
set -o xtrace

while true; do
  set +o errexit
  curl -w "ReturnCode:%{http_code}\n" "http://localhost:7189/api/v12/eula" -o /dev/null 2> /dev/null | grep ReturnCode:200
  ret=$?
  set -o errexit
  if [ $ret == 0 ]; then
    echo "Director is ready!"
    break
  fi
  echo "Waiting for Director to be ready..."
  sleep 1
done

nohup cloudera-director bootstrap-remote director-conf/azure.conf \
  --lp.remote.username=admin \
  --lp.remote.password=admin \
  > /var/log/cdsw-workshop/bootstrap.log 2>&1 &
