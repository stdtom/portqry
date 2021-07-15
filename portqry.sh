#!/usr/bin/env bash
#

### TODO
#if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
#then
#    set -eo pipefail  # Exit immediately on error
#    #set -u            # Exit on unset variables 
#fi


#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} [OPTION]... [FILE]...
#%
#% DESCRIPTION
#%    portqry.sh is a shell script that you can use to help troubleshoot TCP/IP connectivity 
#%    issues. portqry.sh runs on Linux-based computers. The script can be used to check the 
#%    port status of TCP ports on a number of target computers you specify.
#%
#% OPTIONS
#%    -t, --timeout  Maximum time in seconds to try to establish a connection (default: 5)
#%    -p, --port  Ports to scan (default: '80')
#%    -h  show this help (default: false)
    #%    -u, --username    Username for script
    #%    -p, --password    Input user password, it's recommended to insert
    #%                      this through the interactive option
    #%    -f, --force       Skip all user interaction
    #%    -i, --interactive Prompt for values
    #%    -q, --quiet       Quiet (no output)
    #%    -v, --verbose     Output more
#%    -h, --help        Display this help and exit
#%        --version     Output version information and exit
#%
#% EXAMPLES
#%    ${SCRIPT_NAME} -u username
#%
#================================================================
#- IMPLEMENTATION
#-    version         ${SCRIPT_NAME} ${VERSION}
#-    author          stdtom
#-    copyright       Copyright (c) 2019-2021 stdtom
#-    license         MIT License
#-
#================================================================
#  HISTORY
#     2019/08/03 : stdtom : Script creation
#     2019/08/21 : stdtom : Finazlizing first version
#     2021/07/14 : stdtom : Eliminate shflags dependency
# 
#================================================================
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#
#================================================================
# END_OF_HEADER
#================================================================

# Preamble {{{

# Detect whether output is piped or not.
[[ -t 1 ]] && piped=0 || piped=1

# Defaults
force=0
quiet=0
verbose=0
interactive=0
args=()

# }}}
# Helpers {{{

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[1;31m' GREEN='\033[1;32m' ORANGE='\033[0;33m' BLUE='\033[1;34m' PURPLE='\033[1;35m' CYAN='\033[1;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}
out() {
  ((quiet)) && return

  local message="$@"
  if ((piped)); then
    message=$(echo $message | sed '
      s/\\[0-9]\{3\}\[[0-9]\(;[0-9]\{2\}\)\?m//g;
      s/✖/Error:/g;
      s/✔/Success:/g;
    ')
  fi
  printf '%b\n' "$message";
}
die() { out "$@"; exit 1; } >&2
err() { out " ${RED}✖  $@${NOFORMAT}"; } >&2
success() { out " ${GREEN}✔  $@${NOFORMAT}"; }


# Verbose logging
log() { (($verbose)) && out "$@"; }

# Notify on function success
notify() { [[ $? == 0 ]] && success "$@" || err "$@"; }

# Escape a string
escape() { echo $@ | sed 's/\//\\\//g'; }

# Unless force is used, confirm with user
confirm() {
  (($force)) && return 0;

  read -p "$1 [y/N] " -n 1;
  [[ $REPLY =~ ^[Yy]$ ]];
}

timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

  #== needed variables ==#
SCRIPT_HEADSIZE=$(head -200 ${0} |grep -n "^# END_OF_HEADER" | cut -f1 -d:)
SCRIPT_NAME="$(basename ${0})"

  #== usage functions ==#
usage() { printf "Usage: "; head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#+" | sed -e "s/^#+[ ]*//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g" ; }
usagefull() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#[%+-]" | sed -e "s/^#[%+-]//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g" ; }
scriptinfo() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#-" | sed -e "s/^#-//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }

# }}}
# Script logic -- TOUCH THIS {{{

VERSION="v0.1"

# A list of all variables to prompt in interactive mode. These variables HAVE
# to be named exactly as the longname option definition in usage().
interactive_opts=()


# Set a trap for cleaning up in case of errors or when script exits.
rollback() {
  die
}

# Put your script here
main() {
    while IFS=: read -r f1 f2
    do
        THOST=$f1
        TPORT=$f2

        # Skip empty lines
        [[ -z "$THOST" && -z "$TPORT" ]] && continue

        # Skip comments
        [[ "$THOST" == "#"* ]] &&  continue

        # If no port specified, use port from command line flag
        [[  -z "$TPORT" ]] && TPORT=${port}

        test_tcp_connection "$THOST" "$TPORT" 
    done 
}

test_tcp_connection(){
	local thost="$1"
	local tport="$2"
	
    if [ "$tport" -eq "$tport" ] 2> /dev/null && [ "$tport" -ge 1 ] && [ "$tport" -le 65535 ]; then
        printf '%s:%s\t' "$thost" "$tport"
        timeout "${timeout}" bash -c "cat < /dev/null > /dev/tcp/$thost/$tport" 2>/dev/null 1>&2
        rcode=$?

        case "$rcode" in
            0)
                result="LISTENING"
                ;;
            1)
                result="NOT LISTENING"
                ;;
            124)
                result="FILTERED"
                ;;
            *)
                result="UNKOWN (Return code $rcode not specified)"
                ;;
        esac

        printf '%s\n' "$result"

    # if port list
    elif [[ "$tport" == *","* ]]; then
        IFS=','
        read -ra elems  <<< "$tport"

        ret=0
        for el in "${elems[@]}"; do # access each element of array
            test_tcp_connection "$thost" "$el"
        done

    # if port range
    elif [[ "$tport" == *"-"* ]]; then
        IFS='-'
        read -r lower upper  <<< "$tport"
        [ "$lower" -gt "$upper" ]   && printf 'Invalid port range: %s\n' "$lport" && return 1

        for (( el=lower; el<=upper; el++ )); do
            test_tcp_connection "$thost" "$el"
        done
    fi
}

validate_port(){
    local lport="$1"

    # if  lport is integer
    if [ "$lport" -eq "$lport" ] 2> /dev/null
    then
        # if 1 <= lport <= 65536
        [[ ( "$lport" -ge 1 ) && ( "$lport" -le 65535 ) ]]   && return 0

        # if lport < 1
        [ "$lport" -lt 1 ]   && printf 'Invalid port: %s\n' "$lport" && return 1

        #if lport > 65535
        [ "$lport" -gt 65535 ]   && printf 'Invalid port: %s\n' "$lport" && return 1
    else
        # if port range
        if [[ "$lport" == *"-"* ]]
        then
            IFS='-'
            read -r lower upper  <<< "$lport"

            # valid port range
            [ "$lower" -lt "$upper" ]   && return 0

            # invalid port range
            [ "$lower" -gt "$upper" ]   && printf 'Invalid port range: %s\n' "$lport" && return 1
        fi

        # if port list
        if [[ "$lport" == *","* ]]
        then
            IFS=','
            read -ra elems  <<< "$lport"

            ret=0
            for el in "${elems[@]}"; do # access each element of array
                validate_port "$el"
                ret=$(( ret | $?))
            done

            return ${ret}
        fi

        # if not integer, not port range, and not port list
        printf 'Invalid port: %s\n' "$lport"
        return 1
    fi

    # should never be reached
    return 33;
}

validate_integer(){
    local local_int="$1"

    # if  local_int is integer
    if [ "$local_int" -eq "$local_int" ] 2> /dev/null
    then
        # if 0 <= local_int <= 65536
        [[ ( "$local_int" -ge 0 ) && ( "$local_int" -le 65535 ) ]]   && return 0

        # if local_int < 0
        [ "$local_int" -lt 0 ]   && printf 'Invalid integer: %s\n' "$local_int" && return 1

        #if local_int > 65535
        [ "$local_int" -gt 65535 ]   && printf 'Invalid integer: %s\n' "$local_int" && return 1
    else
        # if not integer
        printf 'Invalid integer: %s\n' "$lport"
        return 1
    fi

    # should never be reached
    return 33;
}

# Run main block only if script has not been sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
then
    echo "Script ${BASH_SOURCE[0]} loaded ..."
    return
fi


# }}}
# Boilerplate {{{

# Prompt the user to interactively enter desired variable values. 
prompt_options() {
  local desc=
  local val=
  for val in ${interactive_opts[@]}; do

    # Skip values which already are defined
    [[ $(eval echo "\$$val") ]] && continue

    # Parse the usage description for spefic option longname.
    desc=$(usage | awk -v val=$val '
      BEGIN {
        # Separate rows at option definitions and begin line right before
        # longname.
        RS="\n +-([a-zA-Z0-9], )|-";
        ORS=" ";
      }
      NR > 3 {
        # Check if the option longname equals the value requested and passed
        # into awk.
        if ($1 == val) {
          # Print all remaining fields, ie. the description.
          for (i=2; i <= NF; i++) print $i
        }
      }
    ')
    [[ ! "$desc" ]] && continue

    echo -n "$desc: "

    # In case this is a password field, hide the user input
    if [[ $val == "password" ]]; then
      stty -echo; read password; stty echo
      echo
    # Otherwise just read the input
    else
      eval "read $val"
    fi
  done
}

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;
    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# }}}
# Main loop {{{
setup_colors

# Print help if no arguments were passed.
#[[ $# -eq 0 ]] && set -- "--help"          # TODO

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usagefull >&2; safe_exit ;;
    --version) out "${SCRIPT_NAME} ${VERSION}"; safe_exit ;;
    -t|--timeout) shift; timeout=$1 ;;
    -p|--port) shift; port=$1 ;;
    -v|--verbose) verbose=1 ;;
    -q|--quiet) quiet=1 ;;
    -i|--interactive) interactive=1 ;;
    -f|--force) force=1 ;;
    --endopts) shift; break ;;
    *) die "invalid option: $1" ;;
  esac
  shift
done

# Set default value and validate parameter
timeout="${timeout:-5}"
validate_integer "${timeout}" || exit 1

port="${port:-80}"
validate_port "${port}" || exit 1

main


