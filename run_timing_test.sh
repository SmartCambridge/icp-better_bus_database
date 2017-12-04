#!/bin/bash

database='tfcapi'
work_mem='2GB'
iterations='10'

setup="set work_mem to '${work_mem}'"

echo "============================================================================="
echo "Testing \"${@}\" with ${iterations} iterations and work_mem ${work_mem}"

echo
psql -e -c "${setup}; explain analyse ${@}" "${database}"

echo
echo "${setup}; ${@}" |\
  pgbench "${database}" -n -t "${iterations}" -P 5 -f - |\
  egrep '^latency'

echo
