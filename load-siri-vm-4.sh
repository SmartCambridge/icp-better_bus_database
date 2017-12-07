#!/bin/bash

database='tfcapi'
table='siri_vm_4'
loader='siri-vm-to-csv4.py'
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
    acp_id                   CHAR(20) NOT NULL,
    acp_lng                  DOUBLE PRECISION NOT NULL,
    acp_lat                  DOUBLE PRECISION NOT NULL,
    acp_ts                   BIGINT NOT NULL,
    location2d               GEOGRAPHY(POINT,4326) NOT NULL,
    location4d               GEOGRAPHY(POINTZM,4326) NOT NULL,
    info                     JSONB NOT NULL
   );

\copy ${table} (acp_id, acp_lng, acp_lat, acp_ts, location2d, location4d, info) FROM PROGRAM './"${loader}" "${load_path}"' (FORMAT CSV, FREEZE TRUE)

CREATE INDEX ${table}_acp_id ON ${table} (acp_id);
CREATE INDEX ${table}_acp_lng ON ${table} (acp_lng);
CREATE INDEX ${table}_acp_lat ON ${table} (acp_lat);
CREATE INDEX ${table}_acp_ts ON ${table} (acp_ts);
CREATE INDEX ${table}_location2d on ${table} USING GIST (location2d);
CREATE INDEX ${table}_location2d_geom on ${table} USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_location4d on ${table} USING GIST (location4d);
CREATE INDEX ${table}_location4d_geom_nd on ${table} USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_info ON ${table} USING GIN (info);

COMMIT;

EOF
