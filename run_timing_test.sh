#!/bin/bash

database='tfcapi'
work_mem='2GB'
iterations='10'

setup="set work_mem to '${work_mem}'"

echo "Testing \"${@}\" with ${iterations} iterations and work_mem ${work_mem}"

echo
echo "Flushing buffers"
sudo sh -c 'sync && echo 3 > /proc/sys/vm/drop_caches'

echo
echo "Restarting Postgres"
sudo service postgresql restart

echo
psql -d "${database}" -e -f - <<EOF
\timing off
\pset pager off
${setup};
explain analyse ${@}
EOF

echo
echo "${setup}; ${@}" |\
  pgbench "${database}" -n -t "${iterations}" -P 5 -f - |\
  egrep '^latency'

echo
