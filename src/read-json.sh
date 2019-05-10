#!/bin/bash
#
# Function that uses python to parse a json file and return a specified key.
# Dot notation for keys is possible.
#
# Usage: readJson <path-to-json> <key>
#

cd $(dirname $0)
set -e

readJson() {
  # Make sure python is installed
  pyv="$(python -V 2>&1)"
  if [[ -z $pyv ]]; then
    echo "No Python!"
    exit 0
  fi

  # Create python command that will be executed to modify JSON
  read -d '' pyCmd << EOF || true
import json
import sys
import io
from collections import OrderedDict

def nested_get(dataDict, mapList):    
    for k in mapList: dataDict = dataDict[k]
    return dataDict

with io.open(sys.argv[1], encoding='utf-8', mode='r') as jsonFile:
    data = json.load(jsonFile, object_pairs_hook=OrderedDict)
    key = sys.argv[2].split('.')
    print(nested_get(data, key))
EOF

  # Execute python script
  python -c "$pyCmd" "$1" "$2"
}

example() {
  printf "Reading 'version' and 'deep.nested.key' from '../mocks/mock.json'\n"

  version=$(readJson ../mocks/mock.json version)
  nestedKey=$(readJson ../mocks/mock.json deep.nested.key)

  printf "version: $version\n"
  printf "deep.nested.key: $nestedKey\n"
}
example