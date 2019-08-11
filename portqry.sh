#!/bin/bash
#

test_tcp_connection(){
	local thost="$1"
	local tport="$2"
	
    printf '%s:%s\t' "$thost" "$tport" 
    timeout "${FLAGS_timeout}" bash -c "cat < /dev/null > /dev/tcp/$THOST/$TPORT" 2>/dev/null 1>&2
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
}

validate_port(){
    local lport="$1"

    # if  lport is integer
    if [ "$lport" -eq "$lport" ] 2> /dev/null
    then
        # if 1 <= lport <= 65536
        [ "$lport" -ge 1 -a "$lport" -le 65535 ]   && return 0

        # if lport < 1
        [ "$lport" -lt 1 ]   && return 1

        #if lport > 65535
        [ "$lport" -gt 65535 ]   && return 1
    else
        # if port range
        if [[ "$lport" == *"-"* ]]
        then
            IFS='-'
            read -r lower upper  <<< "$lport"
            [ "$lower" -lt "$upper" ]   && return 0
        fi

        # if port list
        if [[ "$lport" == *","* ]]
        then
            IFS=','
            read -ra elems  <<< "$lport"

            ret=0
            for el in "${elems[@]}"; do # access each element of array
                validate_port $el
                ret=$(( $ret | $?))
            done

            return ${ret}
        fi

        # if not integer, not port range, and not port list
        return 1
    fi

    # should never be reached
    return 33;
}

# Run main block only if script has not been sourced
 if [[ "${BASH_SOURCE[0]}" != "${0}" ]] 
 then
     echo "Script ${BASH_SOURCE[0]} loaded ..." 
else
   # Source shflags.
   . libs/shflags/shflags

    DEFINE_integer 'timeout' 5 'Maximum time in seconds to try to establish a connection' 't'
    DEFINE_string 'port' '80' 'Ports to scan' 'p'

    # Parse the command-line.
    FLAGS "$@" || exit 1
    eval set -- "${FLAGS_ARGV}"

    while IFS=: read -r f1 f2
    do
        THOST=$f1
        TPORT=$f2

        # Skip empty lines
        [[ -z "$THOST" && -z "$TPORT" ]] && continue

        # Skip comments
        [[ "$THOST" == "#"* ]] &&  continue

        # If no port specified, use port from command line flag
        [[  -z "$TPORT" ]] && TPORT=${FLAGS_port}

        test_tcp_connection "$THOST" "$TPORT" 
    done 
fi

