#!/bin/sh
#

testSkipEmptyLines() {
  result=`echo ""|./portqry.sh`
  assertEquals \
        x"${result}" "x" 
}

testSkipCommentLines() {
  result=`echo "#"|./portqry.sh`
  assertEquals \
        x"${result}" "x" 
}

testLocalhostPor2NotListening() {
  result=`(echo "127.0.0.1:2")|./portqry.sh`
#  assertEquals \
#        "x127.0.0.1:2    NOT LISTENING" x"${result}" 
  assertContains "${result}" "127.0.0.1:2" 
  assertContains "${result}"  "NOT LISTENING" 
}


oneTimeSetUp() {
  # Load portqry to test.
  . ./portqry.sh

}

# Load and run shUnit2.
. ./test/libs/shunit2/shunit2