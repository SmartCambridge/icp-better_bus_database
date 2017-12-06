#!/bin/bash

database='tfcapi'
table='siri_vm_3'
loader='siri-vm-to-csv3.py'
load_pattern=''
work_mem='2GB'
maintenance_work_mem='2GB'

# Make this work on laptop and tfc servers
if [[ -d '/Users/jw35/icp/data/' ]]; then
    load_path="/Users/jw35/icp/data/sirivm_json/data_bin/${load_pattern}"
else
    load_path="/media/tfc/sirivm_json/data_bin/${load_pattern}"
fi

echo
echo "Loading data from ${load_path} into database ${database}, table ${table}"
echo

time psql -d "${database}" -e -X <<EOF

\timing on

SET work_mem TO '${work_mem}';
SET maintenance_work_mem TO '${maintenance_work_mem}';

BEGIN;

DROP TABLE IF EXISTS ${table};

CREATE TABLE ${table} (
    file_ts                  TIMESTAMP WITH TIME ZONE NOT NULL,
    location                 GEOMETRY(POINT,4326) NOT NULL,
    recorded_ts              TIMESTAMP WITH TIME ZONE NOT NULL,
    recorded_date            DATE NOT NULL,
    departure_ts             TIMESTAMP WITH TIME ZONE NOT NULL,
    info                     JSONB NOT NULL
   );

\copy ${table} (file_ts, location, recorded_ts, recorded_date, departure_ts, info) FROM PROGRAM './"${loader}" "${load_path}"' (FORMAT CSV, FREEZE TRUE)

CREATE INDEX ${table}_location ON ${table} USING GIST (location);
CREATE INDEX ${table}_recorded_ts ON ${table} (recorded_ts);
CREATE INDEX ${table}_recorded_date ON ${table} (recorded_date);
CREATE INDEX ${table}_departure_ts ON ${table} (departure_ts);
CREATE INDEX ${table}_info ON ${table} USING GIN (info);

COMMIT;

EOF
