#!/bin/bash

while read line
do
  if [[ -n "${line}" -a "${line}"" != #* ) ]]
  then
    ./run_timing_tests.sh "${line}"
  fi
done < $1

