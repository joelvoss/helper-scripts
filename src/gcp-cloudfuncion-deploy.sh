#!/bin/bash
#
# This script helps to simplify the deployment process by adding important 
# deployment relevant parameters to the `gcloud functions deploy` call.
# It depends on a package.json to mark the root folder of the application.
# In addition you can place a .env file in the root folder to set those
# environment specific parameters.
#

cd $(dirname $0)
set -e

RESET="\e[0m\e[39m"
BOLD="\e[1m"
DIM="\e[2m"
CYAN="\e[36m"
GREEN="\e[32m"
RED="\e[31m"

# Helper function to get the project root by looking up the file tree
# for a filename. In our case the package.json.
# Usage: `findUp package.json`
findUp() {
  x=`pwd`
  while [ "$x" != "/" ] ; do
      found=$(find "$x" -maxdepth 1 -name $1 | sed 's|/[^/]*$||')
      if [[ ! -z $found ]]; then
        echo $found
        break
      else
        x=`dirname "$x"`
      fi
  done
}

# Helper function to ask the user for confirmation.
# Usage: `if confirm "<Text to prepend>" ; then
#           do something on confirmation
#         else
#           do something on rejection
#         fi`
confirm() {
  read -r -p "$1 Are you sure? (y/N) " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
      true
      ;;
    *)
      false
      ;;
  esac
}

# Helper function to read properties from json files.
# In particular the package.json
# Usage: `readJson <path-to-json> <key>`
readJson() {  
  UNAMESTR=`uname`
  if [[ "$UNAMESTR" == 'Linux' ]]; then
    SED_EXTENDED='-r'
  elif [[ "$UNAMESTR" == 'Darwin' ]]; then
    SED_EXTENDED='-E'
  fi; 

  VALUE=`grep -m 1 "\"${2}\"" ${1} | sed ${SED_EXTENDED} 's/^ *//;s/.*: *"//;s/",?//'`

  if [ ! "$VALUE" ]; then
    echo "Error: Cannot find \"${2}\" in ${1}" >&2;
    exit 1;
  else
    echo $VALUE ;
  fi; 
}

# Navigate into the root so the gcloud deploy command finds
# our cloud function.
cd $(findUp package.json)

# Script starts here...
printf $GREEN$BOLD"Deployment script$RESET$DIM v1.0.0"$RESET"\n\n"

# Get package name from package.json
GCF_NAME=`readJson package.json name`
printf "  Parsed GCF name: "$CYAN"$GCF_NAME"$RESET"\n"

# Parse .env file
if [ ! -f .env ]; then
  printf $RED"Error!"$RESET"\n"
  printf "  Could not find $CYAN.env file!"$RESET"\n"
  exit 1
else
  # Grep env variables
  while IFS= read -r line
  do
    echo "$line"
  done < .env

  # GOOGLE_CLOUD_PROJECT=$(grep GOOGLE_CLOUD_PROJECT .env | cut -d '=' -f2)
  # SERVICE_ACCOUNT_EMAIL=$(grep SERVICE_ACCOUNT_EMAIL .env | cut -d '=' -f2)
  # ENTRY_POINT=$(grep ENTRY_POINT .env | cut -d '=' -f2)
  # printf "  Parsed "$CYAN".env "$RESET"file\n"
  # printf "    GOOGLE_CLOUD_PROJECT: $CYAN$GOOGLE_CLOUD_PROJECT"$RESET"\n"
  # printf "    SERVICE_ACCOUNT_EMAIL: $CYAN$SERVICE_ACCOUNT_EMAIL"$RESET"\n"
  # printf "    CORS_ALLOW_ORIGIN: $CYAN$CORS_ALLOW_ORIGIN"$RESET"\n"
  # printf "    ENTRY_POINT: $CYAN$ENTRY_POINT"$RESET"\n"
  # printf "\n"
fi

exit 0

# Define deployment variables
RUNTIME="nodejs8"
REGION="europe-west1"
MEMORY="128MB"
TIMEOUT="5"

printf "  Starting deployment with the follow configuration:\n"
printf "    project: "$CYAN"$GOOGLE_CLOUD_PROJECT"$RESET"\n"
printf "    runtime: "$CYAN"$RUNTIME"$RESET"\n"
printf "    region: "$CYAN"$REGION"$RESET"\n"
printf "    entry-point: "$CYAN"$ENTRY_POINT"$RESET"\n"
printf "    memory: "$CYAN"$MEMORY"$RESET"\n"
printf "    timeout: "$CYAN"$TIMEOUT"$RESET"\n"
printf "    service-account: "$CYAN"$SERVICE_ACCOUNT_EMAIL"$RESET"\n"
printf "    env-vars: "$CYAN"GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT"$RESET"\n"
printf "              "$CYAN"CORS_ALLOW_ORIGIN=$CORS_ALLOW_ORIGIN"$RESET"\n"
printf "\n"
if confirm " " ; then
  gcloud auth login
  gcloud config set project $GOOGLE_CLOUD_PROJECT

  # Deploy function to gcp
  # Region europe-west1 => Belgien
  # Region europe-west3 => Frankfurt (is not available)
  gcloud functions deploy $GCF_NAME \
    --runtime $RUNTIME \
    --region $REGION \
    --entry-point $ENTRY_POINT \
    --memory $MEMORY \
    --timeout $TIMEOUT \
    --trigger-http \
    ${SERVICE_ACCOUNT_EMAIL:+--service-account $SERVICE_ACCOUNT_EMAIL} \
    --set-env-vars "GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT,CORS_ALLOW_ORIGIN=$CORS_ALLOW_ORIGIN"

  printf $GREEN$BOLD"Success!"$RESET"\n"
  exit 0
else
  printf $RED"Deployment canceled!"$RESET"\n"
  exit 0
fi
