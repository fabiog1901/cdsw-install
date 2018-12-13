#!/bin/bash

which terraform > /dev/null 2>&1
if [ $? != 0 ]; then
  echo "ERROR: Ensure terraform is in your path and try again."
  exit 1
fi

API_VERSION=v12

ENV_NAME=cdsw-workshop-env
DEP_NAME=cdsw-workshop-cm
CLU_NAME=cdsw-workshop

COOKIE_JAR=./.cookies

function set_terraform_workspace() {
  local workspace=$1
  if [ "$workspace" == "" ]; then
    unset TF_WORKSPACE
  else
    export TF_WORKSPACE="$workspace"
  fi
}

function get_director_host() {
##  if [ "$TF_WORKSPACE" != "" ]; then
#    #if [ -f $BASE_DIR/terraform.tfstate.d/$workspace/terraform.tfstate ]
#    export TF_WORKSPACE="$workspace"
#  fi
  terraform state show aws_instance.cdsw-workshop | grep public_dns | awk '{print $NF}'
}

function api_login() {
  local director_host=${1:-$(get_director_host)}
  curl --cookie-jar $COOKIE_JAR --cookie $COOKIE_JAR -H "accept: application/json" -H "Content-Type: application/json" \
    -X POST \
    "http://$director_host:7189/api/$API_VERSION/login" \
    -d "{ \"password\": \"admin\", \"username\": \"admin\"}" > /dev/null 2>&1
}

function api_delete_deployment() {
  local director_host=${1:-$(get_director_host)}
  curl --cookie $COOKIE_JAR -H "accept: application/json" -H "Content-Type: application/json" \
    -X DELETE \
    "http://$director_host:7189/api/$API_VERSION/environments/$ENV_NAME/deployments/$DEP_NAME"
}

function api_get_deployment_status() {
  local director_host=${1:-$(get_director_host)}
  curl --cookie $COOKIE_JAR -H "accept: application/json" -H "Content-Type: application/json" \
    -X GET \
    "http://$director_host:7189/api/$API_VERSION/environments/$ENV_NAME/deployments/$DEP_NAME/status" 2>/dev/null
}

function api_get_deployment() {
  local director_host=${1:-$(get_director_host)}
  curl --cookie $COOKIE_JAR -H "accept: application/json" -H "Content-Type: application/json" \
    -X GET \
    "http://$director_host:7189/api/$API_VERSION/environments/$ENV_NAME/deployments/$DEP_NAME" 2>/dev/null
}

function api_get_cluster() {
  local director_host=${1:-$(get_director_host)}
  curl --cookie $COOKIE_JAR -H "accept: application/json" -H "Content-Type: application/json" \
    -X GET \
    "http://$director_host:7189/api/$API_VERSION/environments/$ENV_NAME/deployments/$DEP_NAME/clusters/$CLU_NAME" 2>/dev/null
}

function api_get_cluster_status() {
  local director_host=${1:-$(get_director_host)}
  curl --cookie $COOKIE_JAR -H "accept: application/json" -H "Content-Type: application/json" \
    -X GET \
    "http://$director_host:7189/api/$API_VERSION/environments/$ENV_NAME/deployments/$DEP_NAME/clusters/$CLU_NAME/status" 2>/dev/null
}

function get_public_address() {
  local template_name=$1
  local property_name=$2
  python -c '
import json
import sys

try:
    j = json.load(sys.stdin)
    if "managerInstance" in j:
        print(j["managerInstance"]["properties"]["publicDnsName"])
    else:
        for inst in j["instances"]:
            if inst["virtualInstance"]["template"]["name"] == "cdswmasters":
                print(inst["properties"]["publicIpAddress"])
except:
    pass
'
}

function get_cm_public_dns() {
  local director_host=${1:-$(get_director_host)}
  # Get CM public ip
  api_get_deployment $director_host | get_public_address
}

function get_cdsw_public_ip() {
  local director_host=${1:-$(get_director_host)}
  # Get CDSW public ip
  api_get_cluster $director_host | get_public_address
}

function get_director_url() {
  local director_host=${1:-$(get_director_host)}
  if [ "$director_host" != "" ]; then
    echo "http://$director_host:7189/"
  fi
}

function get_cm_url() {
  local director_host=${1:-$(get_director_host)}
  cm_public_dns=$(get_cm_public_dns $director_host)
  if [ "$cm_public_dns" != "" ]; then
    echo "http://$cm_public_dns:7180/"
  fi
}

function get_cdsw_url() {
  local director_host=${1:-$(get_director_host)}
  cdsw_public_ip=$(get_cdsw_public_ip $director_host)
  if [ "$cdsw_public_ip" != "" ]; then
    echo "http://cdsw.${cdsw_public_ip}.nip.io/"
  fi
}
