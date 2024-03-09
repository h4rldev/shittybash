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
    echo_color "${RED}" "please specify a color"
  fi

  if [[ -n ${2} ]]; then
    CONTENT=${2}
  else
    echo_color "${RED}" "please specify a message"
  fi

  echo -ne "${COLOR}${CONTENT}${CLEAR}"
}

navigate_dir() {
  local IS_FZF_ENABLED
  local ENTRY
  local -a FILES 
  local PROMPT

  PROMPT="Select file: "
  IS_FZF_ENABLED=${1}
  
  if [[ $IS_FZF_ENABLED == "true" ]]; then
    ENTRY=$(find ${DIR} -type f -print 2> /dev/null | fzf --layout=reverse --prompt="${PROMPT}" --preview 'cat {}')
    echo ${ENTRY}
  else 
    PS3="${PROMPT}"
    readarray -t FILES < <(find ${DIR} -type f -print 2> /dev/null)
    select OPT in ${FILES[@]}; do
      if [[ -z ${OPT} ]]; then
        echo_color "${RED}"  "Invalid choice, please try again. \n" >&2
       else
        echo_color "${CYAN}" "You selected ${opt} \n" >&2
        echo ${OPT}
        break
      fi
    done
  fi
}

check_for_fzf() {
  local INSTALL_FZF
  local PACKAGE_MANAGER_OF_CHOICE
  local ENABLE_FZF

  if [[ -z ${FZF_EXIST} ]]; then
    echo_color "${CYAN}" "fzf not found, would you like to install it? (${GREEN}Y${CLEAR}/${RED}n${CLEAR}): " >&2
    read -r INSTALL_FZF
    if ! [[ ${INSTALL_FZF} =~ [Nn] ]]; then
      while true; do
        echo_color "${CYAN}"  "Pick your package manager \n" >&2
        echo_color "${CYAN}"  "The choices are: ${RED}${PACKAGE_MANAGERS[*]}${CLEAR} \n" >&2
        echo_color "${GREEN}" "Enter package manager: " >&2
        read -r PACKAGE_MANAGER_OF_CHOICE

        case "${PACKAGE_MANAGER_OF_CHOICE}" in
          "${PACKAGE_MANAGERS[0]}")
            sudo "${PACKAGE_MANAGERS[0]}" "${PACKAGE_MANAGER_FLAGS[1]}" "fzf"
            break
          ;;
          "${PACKAGE_MANAGERS[1]}")
            sudo "${PACKAGE_MANAGERS[1]}" "${PACKAGE_MANAGER_FLAGS[0]}" "fzf"
            break
          ;;
          "${PACKAGE_MANAGERS[2]}")
            sudo "${PACKAGE_MANAGERS[2]}" "${PACKAGE_MANAGER_FLAGS[1]}" "fzf"
            break
          ;;
          *)
            echo_color "${RED}" "Something went wrong, or you picked an invalid package manager, please try again" >&2
          ;;
        esac
      done
    fi
  fi
  if [[ -n ${FZF_EXIST} ]]; then
    echo_color "${CYAN}" "You have fzf installed. \nDo you want to use it? (${GREEN}Y${CLEAR}/${RED}n${CLEAR}): " >&2
    read -r ENABLE_FZF
  
    if [[ ${ENABLE_FZF} =~ [Nn] ]]; then
      echo false
      return
    fi
    echo true
  fi
}

filter() {
  local -a LEVELS
  local LEVEL
  local PROMPT
  local FILE1
  local FILE2
  local IS_FZF_ENABLED
  local LAST_TIME
  local LAST_EPOCH
  local TEN_SECONDS_BEFORE
  local NEW_TIME
  local NEW_TIME_TEN_SECONDS_AGO
  local RESULT

  PROMPT="Select logging level: "
  
  if [[ -n ${1} ]]; then
    FILE1=${1}
  else
    echo_color "${RED}" "please specify FILE1"
  fi

  if [[ -n ${2} ]]; then
    FILE2=${2}
  else
    echo_color "${RED}" "please specify FILE2"
  fi

  if [[ -n ${3} ]]; then
    IS_FZF_ENABLED=${3}
  else
    IS_FZF_ENABLED=false
  fi

  LEVELS=("emerg" "alert" "crit" "error" "warn" "notice" "info" "debug")
  
  if [[ ${IS_FZF_ENABLED} == true ]]; then
    LEVEL=$(printf "%s\n" "${LEVELS[@]}" | fzf --layout=reverse --prompt="${PROMPT}" --preview="grep {} ${FILE1}")
  else
    PS3="${PROMPT}"
    select OPT in ${LEVELS[@]}; do
      if [[ -z $OPT ]]; then
        echo_color "$RED" "Invalid choice, please try again"
      else
        LEVEL=${OPT}
        break
      fi
    done
  fi

  LAST_TIME=$(grep "${LEVEL}" "${FILE1}" | tail -n  1 | awk -F'[][]' '{print $1}')
  LAST_TIME="${LAST_TIME%%}"
  echo "Last time: ${LAST_TIME}"

  # Convert the timestamp to Unix epoch time
  LAST_EPOCH=$(date -d "${LAST_TIME}" +%s)
  echo "Last epoch: ${LAST_EPOCH}"

  # Calculate the timestamp  10 seconds before the last "warn" entry
  TEN_SECONDS_BEFORE=$(date -d "@$((${LAST_EPOCH} -  10))" +"%Y/%m/%d %H:%M:%S")  
  echo "Timestamp 10 seconds before: $TEN_SECONDS_BEFORE"
  NEW_TIME=$(echo ${LAST_TIME} | awk '{split($0,a," "); split(a[1],b,"/"); printf "%02d/%s/%04d:%s\n", b[3], b[2], b[1], a[2]}')
  NEW_TIME=$(echo ${NEW_TIME} | awk '{
    split($0,a,"/");
    month_map["01"]="Jan";
    month_map["02"]="Feb";
    month_map["03"]="Mar";
    month_map["04"]="Apr";
    month_map["05"]="May";
    month_map["06"]="Jun";
    month_map["07"]="Jul";
    month_map["08"]="Aug";
    month_map["09"]="Sep";
    month_map["10"]="Oct";
    month_map["11"]="Nov";
    month_map["12"]="Dec";
    a[2]=month_map[a[2]];
    gug=" +0000";
    print a[1] "/" a[2] "/" a[3] a[4] gug;
  }')
  NEW_TIME_TEN_SECONDS_AGO=$(echo $TEN_SECONDS_BEFORE | awk '{split($0,a," "); split(a[1],b,"/"); printf "%02d/%s/%04d:%s\n", b[3], b[2], b[1], a[2]}')
  NEW_TIME_TEN_SECONDS_AGO=$(echo $NEW_TIME_TEN_SECONDS_AGO | awk '{
    split($0,a,"/");
    month_map["01"]="Jan";
    month_map["02"]="Feb";
    month_map["03"]="Mar";
    month_map["04"]="Apr";
    month_map["05"]="May";
    month_map["06"]="Jun";
    month_map["07"]="Jul";
    month_map["08"]="Aug";
    month_map["09"]="Sep";
    month_map["10"]="Oct";
    month_map["11"]="Nov";
    month_map["12"]="Dec";
    a[2]=month_map[a[2]];
    gug=" +0000";
    print a[1] "/" a[2] "/" a[3] a[4] gug;
  }')
  echo "${NEW_TIME}"
  echo "${NEW_TIME_TEN_SECONDS_AGO}"

  RESULT=$(awk -v start_time="$NEW_TIME_TEN_SECONDS_AGO" -v end_time="$NEW_TIME" \
  'function parse_timestamp(line) {
    match(line, /([0-9]{2})\/([A-Za-z]{3})\/([0-9]{4}):([0-9]{2}):([0-9]{2}):([0-9]{2})/)
    day = $1
    month = $2
    year = $3
    time = $4 ":" $5 ":" $6

    # Create an associative array for month names
    split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month_array, " ")
    for (i in month_array) {
        month_map[month_array[i]] = i + 1
    }

    # Replace the month name with its numeric equivalent
    month_num = month_map[month]

    # Format the timestamp
    ts = sprintf("%02d/%02d/%04d %s", day, month_num, year, time)

    # Convert the timestamp to Unix epoch time
    time_maketh = mktime(ts)
    return time_maketh
  }
  {
    ts = parse_timestamp($0)
    print "ts:" ts
    if (ts >= start && ts <= end) {
        print $0
    }
  }' "$FILE2")
  echo "$RESULT"
}




main() {
  shopt -s nullglob # prevent errors when no files are found

  local IS_FZF_ENABLED
  local FILE_TO_FILTER
  local COMPARISON_FILE

  IS_FZF_ENABLED=$(check_for_fzf) 
  echo_color "${CYAN}" "Checking ${DIR}\n"
  sleep 0.5

  FILE_TO_FILTER=$(navigate_dir "$IS_FZF_ENABLED")
  COMPARISON_FILE=$(navigate_dir "$IS_FZF_ENABLED")
  
  filter "$FILE_TO_FILTER" "$COMPARISON_FILE" "$IS_FZF_ENABLED"
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
