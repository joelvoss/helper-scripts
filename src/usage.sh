#!/bin/bash

cd $(dirname $0)
set -e

die() {
  local _ret=$2
  test -n "$_ret" || _ret=1
  test "$_PRINT_HELP" = yes && print_help >&2
  echo "$1" >&2
  exit ${_ret}
}

begins_with_short_option() {
  local first_option all_short_options
  all_short_options='h'
  first_option="${1:0:1}"
  test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

print_help () {
  printf "Usage script. Version x.x.x\n"
  printf "\n"
  printf "Script name and description\n"
  printf "\n"
  printf 'Usage: %s [-h|--help]\n' "$0"
  printf "\n"
  printf "Options:\n"
  printf '  -h,--help:\tPrints help\n'
}

parse_commandline ()
{
  while test $# -gt 0
  do
    _key="$1"
    case "$_key" in
      -h|--help)
        print_help
        exit 0
        ;;
      -h*)
        print_help
        exit 0
        ;;
      *)
        _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
        ;;
    esac
    shift
  done
}

parse_commandline "$@"