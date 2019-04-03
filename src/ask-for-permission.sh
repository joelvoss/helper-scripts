#!/bin/bash

cd $(dirname $0)
set -e

confirm() {
  # call with a prompt string or use a default
  read -r -p "$1 Are you sure? [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
      true
      ;;
    *)
      false
      ;;
  esac
}

if confirm "Next task needs your permission." ; then
  printf "Success! \n"
  exit 0
else
  printf "Sad :( \n"
fi
