#!/usr/bin/env bash

VERSION="0.0.1"

DIR="${HOME}/nginx_loggar"
FZF_EXIST=$(command -v fzf)
PACKAGE_MANAGER_FLAGS=("-S" "install")
PACKAGE_MANAGERS=("apt" "pacman" "dnf" "xbps-install")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
CLEAR='\033[0m'

echo_color() {
  local CONTENT
  local COLOR
  if [[ -n ${1} ]]; then
    COLOR=${1}
  else
    echo "${RED}please specify a color${CLEAR}"
  fi

  if [[ -n ${2} ]]; then
    CONTENT=${2}
  else
    echo "${RED}please specify a message${CLEAR}" 
  fi

  echo -ne "${COLOR}${CONTENT}${CLEAR}"
}


main() {
  local INSTALL_FZF
  local PACKAGE_MANAGER_OF_CHOICE
  if [[ -z ${FZF_EXIST} ]]; then
    echo_color "${CYAN}" "fzf not found, would you like to install it?? (${GREEN}Y${CLEAR}/${RED}n${CLEAR}): "
    read -r INSTALL_FZF
    if ! [[ ${INSTALL_FZF} =~ [Nn] ]]; then
      echo_color "${CYAN}" "Pick your package manager \n"
      echo_color "${CYAN}" "The choices are: ${RED}${PACKAGE_MANAGERS[*]}${CLEAR} \n"
      echo_color "${GREEN}" "Enter package manager: " 
      read -r PACKAGE_MANAGER_OF_CHOICE
      while (true); do
        case "${PACKAGE_MANAGER_OF_CHOICE}" in
          "${PACKAGE_MANAGERS[0]}")
            "${PACKAGE_MANAGERS[0]}" "${PACKAGE_MANAGER_FLAGS[1]}" "fzf"
            break
          ;;
          "${PACKAGE_MANAGERS[1]}")
            "${PACKAGE_MANAGERS[1]}" "${PACKAGE_MANAGER_FLAGS[0]}" "fzf"
            break
          ;;
          "${PACKAGE_MANAGERS[2]}")
            "${PACKAGE_MANAGERS[2]}" "${PACKAGE_MANAGER_FLAGS[1]}" "fzf"
            break
          ;;
          "${PACKAGE_MANAGERS[3]}")
            "${PACKAGE_MANAGERS[3]}" "${PACKAGE_MANAGER_FLAGS[0]}" "fzf"
            break
          ;;
          *)
            echo "Something went wrong, or you picked an invalid package manager, please try again"
          ;;
        esac
      done
    fi
  fi
}


case "${1}" in
  "--help" | "-h" | "-?")
    echo -e "log-scanner v${BLUE}${VERSION}${CLEAR} \n"
    echo -e "Usage:"
    echo -e "--help | -h | -?"
    echo -e "Displays this message. \n"
    echo -e "--version | -v"
    echo -e "Displays script version. \n"
    echo -e "--directory | -d"
    echo -e "Sets the directory of logs you want to scan. \n"
    echo -e "Made with ${RED}<3${CLEAR} by h4rl"
  ;;
  "--version" | "-v")
    echo -e "log-scanner v${BLUE}${VERSION}${CLEAR}"
  ;;
  "--directory" | "-d")
    DIR="${2}"
    main
  ;;
  *)
    main
  ;;
esac
