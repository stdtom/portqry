#!/bin/bash
#

testSkipEmptyLines() {
  result=$(echo ""|./portqry.sh)
  assertEquals \
        x"${result}" "x" 
}

testSkipCommentLines() {
  result=$(echo "#"|./portqry.sh)
  assertEquals \
        x"${result}" "x" 
}

testLocalhostPort2NotListening() {
  result=$( (echo "127.0.0.1:2")|./portqry.sh )
#  assertEquals \
#        "x127.0.0.1:2    NOT LISTENING" x"${result}" 
  assertContains "${result}" "127.0.0.1:2" 
  assertContains "${result}"  "NOT LISTENING" 
}

testTimeoutAcceptInteger() {
  result=$( (echo "127.0.0.1:2")|./portqry.sh -t 3 )
  assertContains "${result}" "127.0.0.1:2"
  assertContains "${result}"  "NOT LISTENING"
}

testTimeoutRejectNonInteger() {
  (echo "127.0.0.1:2")|./portqry.sh -t d 2>/dev/null
  result=$?
  assertNotEquals \
        "0" "${result}"
}

testUseDefaultPort80() {
  result=$( (echo "127.0.0.1")|./portqry.sh )
  assertContains "${result}" "127.0.0.1:80"
}

testUsePortFlag() {
  result=$( (echo "127.0.0.1")|./portqry.sh -p 3 )
  assertContains "${result}" "127.0.0.1:3"
}

testValidatePortTable() {
  while read -r desc arg want; do
    got=$(validate_port "${arg}")
    got=$?
    #assertTrue "${desc}: validate_port() unexpected error; return ${rtrn}" ${rtrn}
    assertEquals "${desc}: validate_port(): " "${want}" "${got}"
  done <<EOF
  port=1 1 0
  port=2 2 0
  maxPort 65535 0
  greaterMaxPort 65536 1
  port=0 0 1
  portAsString abc 1
  negativePort -1 1
  portRange 2-3 0
  inversPortRange 4-3 1
  portList 2,3,6 0
  invalidPortList 2,xy,6 1
  portListWithEmptyPort 2,,3,6 1
  empty "" 1
EOF
}

testUsePortFlagTable() {
  while read -r desc arg want; do
    got=$( (echo "127.0.0.1")|./portqry.sh -p "${arg}" )
    assertContains "${desc}: validate_port(): " "${got}" "${want}"
  done <<EOF
  port=1 1 127.0.0.1:1
  port=2 2 127.0.0.1:2
  maxPort 65535 127.0.0.1:65535
  greaterMaxPort 65536 Invalid port
  port=0 0 Invalid port
  portAsString abc Invalid port
  negativePort -1 Invalid port
  inversPortRange 4-3 Invalid port range
  invalidPortList 2,xy,6 Invalid port
  portListWithEmptyPort 2,,3,6 Invalid port
  empty "" Invalid port
EOF
}

testUsePortFlagWithRange() {
  result=$( (echo "127.0.0.1")|./portqry.sh -p 2-4 )
  assertContains "${result}" "127.0.0.1:2"
  assertContains "${result}" "127.0.0.1:3"
  assertContains "${result}" "127.0.0.1:4"
}

testUsePortFlagWithList() {
  result=$( (echo "127.0.0.1")|./portqry.sh -p 2,3,6 )
  assertContains "${result}" "127.0.0.1:2"
  assertContains "${result}" "127.0.0.1:3"
  assertContains "${result}" "127.0.0.1:6"
}

testLocalhostListeningPorts() {
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    for p in $localListeningPorts ; do
      result=$( (echo "127.0.0.1:$p")|./portqry.sh )
      assertContains "${result}" "127.0.0.1:$p"
      assertNotContains "${result}"  "NOT LISTENING"
    done
  fi
}

testLocalhostNotListeningPorts() {
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    for p in $localNotListeningPorts ; do
      result=$( (echo "127.0.0.1:$p")|./portqry.sh )
      assertContains "${result}" "127.0.0.1:$p"
      assertContains "${result}"  "NOT LISTENING"
    done
  fi
}

testUsePortFlagWithLocalhostListeningPortList() {
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    portlist=${localListeningPorts// /,}   # Replace ' ' with ','  cf.  https://www.gnu.org/software/bash/manual/bash.html#Shell-Parameter-Expansion
    portlist=${portlist%,}
    result=$( (echo "127.0.0.1")|./portqry.sh -p "$portlist" )
    for p in $localListeningPorts ; do
      assertContains "${result}" "127.0.0.1:$p"
      assertNotContains "${result}"  "NOT LISTENING"
    done
  fi
}

testUsePortFlagWithLocalhostListeningPortRange() {
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    set -- ${localListeningPorts}
    lo=$(( $1 - 1 ))
    hi=$(( $1 + 1 ))
    result=$( (echo "127.0.0.1")|./portqry.sh -p "${lo}-${hi}" )
    assertContains "${result}" "127.0.0.1:$lo"
    assertContains "${result}" "127.0.0.1:$1"
    assertContains "${result}" "127.0.0.1:$hi"
    assertNotContains "$(echo ${result}|grep '127.0.0.1:$1' )"  "NOT LISTENING"
  fi
}

oneTimeSetUp() {
  # Load portqry to test.
  . ./portqry.sh

  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    localListeningPorts=$(netstat -tln4 |awk '/^tcp/ {split($4,a,/:/); if (a[1] ~ /(0\.0\.0\.0|127\.0\.0\.1)/) print a[2]}'|sort -n |tr '\n' ' ')
    localNotListeningPorts=$(for p in {78..85}; do [[ $localListeningPorts =~ $p ]] || echo $p; done|head -n5)
  #elif [[ "$OSTYPE" == "msys" ]]; then
    # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
  fi

}

localListeningPorts=""
localNotListeningPorts=""

# Load and run shUnit2.
. ./test/libs/shunit2/shunit2

