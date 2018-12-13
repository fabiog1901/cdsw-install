#!/bin/bash
BASE_DIR=$(dirname $0)
source $BASE_DIR/common.sh

OUTPUTS=$BASE_DIR/.outputs

WORKSPACE=${1:-}
ADMIN_EMAIL=${2:-}
CDSW_URL=${3:-}

set_terraform_workspace "$WORKSPACE"

if [ "$ADMIN_EMAIL" == "" ]; then
  echo -n "Enter admin email: "
  read ADMIN_EMAIL
fi
echo "Admin email: $ADMIN_EMAIL"

if [ "$CDSW_URL" == "" ]; then
  # Login to Director to get the CDSW address
  api_login
  CDSW_URL=$(get_cdsw_url)
fi
CDSW_URL=${CDSW_URL%%/}
echo "CDSW URL:    $CDSW_URL"

function post_api() {
  local endpoint=$1
  local data=$2
  local token=${3:-}
  if [ "$token" == "" ]; then
    auth_option=""
  else
    auth_option="Authorization: Bearer $token"
  fi
  curl -X POST \
    -H "$auth_option" \
    -H "Content-Length: ${#data}" \
    -H "Content-Type: application/json" \
    --data "$data" \
    "$CDSW_URL$endpoint" 2>/dev/null
}

function patch_api() {
  local endpoint=$1
  local data=$2
  local token=${3:-}
  if [ "$token" == "" ]; then
    auth_option=""
  else
    auth_option="Authorization: Bearer $token"
  fi
  curl -X PATCH \
    -H "$auth_option" \
    -H "Content-Length: ${#data}" \
    -H "Content-Type: application/json" \
    --data "$data" \
    "$CDSW_URL$endpoint" 2>/dev/null
}

function get_api() {
  local endpoint=$1
  local token=${2:-}
  if [ "$token" == "" ]; then
    auth_option=""
  else
    auth_option="Authorization: Bearer $token"
  fi
  curl -X GET \
    -H "$auth_option" \
    "$CDSW_URL$endpoint" 2>/dev/null
}

function cdsw_api_create_user() {
  local username=$1
  local password=$2
  local fullname=$3
  local email=$4
  data='{"email":"'$email'","name":"'$fullname'","username":"'$username'","password":"'$password'","type":"user"}'
  post_api /api/v1/users "$data" > $OUTPUTS/$(date +%s).cdsw_api_create_user.$RANDOM
}

function cdsw_api_deactivate_user() {
  local token=$1
  local username=$2
  data='{"banned":true}'
  patch_api /api/v1/users/$username "$data" "$token" > $OUTPUTS/$(date +%s).cdsw_api_deactivate_user.$RANDOM
}

function cdsw_api_create_team() {
  local token=$1
  local team=$2
  data='{"type":"organization","username":"'"$team"'"}'
  post_api /api/v1/users "$data" "$token" > $OUTPUTS/$(date +%s).cdsw_api_create_team.$RANDOM
}

function cdsw_api_login() {
  local username=$1
  local password=$2
  data='{"_local":false,"login":"'$username'","password":"'$password'"}'
  post_api /api/v1/authenticate "$data" | tee $OUTPUTS/$(date +%s).cdsw_api_login.$RANDOM | grep auth_token | awk -F\" '{print $4}'
}

function cdsw_api_set_hadoop_credentials() {
  local token=$1
  local principal=$2
  local password=$3
  data='{"principal":"'$principal'","password":"'$password'","clusterId":1}'
  post_api /api/v1/users/admin/kerberos-credentials "$data" "$token" > $OUTPUTS/$(date +%s).cdsw_api_set_hadoop_credentials.$RANDOM
}

function cdsw_api_add_engine() {
  local token=$1
  local vcpus=$2
  local memory_gb=$3
  data='{"cpu":'$vcpus',"memory":'$memory_gb'}'
  post_api /api/v1/site/engine-profiles "$data" "$token" | tee $OUTPUTS/$(date +%s).cdsw_api_add_engine.$RANDOM | grep '"id"' | awk '{gsub(/,/, ""); print $NF}'
}

function cdsw_api_create_project() {
  local token=$1
  local username=$2
  local template=$3   # blank, {}, ?, git
  local visibility=$4 # private, organization (aka. Team), public
  local name=$5
  local git_url=$6    # only for git templates
  data='{"template":"'$template'","project_visibility":"'$visibility'","name":"'$name'","gitUrl":"'$git_url'"}'
  post_api /api/v1/users/$username/projects "$data" "$token" | tee $OUTPUTS/$(date +%s).cdsw_api_create_project.$RANDOM | grep '"slug"' | awk -F\" '{print $4}'

# R template: {"template":{"id":1,"name":"R","created_at":"2018-11-16T05:28:02.635Z","repository":"","built_in":true,"enabled":true,"route":"project-templates","reqParams":null,"parentResource":null,"restangularCollection":false},"project_visibility":"private","name":"TemplateR"}
# Py template: {"template":{"id":2,"name":"Python","created_at":"2018-11-16T05:28:02.635Z","repository":"","built_in":true,"enabled":true,"route":"project-templates","reqParams":null,"parentResource":null,"restangularCollection":false},"project_visibility":"private","name":"TemplatePy"}
}

function cdsw_api_create_job() {
  local token=$1
  local slug=$2
  local name=$3
  local type=$4
  local script=$5
  local timezone=$6
  local kernel=$7
  local vcpus=$8
  local memory_gb=$9
  data='{"name":"'$name'","type":"'$type'","script":"'$script'","timezone":"'$timezone'","environment":{},"kernel":"'$kernel'","cpu":'$vcpus',"memory":'$memory_gb',"nvidia_gpu":0,"notifications":[],"recipients":{},"attachments":[]}'
  post_api /api/v1/projects/$slug/jobs "$data" "$token" | tee $OUTPUTS/$(date +%s).cdsw_api_create_job.$RANDOM | grep '"id"' | head -1 | awk '{gsub(/,/, ""); print $NF}'
}

function cdsw_api_start_job() {
  local token=$1
  local slug=$2
  local job_id=$3
  data='{}'
  post_api /api/v1/projects/$slug/jobs/$job_id/start "$data" "$token" > $OUTPUTS/$(date +%s).cdsw_api_start_job.$RANDOM
}

function cdsw_api_wait_job() {
  local token=$1
  local slug=$2
  local job_id=$3
  local wait_secs=${4:-0}
  local retries=${5:-0}
  while [ $retries -gt 0 ]; do
    get_api /api/v1/projects/$slug/jobs/$job_id "$token" > $OUTPUTS/waitfile
    echo "  -> $(date) - Job status: $(grep '"status"' $OUTPUTS/waitfile | awk -F\" '{print $4}')"
    grep '"finished_at"' $OUTPUTS/waitfile > /dev/null
    if [ $? == 0 ]; then
      break
    fi
    sleep $wait_secs
    retries=$((retries-1))
  done
}

function cdsw_api_add_engine_image() {
  local token=$1
  local description=$2
  local repository=$3
  local tag=$4
  data='{"engineImage":{"description":"'$description'","tag":"'$tag'","repository":"'$repository'"}}'
  post_api /api/v1/engine-images "$data" "$token" > $OUTPUTS/$(date +%s).cdsw_api_add_engine_image.$RANDOM
}

# Create output directory for troubleshooting purposes, if necessary
mkdir -p $OUTPUTS

# Create users
cdsw_api_create_user admin cloudera "CDSW Administrator" $ADMIN_EMAIL
cdsw_api_create_user instructor cloudera "Workshop Instructor" instructor_$ADMIN_EMAIL

echo -e "\nLogin"
token=$(cdsw_api_login admin cloudera)

echo -e "\nSet Hadoop credentials"
cdsw_api_set_hadoop_credentials "$token" cdsw@HADOOPSECURITY.LOCAL Cloudera1

echo -e "\nAdd engine"
engine_id=$(cdsw_api_add_engine "$token" 2 4)
echo "  -> Engine Id: $engine_id"

#echo -e "\nCreate team"
#cdsw_api_create_team "$token" WorkshopParticipants

echo -e "\nCreate Git project for Exercise 1"
ex1_slug=$(cdsw_api_create_project "$token" admin git public "Exercise 1" "https://github.com/mikeharding/cdsw-workshop-exercise-1")
echo "  -> Project: $ex1_slug"

echo -e "\nCreate Git project for Exercise 3"
ex3_slug=$(cdsw_api_create_project "$token" admin git private "Exercise 3" "https://github.com/jordanvolz/BasketballStatsCDSW")
echo "  -> Project: $ex3_slug"

echo -e "\nRunning setup for Exercise 3"
ex3_job_id=$(cdsw_api_create_job "$token" "$ex3_slug" "Exercise 3 Setup Job" manual setup.scala America/Los_Angeles scala 2 4)
cdsw_api_start_job "$token" "$ex3_slug" $ex3_job_id
echo "  -> Job Id: $ex3_job_id"

echo -e "\nCreate Git project for Exercise 4"
ex4_slug=$(cdsw_api_create_project "$token" admin git public "US Flight Analytics" "https://github.com/jessielin2008/cdsw-flight-analytics")
echo "  -> Project: $ex4_slug"

echo -e "\nRunning setup for Exercise 4 - Python"
ex4_python_job_id=$(cdsw_api_create_job "$token" "$ex4_slug" "Exercise 4 Setup Job - Python" manual setup.py America/Los_Angeles python3 2 4)
cdsw_api_start_job "$token" "$ex4_slug" $ex4_python_job_id
echo "  -> Job Id: $ex4_python_job_id"

echo -e "\nRunning setup for Exercise 4 - R"
ex4_r_job_id=$(cdsw_api_create_job "$token" "$ex4_slug" "Exercise 4 Setup Job - R" manual setup.R America/Los_Angeles r 2 4)
cdsw_api_start_job "$token" "$ex4_slug" $ex4_r_job_id
echo "  -> Job Id: $ex4_r_job_id"

echo -e "\nAdd engine image for Exercise 6"
cdsw_api_add_engine_image "$token" "TA-lib" "jvolz/cdsw-ta-lib" "version2.1"

echo -e "\nWait for Exercise 3 setup job to finish"
cdsw_api_wait_job "$token" "$ex3_slug" $ex3_job_id 5 30
echo -e "\nWait for Exercise 4 Python setup job to finish"
cdsw_api_wait_job "$token" "$ex4_slug" $ex4_python_job_id 5 30
echo -e "\nWait for Exercise 4 R setup job to finish"
cdsw_api_wait_job "$token" "$ex4_slug" $ex4_r_job_id 30 30
