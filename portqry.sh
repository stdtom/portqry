#!/bin/sh
#

test_tcp_connection(){
	local thost="$1"
	local tport="$2"
	
    printf '%s:%s\t' "$thost" "$tport" 
    timeout 5 bash -c "cat < /dev/null > /dev/tcp/$THOST/$TPORT" 2>/dev/null 1>&2
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

main() {
    while IFS=: read -r f1 f2
    do
        THOST=$f1 
        TPORT=$f2 

        test_tcp_connection "$THOST" "$TPORT" 
    done 
}

# Run main only if script has not been sourced
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && echo "Script ${BASH_SOURCE[0]} loaded ..." || main

