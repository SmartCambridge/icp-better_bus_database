#!/bin/bash

database='tfcapi'
table='siri_vm_5'
loader='siri-vm-to-csv5.py'
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
    info                     JSONB NOT NULL,
    acp_ts_date              DATE
   ) PARTITION BY RANGE (acp_ts_date);

CREATE TABLE ${table}_2017_01 PARTITION OF ${table}
    FOR VALUES FROM ('2017-10-09') TO ('2017-10-16');
CREATE TABLE ${table}_2017_02 PARTITION OF ${table}
    FOR VALUES FROM ('2017-10-16') TO ('2017-10-23');
CREATE TABLE ${table}_2017_03 PARTITION OF ${table}
    FOR VALUES FROM ('2017-10-23') TO ('2017-10-30');
CREATE TABLE ${table}_2017_04 PARTITION OF ${table}
    FOR VALUES FROM ('2017-10-30') TO ('2017-11-06');
CREATE TABLE ${table}_2017_05 PARTITION OF ${table}
    FOR VALUES FROM ('2017-11-06') TO ('2017-11-13');
CREATE TABLE ${table}_2017_06 PARTITION OF ${table}
    FOR VALUES FROM ('2017-11-13') TO ('2017-11-20');
CREATE TABLE ${table}_2017_07 PARTITION OF ${table}
    FOR VALUES FROM ('2017-11-20') TO ('2017-11-27');
CREATE TABLE ${table}_2017_08 PARTITION OF ${table}
    FOR VALUES FROM ('2017-11-27') TO ('2017-12-04');
CREATE TABLE ${table}_2017_09 PARTITION OF ${table}
    FOR VALUES FROM ('2017-12-04') TO ('2017-12-11');
CREATE TABLE ${table}_2017_10 PARTITION OF ${table}
    FOR VALUES FROM ('2017-12-11') TO ('2017-12-18');
CREATE TABLE ${table}_2017_11 PARTITION OF ${table}
    FOR VALUES FROM ('2017-12-18') TO ('2017-12-25');
CREATE TABLE ${table}_2017_12 PARTITION OF ${table}
    FOR VALUES FROM ('2017-12-25') TO ('2018-01-01');
CREATE TABLE ${table}_2018_01 PARTITION OF ${table}
    FOR VALUES FROM ('2018-01-01') TO ('2018-01-08');

\copy ${table} (acp_id, acp_lng, acp_lat, acp_ts, location2d, location4d, info, acp_ts_date) FROM PROGRAM './"${loader}" "${load_path}"' (FORMAT CSV, FREEZE TRUE)

COMMIT;

EOF

for fragment in '2017_01' '2017_02' '2017_03' '2017_04' '2017_05' '2017_06' '2017_07' '2017_08' '2017_09' '2017_10' '2017_11' '2017_12' '2018_01'
do

  time psql -d "${database}" -e -X <<EOF

\timing on

SET work_mem TO '${work_mem}';
SET maintenance_work_mem TO '${maintenance_work_mem}';

BEGIN;

CREATE INDEX ${table}_${fragment}_acp_id ON ${table}_${fragment} (acp_id);
CREATE INDEX ${table}_${fragment}_acp_lng ON ${table}_${fragment} (acp_lng);
CREATE INDEX ${table}_${fragment}_acp_lat ON ${table}_${fragment} (acp_lat);
CREATE INDEX ${table}_${fragment}_acp_ts ON ${table}_${fragment} (acp_ts);
CREATE INDEX ${table}_${fragment}_location2d on ${table}_${fragment} USING GIST (location2d);
CREATE INDEX ${table}_${fragment}_location2d_geom on ${table}_${fragment} USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_${fragment}_location4d on ${table}_${fragment} USING GIST (location4d);
CREATE INDEX ${table}_${fragment}_location4d_geom_nd on ${table}_${fragment} USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_${fragment}_info ON ${table}_${fragment} USING GIN (info);

COMMIT;

EOF

done
