#!/bin/bash

cd $(dirname $0)
set -e

BOLD="\e[1m"
CYAN="\e[36m"
RESET="\e[0m\e[39m"

function help () {
  printf "\n"
  printf " ${*}\n"
  printf "\n"
  printf "${BOLD}Usage:${RESET}\n"
  printf "  ${usage:-No usage available}\n"
  printf "\n"

  if [[ "${helptext:-}" ]]; then
    printf " ${helptext}\n"
    printf "\n"
  fi

  exit 1
}

# Usage
read -r -d '' usage <<-'EOF' || true
  -l --line  [arg] Line to process.
  -t --temp  [arg] Location of tempfile. Default="/tmp/bar"
  -1 --one         Do just one thing. Required.
  -h --help        This page
EOF

# Helptext
read -r -d '' helptext <<-'EOF' || true
 This is Bash3 Boilerplate's help text. Feel free to add any description of your
 program or elaborate more on command-line arguments. This section is not
 parsed and will be added as-is to the help.
EOF

# Translate usage string -> getopts arguments, and set $arg_<flag> defaults
while read -r tmp_line; do
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
  while getopts "${tmp_opts}" tmp_opt; do
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

  help "Option -${tmp_opt_short}${tmp_opt_long:-} requires an argument."
done

# Cleanup Environment variables
for tmp_varname in ${!tmp_*}; do
  unset -v "${tmp_varname}"
done
unset -v tmp_varname

# Help mode
if [[ "${arg_h:?}" = "1" ]]; then
  # Help exists with code 1
  help "Help using ${0}"
fi

if [[ "${arg_h:?}" = "0" ]]; then
   help "Flag -1 (--one) is required."
fi