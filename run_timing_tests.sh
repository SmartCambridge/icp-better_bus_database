#!/bin/bash

in_quoted='false'

while IFS= read -r
do

  # Skip actual comments
  if [[ "${REPLY}" == '#'* ]]
  then
    :

  # Start of execution block
  elif [[ "${REPLY}" == '```execute' ]]
  then
    in_quoted='true'
    # ..and convert to backtics
    echo '```'

  # End of execution block
  elif [[ "${REPLY}" == '```'* && "${in_quoted}" == 'true' ]] 
  then
    in_quoted='false'
    echo '```'

  # Execute REPLYs inside quoted block
  elif [[ "${in_quoted}" == 'true' ]]
  then
    ./run_timing_test.sh "${REPLY}"

  # And otherwise copy the REPLY through
  else
    echo "${REPLY}"

  fi

done < $1

