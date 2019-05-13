#!/bin/bash

cd $(dirname $0)
set -e

RESET="\e[0m\e[39m"
BOLD="\e[1m"
DIM="\e[2m"
CYAN="\e[36m"
MAGENTA="\e[35m"
RED="\e[31m"

# Usage
read -r -d '' usage <<-EOF || true
  ${CYAN}-t --type${RESET}  ${MAGENTA}[arg]${RESET}  Release-Type. One of "patch", "minor" or "major". Default=patch
  ${CYAN}-f --file${RESET}  ${MAGENTA}[arg]${RESET}  File to get/set version number from/to. Default=package.json
  ${CYAN}-h --help${RESET}         This page.
EOF

# Helptext
read -r -d '' helptext <<-EOF || true
 This script must be executed from the "develop" branch.
 We support the following release types and version files.
 
 Release types:
  1) ${CYAN}patch${RESET} ${DIM}(0.0.1 --> 0.0.2)${RESET}
  2) ${CYAN}minor${RESET} ${DIM}(0.0.1 --> 0.1.0)${RESET}
  3) ${CYAN}major${RESET} ${DIM}(0.0.1 --> 1.0.0)${RESET}

 Version files:
  1) ${CYAN}package.json${RESET}
  2) ${CYAN}pom.xml${RESET}
EOF

# Prints usage and helptext informations.
# Optionally you can prepend own text, e.g. errors.
help () {
  printf "\n"
  printf " ${*}\n"
  printf "\n"
  printf "${BOLD}Usage:${RESET} $0 ${CYAN}[--option] ${MAGENTA}[arg]${RESET}\n"
  printf "\n"
  printf "${BOLD}Options:${RESET}\n"
  printf "  ${usage:-No usage available}\n"
  printf "\n"

  if [[ "${helptext:-}" ]]; then
    printf " ${helptext}\n"
    printf "\n"
  fi

  exit 1
}

error() {
  printf "\n"
  printf "${BOLD}Error:${RESET}\n"
  printf " ${*}"  
  help ""
  
  exit 1
}

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

# Parse usage string
# Translate usage string ➞ getopts arguments, and set $arg_<flag> defaults.
while read -r tmp_line; do
  # Remove ANSI escape sequences.
  tmp_line=$(echo ${tmp_line} | sed 's/\\e\[[0-9;]*[a-zA-Z]//g')

  if [[ "${tmp_line}" =~ ^- ]]; then
    # Fetch single character version of option string
    tmp_opt="${tmp_line%% *}"
    tmp_opt="${tmp_opt:1}"

    # Fetch long version if present
    tmp_long_opt=""
    if [[ "${tmp_line}" = *"--"* ]]; then
      tmp_long_opt="${tmp_line#*--}"
      tmp_long_opt="${tmp_long_opt%% *}"
    fi

    # Map opt long name to/from opt short name
    printf -v "tmp_opt_long2short_${tmp_long_opt//-/_}" '%s' "${tmp_opt}"
    printf -v "tmp_opt_short2long_${tmp_opt}" '%s' "${tmp_long_opt//-/_}"

    # Check if option takes an argument
    if [[ "${tmp_line}" =~ \[.*\] ]]; then
      # Add ":" if opt has arg
      tmp_opt="${tmp_opt}:" 
      # It has an arg. Init with ""
      tmp_init=""  
      printf -v "tmp_has_arg_${tmp_opt:0:1}" '%s' "1"
    elif [[ "${tmp_line}" =~ \{.*\} ]]; then
      tmp_opt="${tmp_opt}:"
      tmp_init=""
      # Remember that this option requires an argument
      printf -v "tmp_has_arg_${tmp_opt:0:1}" '%s' "2"
    else
      # Opt is a flag. Init with 0
      tmp_init="0"
      printf -v "tmp_has_arg_${tmp_opt:0:1}" '%s' "0"
    fi
    tmp_opts="${tmp_opts:-}${tmp_opt}"
  fi

  [[ "${tmp_opt:-}" ]] || continue

  if [[ "${tmp_line}" =~ ^Default= ]] || [[ "${tmp_line}" =~ \.\ *Default= ]]; then
    # Ignore default value if option does not have an argument
    tmp_varname="tmp_has_arg_${tmp_opt:0:1}"

    if [[ "${!tmp_varname}" != "0" ]]; then
      tmp_init="${tmp_line##*Default=}"
      tmp_re='^"(.*)"$'
      if [[ "${tmp_init}" =~ ${tmp_re} ]]; then
        tmp_init="${BASH_REMATCH[1]}"
      else
        tmp_re="^'(.*)'$"
        if [[ "${tmp_init}" =~ ${tmp_re} ]]; then
          tmp_init="${BASH_REMATCH[1]}"
        fi
      fi
    fi
  fi

  if [[ "${tmp_line}" =~ ^Required\. ]] || [[ "${tmp_line}" =~ \.\ *Required\. ]]; then
    # Remember that this option requires an argument
    printf -v "tmp_has_arg_${tmp_opt:0:1}" '%s' "2"
  fi

  printf -v "arg_${tmp_opt:0:1}" '%s' "${tmp_init}"
done <<< "${usage:-}"

# Run getopts only if options were specified in usage
if [[ "${tmp_opts:-}" ]]; then
  # Allow long options like --this
  tmp_opts="${tmp_opts}-:"

  # Reset in case getopts has been used previously in the shell.
  OPTIND=1

  # Start parsing command line.
  # Unexpected arguments will cause unbound variables to be dereferenced.
  set +o nounset
  # Overwrite $arg_<flag> defaults with the actual CLI options
  while getopts ${tmp_opts} tmp_opt; do
    [[ "${tmp_opt}" = "?" ]] && help "Invalid use of script: ${*} "

    if [[ "${tmp_opt}" = "-" ]]; then
      # OPTARG is long-option-name or long-option=value
      if [[ "${OPTARG}" =~ .*=.* ]]; then
        # --key=value format
        tmp_long_opt=${OPTARG/=*/}
        # Set opt to the short option corresponding to the long option
        tmp_varname="tmp_opt_long2short_${tmp_long_opt//-/_}"
        printf -v "tmp_opt" '%s' "${!tmp_varname}"
        OPTARG=${OPTARG#*=}
      else
        # --key value format
        # Map long name to short version of option
        tmp_varname="tmp_opt_long2short_${OPTARG//-/_}"
        printf -v "tmp_opt" '%s' "${!tmp_varname}"
        # Only assign OPTARG if option takes an argument
        tmp_varname="tmp_has_arg_${tmp_opt}"
        tmp_varvalue="${!tmp_varname}"
        [[ "${tmp_varvalue}" != "0" ]] && tmp_varvalue="1"
        printf -v "OPTARG" '%s' "${@:OPTIND:${tmp_varvalue}}"
        # Shift over the argument if argument is expected
        ((OPTIND+=tmp_varvalue))
      fi
      # we have set opt/OPTARG to the short value and the argument as OPTARG if it exists
    fi
    tmp_varname="arg_${tmp_opt:0:1}"
    tmp_default="${!tmp_varname}"

    tmp_value="${OPTARG}"
    if [[ -z "${OPTARG}" ]]; then
      tmp_value=$((tmp_default + 1))
    fi

    printf -v "${tmp_varname}" '%s' "${tmp_value}"
  done
  # No more unbound variable references expected
  set -o nounset

  shift $((OPTIND-1))

  if [[ "${1:-}" = "--" ]] ; then
    shift
  fi
fi

# Automatic validation of required option arguments.
for tmp_varname in ${!tmp_has_arg_*}; do
  # validate only options which required an argument
  [[ "${!tmp_varname}" = "2" ]] || continue

  tmp_opt_short="${tmp_varname##*_}"
  tmp_varname="arg_${tmp_opt_short}"
  [[ "${!tmp_varname}" ]] && continue

  tmp_varname="tmp_opt_short2long_${tmp_opt_short}"
  printf -v "tmp_opt_long" '%s' "${!tmp_varname}"
  [[ "${tmp_opt_long:-}" ]] && tmp_opt_long=" (--${tmp_opt_long//_/-})"

  help "${BOLD}Error:${RESET} Option -${tmp_opt_short}${tmp_opt_long:-} requires an argument."
done

# Cleanup tmp environment variables.
for tmp_varname in ${!tmp_*}; do
  unset -v "${tmp_varname}"
done
unset -v tmp_varname

if [[ "${arg_h:?}" = "1" ]]; then
  # Help exists with code 1
  help "Help using ${0}"
fi

# # Validate active git branch
# if [[ "$(git rev-parse --abbrev-ref HEAD)" != "develop" ]]; then
#   error "Not on branch \"${CYAN}develop${RESET}\"."
# fi

# Get current version from package.json
VERSION_FILE=$(findUp ${arg_f})
VERSION=$(readJson ${VERSION_FILE}/${arg_f} version)
IFS='.' read -r -a SEMVER <<< "${VERSION}"

# Set new semver number
case ${arg_t} in
  patch)
    printf -v "NEW_VERSION" '%s.%s.%s' ${SEMVER[0]} ${SEMVER[1]} $((${SEMVER[2]} + 1))
    ;;
  minor)
    printf -v "NEW_VERSION" '%s.%s.0' "${SEMVER[0]}" "$((${SEMVER[1]} + 1))"
    ;;
  major)
    printf -v "NEW_VERSION" '%s.0.0' "$((${SEMVER[0]} + 1))"
    ;;
  *)
    error "-t (--type) argument must be one of \"patch\", \"minor\" or \"major\""
    ;;
esac


printf "Cutting ${CYAN}${arg_t}${RESET} release. ${DIM}(${VERSION} --> ${NEW_VERSION})${RESET}\n"

# Commit new release version
printf "Commit new release version..."
exit 0
modifyJson ${VERSION_FILE}/${arg_f} version ${NEW_VERSION}
git add ${VERSION_FILE}/${arg_f}
git commit -m "Cut release ${NEW_VERSION}"
printf "done.\n"

# Merge to master + tag
printf "[RELEASE] Merging to master and tagging...\n"
git checkout master
git merge develop
git tag -a -m "Cut release ${NEW_VERSION}" ${NEW_VERSION}

# Checkout develop
printf "[RELEASE] Setting and committing next dev version...\n"
git checkout develop

printf "[RELEASE] Release performed successfully. Please review the changes and push them manually.\n"