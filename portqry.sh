#!/bin/bash
#

test_tcp_connection(){
	local thost="$1"
	local tport="$2"
	
    if [ "$tport" -eq "$tport" ] 2> /dev/null && [ "$tport" -ge 1 ] && [ "$tport" -le 65535 ]; then
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
            [ "$lower" -lt "$upper" ]   && return 0
        fi

        # if invalid port range
        if [[ "$lport" == *"-"* ]]
        then
            IFS='-'
            read -r lower upper  <<< "$lport"
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
    validate_port "${FLAGS_port}" || exit 1

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

