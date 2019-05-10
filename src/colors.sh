#!/bin/bash

cd $(dirname $0)
set -e

# Formatting
BOLD="\e[1m"
DIM="\e[2m"
UNDERLINED="\e[4m"
INVERT="\e[7m"
RESET="\e[0m\e[39m"

# Colors (8 bit)
BLACK="\e[30m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"

# Colors (16 bit)
B_BLACK="\e[30;1m"
B_RED="\e[31;1m"
B_GREEN="\e[32;1m"
B_YELLOW="\e[33;1m"
B_BLUE="\e[34;1m"
B_MAGENTA="\e[35;1m"
B_CYAN="\e[36;1m"
B_WHITE="\e[37;1m"

# Background colors (8 bit)
BG_BLACK="\e[40m"
BG_RED="\e[41m"
BG_GREEN="\e[42m"
BG_YELLOW="\e[43m"
BG_BLUE="\e[44m"
BG_MAGENTA="\e[45m"
BG_CYAN="\e[46m"
BG_WHITE="\e[47m"

# Background colors (16 bit)
BG_B_BLACK="\e[40;1m"
BG_B_RED="\e[41;1m"
BG_B_GREEN="\e[42;1m"
BG_B_YELLOW="\e[43;1m"
BG_B_BLUE="\e[44;1m"
BG_B_MAGENTA="\e[45;1m"
BG_B_CYAN="\e[46;1m"
BG_B_WHITE="\e[47;1m"

example() {
  printf "You can use ${BOLD}colors${RESET} in your terminal!\n"
  printf "8-Bit colors:\n"
  printf "  ${RED}Red${RESET}  "
  printf "${GREEN}Green${RESET}  "
  printf "${YELLOW}Yellow${RESET}  "
  printf "${BLUE}Blue${RESET}  "
  printf "${MAGENTA}Magenta${RESET}  "
  printf "${CYAN}Cyan${RESET}  "
  printf "${WHITE}White${RESET}  "
  printf "${BLACK}Black${RESET}\n"

  printf "16-Bit colors:\n"
  printf "  ${B_RED}Bright Red${RESET}  "
  printf "${B_GREEN}Bright Green${RESET}  "
  printf "${B_YELLOW}Bright Yellow${RESET}  "
  printf "${B_BLUE}Bright Blue${RESET}  "
  printf "${B_MAGENTA}Bright Magenta${RESET}  "
  printf "${B_CYAN}Bright Cyan${RESET}  "
  printf "${B_WHITE}Bright White${RESET}  "
  printf "${B_BLACK}Bright Black${RESET}\n"

  printf "8-Bit background colors:\n"
  printf "  ${BG_RED}Red${RESET}  "
  printf "${BG_GREEN}Green${RESET}  "
  printf "${BG_YELLOW}Yellow${RESET}  "
  printf "${BG_BLUE}Blue${RESET}  "
  printf "${BG_MAGENTA}Magenta${RESET}  "
  printf "${BG_CYAN}Cyan${RESET}  "
  printf "${BG_WHITE}White${RESET}  "
  printf "${BG_BLACK}Black${RESET}\n"

  printf "16-Bit background colors:\n"
  printf "  ${BG_B_RED}Red${RESET}  "
  printf "${BG_B_GREEN}Green${RESET}  "
  printf "${BG_B_YELLOW}Yellow${RESET}  "
  printf "${BG_B_BLUE}Blue${RESET}  "
  printf "${BG_B_MAGENTA}Magenta${RESET}  "
  printf "${BG_B_CYAN}Cyan${RESET}  "
  printf "${BG_B_WHITE}White${RESET}  "
  printf "${BG_B_BLACK}Black${RESET}\n"

  printf "\n"
  printf "You can use ${BOLD}formatting${RESET} in your terminal!\n"
  printf "  ${BOLD}Bold${RESET}  "
  printf "${DIM}Dim${RESET}  "
  printf "${UNDERLINED}Underlined${RESET}  "
  printf "${INVERT}Invert${RESET}\n"
}
example