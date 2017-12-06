#!/bin/bash

in_quoted='false'

while IFS= read -r
do

  # Skip actual comments
  if [[ "${REPLY}" == '#'* ]]
  then
    :

  # Track quoted block state
  elif [[ "${REPLY}" == '"""' ]]
  then
    if [[ "${in_quoted}" == 'true' ]]
    then
      in_quoted='false'
    else
      in_quoted='true'
    fi
    # ..and convert to backtics
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

