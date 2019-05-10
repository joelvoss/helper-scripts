#!/bin/bash
#
# Function to ask the user for confirmation.
# Usage: `if confirm "<Text to prepend>" ; then
#           do something on confirmation
#         else
#           do something on rejection
#         fi`

cd $(dirname $0)
set -e

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

example() {
  if confirm "<Text to prepend>" ; then
    printf "Confirmed!\n"
  else
    printf "Rejected!\n"
  fi
}
example