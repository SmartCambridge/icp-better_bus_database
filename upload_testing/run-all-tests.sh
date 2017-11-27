# Simple database 

# With pgloader
./timeit.sh 5 'psql -c "truncate siri_vm_simple_test" acp; ./siri-vm-to-simple-csv.py ../../data/sirivm_json/data_bin/2017/10/27/ | pgloader siri-vm-to-simple-database.load'

# With Python
./timeit.sh 5 'psql -c "truncate siri_vm_simple_test" acp; psql -f drop_simple_indexes.sql acp; ./siri-vm-simple-insert.py ../../data/sirivm_json/data_bin/2017/10/27/; psql -f add_simple_indexes.sql acp'

# Complex database

# With pgloader and subsequent update
./timeit.sh 5 'psql -c "truncate siri_vm_complex_test" acp; psql -f drop_complex_indexes.sql acp; ./siri-vm-to-simple-csv.py ../../data/sirivm_json/data_bin/2017/10/27/ | pgloader siri-vm-to-complex-database-with-update.load; psql -f add_complex_indexes.sql acp'

# With pgloader and all data supplied
./timeit.sh 5 'psql -c "truncate siri_vm_complex_test" acp; ./siri-vm-to-complex-csv.py ../../data/sirivm_json/data_bin/2017/10/27/ | pgloader siri-vm-to-complex-database.load'

# With SQL piped into psql
./timeit.sh 5 'psql -c "truncate siri_vm_complex_test" acp; psql -f drop_complex_indexes.sql acp; ./siri-vm-to-complex-sql.py ../../data/sirivm_json/data_bin/2017/10/27/ | psql -q acp; psql -f add_complex_indexes.sql acp'

# With Python
./timeit.sh 5 'psql -c "truncate siri_vm_complex_test" acp; psql -f drop_complex_indexes.sql acp; ./siri-vm-complex-insert.py siri_vm3 ../../data/sirivm_json/data_bin/2017/10/27/; psql -f add_complex_indexes.sql acp'

## Appending data

# Simple schema

./timeit.sh 5 'psql -c "truncate siri_vm_simple_test" acp; ./siri-vm-to-simple-csv.py ../../data/sirivm_json/data_bin/2017/10/27/ | pgloader siri-vm-to-simple-database.load; ./siri-vm-simple-insert-commit.py ../../data/sirivm_json/data_bin/2017/10/26/'

# Complex schema

./timeit.sh 5 'psql -c "truncate siri_vm_complex_test" acp; ./siri-vm-to-complex-csv.py ../../data/sirivm_json/data_bin/2017/10/27/ | pgloader siri-vm-to-complex-database.load; ./siri-vm-complex-insert-commit.py ../../data/sirivm_json/data_bin/2017/10/26/'