#!/bin/bash
#

test_tcp_connection(){
	local thost="$1"
	local tport="$2"
	
    printf '%s:%s\t' "$thost" "$tport" 
    timeout ${FLAGS_timeout} bash -c "cat < /dev/null > /dev/tcp/$THOST/$TPORT" 2>/dev/null 1>&2
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

# Run main block only if script has not been sourced
 if [[ "${BASH_SOURCE[0]}" != "${0}" ]] 
 then
     echo "Script ${BASH_SOURCE[0]} loaded ..." 
else
   # Source shflags.
   . libs/shflags/shflags

    DEFINE_integer 'timeout' 5 'Maximum time in seconds to try to establish a connection' 't'

    # Parse the command-line.
    FLAGS "$@" || exit 1
    eval set -- "${FLAGS_ARGV}"

    #echo "Timeout: ${FLAGS_timeout}"

    while IFS=: read -r f1 f2
    do
        THOST=$f1 
        TPORT=$f2 

        # Skip empty lines
        [[ -z "$THOST" && -z "$TPORT"  ]] && continue

        # Skip comments
        [[ "$THOST" == "#"* ]] &&  continue

        test_tcp_connection "$THOST" "$TPORT" 
    done 
fi

