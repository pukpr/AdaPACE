#!/usr/bin/bash
#
# Template for running background applications with P4
# Use P4PATH to determine location of this file

#-| Launch application in the background here 
#-|
$* &

#-| Necessary boiler plate code for p4
#-| Note that as app launched in the background, need to kill manually
#-|
echo "P4 is ready"
while read L
do
  if [[ "$L" == \x1B ]] ; then 
     echo "__ p4 __"
     exit
  elif [[ "$L" == "" ]] ; then 
     echo $*
  fi
  echo "__ p4 __"
done


kill -9 0

