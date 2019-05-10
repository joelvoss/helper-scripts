#!/bin/bash
#
# Function that uses python to modify a given json file.
# Dot notation for keys is possible.
#
# Usage: modifyJson <path-to-json> <key> <value>
#

cd $(dirname $0)
set -e

modifyJson() {
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

def nested_set(dic, keys, value):
    for key in keys[:-1]:
        dic = dic.setdefault(key, {})
    dic[keys[-1]] = value

with io.open(sys.argv[1], encoding='utf-8', mode='r+') as jsonFile:
    data = json.load(jsonFile, object_pairs_hook=OrderedDict)
    key = sys.argv[2].split('.')
    nested_set(data, key, sys.argv[3])
    jsonFile.seek(0)
    jsonFile.write(unicode(json.dumps(data, ensure_ascii=False, indent=2)))
    jsonFile.truncate()
EOF

  # Execute python script
  python -c "$pyCmd" "$1" "$2" "$3"
}

example() {
  printf "Modifying 'version' and 'deep.nested.key' in '../mocks/mock.json'\n"

  modifyJson ../mocks/mock.json version 1.0.0
  modifyJson ../mocks/mock.json deep.nested.key "New value"

  printf "cat ../mocks/mock.json\n"
  cat ../mocks/mock.json
  printf "\n"
}
example