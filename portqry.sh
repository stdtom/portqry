#!/bin/sh
#

test_tcp_connection(){
	local thost="$1"
	local tport="$2"
	
    printf '%s:%s\t' "$thost" "$tport" 
    timeout 5 bash -c "cat < /dev/null > /dev/tcp/$THOST/$TPORT"
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


while IFS=: read -r f1 f2
do
    THOST=$f1 
    TPORT=$f2 

    test_tcp_connection "$THOST" "$TPORT" 
done 


