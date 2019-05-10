#!/bin/bash
#
# Function to get the project root by looking up the file tree
# for a filename. In our case the package.json.
#
# Usage: `findUp <file-to-find> <max-dirs-up>`
#   → max-dirs-up: Defaults to "2"
#

cd $(dirname $0)
set -e

findUp() {
  steps=0
  maxSteps=${2:-2}
  x=`pwd`
  while [ "$x" != "/" ] && [ $steps -le $maxSteps ] ; do
      found=$(find "$x" -maxdepth 1 -name $1 | sed 's|/[^/]*$||')
      if [[ ! -z $found ]]; then
        echo $found
        break
      else
        x=`dirname "$x"`
        ((steps++))
      fi
  done
}

example() {
  printf "Looking for package.json up the directory tree...\n"
  pathToPkg=$(findUp package.json)
  if [ ! -z "$pathToPkg" ]; then
    printf "Found! package.json inside \"$pathToPkg\"\n"
  else
    printf "Not found!\n"
  fi
  
  printf "\n"

  pathToMissingFile="$(findUp missing-file.txt 2)"
  if [ ! -z "$pathToMissingFile" ]; then
    printf "Found! missing-file.txt inside \"$pathToMissingFile\"\n"
  else
    printf "Not found!\n"
  fi
}
example