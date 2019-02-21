#!/bin/bash
# This script performs a deployment to Google Cloud App Engine.

set -e
cd "$(dirname "$0")"

# Helper
# Print usage info
printUsageInfo() {
    cat <<EOF

Usage: $0

EOF
}

# Helper
# Wait for user input and exit if neccessary
shouldContinue() {
  printf " Are you sure? [y/N]: "
  read COND
  # Lowercase user input
  COND=$(echo "$COND" | tr '[:upper:]' '[:lower:]')

  if [[ -z $COND || $COND == "n" ]]; then
    return 0
  fi
  return 1
}

# Helper
# Read value from json
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

# Check, if an app.yaml is present
if [ ! -f ../app.yaml ]; then
    echo "Missing app.yaml. Cancel deployment."
    exit 1
fi

# Get current version from package.json
PACKAGE_VERSION=`readJson ../package.json version`
IFS='.' read -r -a SEMVER <<< "$PACKAGE_VERSION"

# Get app name from package.json
APP_NAME=`readJson ../package.json name`

printf "[DEPLOY] Setup deployment for version $PACKAGE_VERSION. (read from package.json)"
if shouldContinue; then
  echo "[DEPLOY] Deployment cancelled"
  exit 1
fi

printf "[DEPLOY] In what GCP project should be deployed?: "
read PROJECT_ID

printf "[DEPLOY] Starting deployment of \"$APP_NAME\" in version \"$PACKAGE_VERSION\" to \"$PROJECT_ID\"."
if shouldContinue; then
  echo "[DEPLOY] Deployment cancelled"
  exit 1
fi

echo "[DEPLOY] Set-up authentication..."
gcloud auth login

echo "[DEPLOY] Execute clean-up task..."
npm run clean

echo "[DEPLOY] Execute gcloud deployment..."
gcloud app deploy ../app.yaml --version=${SEMVER[0]}-${SEMVER[1]}-${SEMVER[2]} --project=$APP_NAME
