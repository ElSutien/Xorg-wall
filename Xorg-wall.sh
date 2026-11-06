#!/bin/bash

VERSION=0.1
RELEASE_DATE=06/11/2026
AUTHOR=ElSutien



# FUNCTION Print an error message to stderr with color
# Parameters:
#   - 1+: str Message to print
# Stderr: Printed message with colors
# Date: 30/10/20226
perror () {
  [ -t 2 ] && local CNC="\033[0m" CRED="\033[1;31m" || local CNC= CRED=
  echo -e "${CRED}ERROR: ${@}${CNC}" 1>&2
}

# FUNCTION Print an error message to stderr with color and terminate execution
# Parameters:
#   - 1 : str Message to print
#   - 2 : int Error code to return
# Return: specified error code in parameters
# Stderr: Printed message with colors
# Date: 06/11/20226
die () {
  [ -t 2 ] && local CNC="\033[0m" CRED="\033[1;31m" || local CNC= CRED=
  echo -e "${CRED}ERROR: ${1}${CNC}" 1>&2
  [ -z "$2" ] && exit 1 || exit ${2}
}


# FUNCTION Get all display sessions available
# Return: 0 if success; 1 if no user found
# Stdout: List of diplays in touples of (user display)
getAllDisplays () {
  local data
  data=$(ps aux | grep -E "Xorg :[0-9]+" | grep --group-separator=, -oE "^[[:alnum:]]+ |Xorg :[0-9]+" | sed ':a;N;$!ba;s/\nXorg //g')
  echo "$data"
  [ -n "$data" ] && return 0 || return 1
}

# FUNCTION Get display sessions for a given user
# Parameters
#   - 1 : str User name to search
# Return: 0 if success; 1 if no user found
# Stdout: List of diplays in touples of (user display)
getUserDisplays () {
  local data
  data=$(ps aux | grep -E "^${1} " | grep -E "Xorg :[0-9]+" | grep --group-separator=, -oE "^[[:alnum:]]+ |Xorg :[0-9]+" | sed ':a;N;$!ba;s/\nXorg //g')
  echo "$data"
  [ -n "$data" ] && return 0 || return 1
}

# FUNCTION Set a window pid onTop property
# Parameters:
#   - 1 : str User name
#   - 2 : str Display ID
#   - 3 : int Process ID of the window
# Return
setOnTop () {
  local uname=${1} disp=${2} pid=${3} wid
  
  export DISPLAY=${disp}
  
  sleep 1
  wid=$(sudo -u ${uname} -i wmctrl -l -p | grep ${pid} | awk '{print $1}')
  
  sudo -u ${uname} -i wmctrl -i -r ${wid} -b add,above 
  if [ $? -ne 0 ]; then
    perror "Could not set onTop property"
    return 1
  fi
  return 0
}



# FUNCTION Invoke an application on a given display
# Parameters:
#   - 1 : str User name
#   - 2 : str Display ID
#   - 3+: cmd Command to run
# Return: 0 if success; 1 if error
# Stdout: pid of the window process
invokeOnDisplay () {
  local uname=${1} disp=${2} cmd res fpid
  shift 2
  
  export DISPLAY=${disp}
  printf -v cmd '%q ' "${@}"
  
  fpid=$(sudo -u ${uname} -i bash -c "nohup ${cmd} >/dev/null 2>&1 & echo \$!")
  res=$?
  [ $res -ne 0 ] && return 1
  
  [ -n "$fpid" ] && echo "$fpid"
  return 0
}


# FUNCTION Invoke a zenity warning dialog on a given display
# Parameters:
#   - 1 : str User name
#   - 2 : str Display ID
#   - 3 : str Zenity window title
#   - 4 : str Zenity window message
#   - 5*: bit Zenity window onTop
# Return: 
invokeWarning () {
  local uname=${1} disp=${2} ttl="${3}" msg="${4}" onTop wpid
  [ -z "${5}" ] && onTop=0 || onTop="${5}"
  
  wpid=$(invokeOnDisplay ${uname} ${disp} zenity --warning --title "${ttl}" --text "${msg}") || return 1
  
  echo "pid:$wpid"
  
  if [ $onTop -eq 1 ]; then
    setOnTop ${uname} ${disp} ${wpid} || return 1
  fi
  return 0
}


# FUNCTION Invoke a zenity info dialog on a given display
# Parameters:
#   - 1 : str User name
#   - 2 : str Display ID
#   - 3 : str Zenity window title
#   - 4 : str Zenity window message
#   - 5*: bit Zenity window onTop
# Return: 
invokeInfo () {
  local uname=${1} disp=${2} ttl="${3}" msg="${4}" onTop wpid
  [ -z "${5}" ] && onTop=0 || onTop="${5}"
  
  wpid=$(invokeOnDisplay ${uname} ${disp} zenity --info --title "${ttl}" --text "${msg}") || return 1
  
  if [ $onTop -eq 1 ]; then
    setOnTop ${uname} ${disp} ${wpid} || return 1
  fi
  return 0
}




# FUNCTION Execute Warning mode logic
# Parameters
#   Use global script parameters:
#     - p_user
#     - p_attrs
#     - p_ontop
wallWarning () {
  local targets ttl msg onTop iw u d
  
  if [ -z "$p_user" ]; then
    targets=$(getAllDisplays) || die "No X sessions was found on system" 3
  else
    targets=$(getUserDisplays $p_user) || die "User not found or do not have X sessions" 3
  fi
  
  ttl="${p_attrs[0]}"
  msg="${p_attrs[1]}"
  onTop="${p_ontop}"
  
  while IFS= read -r iw; do
    read u d <<<"$iw"
    echo -n "Launching Warning dialog on user $u ($d)... "
    invokeWarning $u $d "$ttl" "$msg" $onTop && echo ok || perror "Invoke failed."
  done <<<"$targets"
}


# FUNCTION Execute Info mode logic
# Parameters
#   Use global script parameters:
#     - p_user
#     - p_attrs
#     - p_ontop
wallInfo () {
  local targets ttl msg onTop iw u d
  
  if [ -z "$p_user" ]; then
    targets=$(getAllDisplays) || die "No X sessions was found on system" 3
  else
    targets=$(getUserDisplays $p_user) || die "User not found or do not have X sessions" 3
  fi
  
  ttl="${p_attrs[0]}"
  msg="${p_attrs[1]}"
  onTop="${p_ontop}"
  
  while IFS= read -r iw; do
    read u d <<<"$iw"
    echo -n "Launching Info dialog on user $u ($d)... "
    invokeInfo $u $d "$ttl" "$msg" $onTop && echo ok || perror "Invoke failed."
  done <<<"$targets"
}


# FUNCTION Execute Info mode logic
# Parameters
#   Use global script parameters:
#     - p_user
#     - p_attrs
#     - p_ontop
wallCustom () {
  local targets onTop iw u d wpid
  
  if [ -z "$p_user" ]; then
    targets=$(getAllDisplays) || die "No X sessions was found on system" 3
  else
    targets=$(getUserDisplays $p_user) || die "User not found or do not have X sessions" 3
  fi
  
  onTop="${p_ontop}"
  
  echo "Target application: ${p_attrs[@]}"
  
  while IFS= read -r iw; do
    read u d <<<"$iw"
    echo -n "Launching custom app on user $u ($d)... "
    wpid=$(invokeOnDisplay $u $d ${p_attrs[@]}) && echo ok || perror "Invoke failed."
    if [ $onTop -eq 1 ]; then
      setOnTop ${u} ${d} ${wpid}
    fi
  done <<<"$targets"
}



printHelp () {
  echo "Xorg-wall [options] <mode> <parameters>"
  echo 
  echo "Invoke a graphical window to all users of Xorg displays"
  echo
  echo "Options:"
  echo "     --user <name>   Invoke only for one user"
  echo "     --ontop         Set the application on top of screen"
  echo "  -V --version       Show version information"
  echo "  -h --help          Show this help message"
  echo
  echo "Modes:"
  echo "     --warning       Print a warning dialog"
  echo "     --info          Print an info dialog"
  echo "     --custom        Invoke a custom app"
  echo
  echo "Parameters for --warning <title> <msg> [onTop]"
  echo "  title    Is the title of the warning window"
  echo "  msg      Is the message of the warning window"
  echo
  echo "Parameters for --info <title> <msg>"
  echo "  title    Is the title of the info window"
  echo "  msg      Is the message of the info window"
  echo
  echo "Parameters for --custom <cmd> [attr ...]"
  echo "  cmd      Is the command to execute"
  echo "  attr     Is an attribute for the command"
}


printVersion () {
  echo "Xorg-wall v${VERSION} (${RELEASE_DATE})"
  echo "By: ${AUTHOR}"
}




p_mode=   #Modes: w (warning), i (info), c (custom)
p_user=
p_ontop=0
p_attrs=()




while [ $# -gt 0 ]; do
  
  case "$1" in
    -h|--help)
      printHelp
      exit 0
      ;;
      
    -V|--version)
      printVersion
      exit 0
      ;;
      
    --warning)
      if [ -z "$p_mode" ]; then
        p_mode=w
      else
        die "Operation mode already set" 1
      fi
      ;;
      
    --info)
      if [ -z "$p_mode" ]; then
        p_mode=i
      else
        die "Operation mode already set" 1
      fi
      ;;
      
    --custom)
      if [ -z "$p_mode" ]; then
        p_mode=c
      else
        die "Operation mode already set" 1
      fi
      ;;
      
    --user)
      p_user=$2
      shift
      ;;
      
    --ontop)
      p_ontop=1
      ;;
      
    -*)
      if [ -z "$p_mode" ]; then
        die "Option '$1' do not exist" 1
      else
        p_attrs+=("$1")
      fi
      ;;
      
    *)
      if [ -z "$p_mode" ]; then
        die "Parameter '$1' do not exist" 1
      else
        p_attrs+=("$1")
      fi
      ;;
  esac
  
  shift
  
done




if [ -z "$p_mode" ]; then
  die "Operation mode was not set" 2
fi

if [ "${#p_attrs[@]}" -eq 0 ]; then
  die  "No command for custom mode" 2
fi


case $p_mode in
  w) #WARNING
    [ "${#p_attrs[@]}" -lt 2 ] && die "Not enough attributes to execute." 2
    wallWarning
    ;;
  
  i) #INFO
    [ "${#p_attrs[@]}" -lt 2 ] && die "Not enough attributes to execute." 2
    wallInfo
    ;;
    
  c) #CUSTOM
    [ "${#p_attrs[@]}" -lt 1 ] && die "Not command to execute." 2
    wallCustom
    ;;
esac

exit 0