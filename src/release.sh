#!/bin/bash
# This script performs a patch/minor/major release by executing the following
# steps:
#   - Sets the versions and commits the changes as a release commit
#   - Merges the release commit to master and tags it with the specific
#     version
#   - Sets the versions to the next development version and commits them
#     to develop
#
# Attention: Pushing the changes to a remote repository is not covered by
# the script to avoid disasters.

printUsageInfo() {
    cat <<EOF

Usage: $0 [-p || -m || -M]

  -p (--patch)
    Perform a patch release.
    Example: 0.1.0 --> 0.1.1

  -m (--minor)
    Peform a minor release.
    Example: 0.1.3 --> 0.2.0

  -M (--major)
    Perform a major release.
    Example: 0.13.1 --> 1.0.0

EOF
}

set -e
cd "$(dirname "$0")"

# Check if we are on develop.
if [ "$(git rev-parse --abbrev-ref HEAD)" != "develop" ]; then
  echo "Needs to be executed on develop branch"
  printUsageInfo
  exit 1
fi

# Check if only one flag is present.
if [ "$#" -gt 1 ]; then
  echo "Only one flag allowed!"
  printUsageInfo
  exit 1
fi

# Get current version from package.json
PACKAGE_VERSION=$(cat ../package.json \
  | grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[",\t ]//g')
IFS='.' read -r -a SEMVER <<< "$PACKAGE_VERSION"

# Set release and development versions based on flags.
case $1 in
  -p|--patch)
    TYPE="patch"
    releaseVersion=$(printf "${SEMVER[0]}.${SEMVER[1]}.$((${SEMVER[2]} + 1))")
    ;;
  -m|--minor)
    TYPE="minor"
    releaseVersion=$(printf "${SEMVER[0]}.$((${SEMVER[1]} + 1)).0")
    ;;
  -M|--major)
    TYPE="major"
    releaseVersion=$(printf "$((${SEMVER[0]} + 1)).0.0")
    ;;
  *)
    printUsageInfo
    exit 1
    ;;
esac

echo "[RELEASE] Starting $TYPE-release process for version $releaseVersion (from current dev version: $PACKAGE_VERSION)"

# Commit new release version
echo "[RELEASE] Commit new release version..."
npm version --no-git-tag-version "$releaseVersion"
git add ../package.json ../package-lock.json
git commit -m "release version: $releaseVersion"

# Merge to master + tag
echo "[RELEASE] Merging to master and tagging..."
git checkout master
git merge develop
git tag -a -m "release version: $releaseVersion" $releaseVersion

# Checkout develop
echo "[RELEASE] Setting and committing next dev version..."
git checkout develop

echo "[RELEASE] Release performed successfully. Please review the changes and push them manually."