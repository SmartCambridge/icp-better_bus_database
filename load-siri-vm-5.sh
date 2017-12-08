#!/bin/bash

database='tfcapi'
table='siri_vm_5'
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

DROP TABLE IF EXISTS ${table} CASCADE;

CREATE TABLE ${table} (
    acp_id                   CHAR(20) NOT NULL,
    acp_lng                  DOUBLE PRECISION NOT NULL,
    acp_lat                  DOUBLE PRECISION NOT NULL,
    acp_ts                   BIGINT NOT NULL,
    location2d               GEOGRAPHY(POINT,4326) NOT NULL,
    location4d               GEOGRAPHY(POINTZM,4326) NOT NULL,
    info                     JSONB NOT NULL,
    acp_ts_date              DATE
   );

-- 1507507200 - 1508112000 (2017-10-09T00:00:00+00:00 to 2017-10-16T00:00:00+00:00) 2017_41
CREATE TABLE ${table}_2017_41 (
    CHECK ( acp_ts >= 1507507200 and acp_ts < 1508112000 )
) INHERITS (${table});

-- 1508112000 - 1508716800 (2017-10-16T00:00:00+00:00 to 2017-10-23T00:00:00+00:00) 2017_42
CREATE TABLE ${table}_2017_42 (
    CHECK ( acp_ts >= 1508112000 and acp_ts < 1508716800 )
) INHERITS (${table});

-- 1508716800 - 1509321600 (2017-10-23T00:00:00+00:00 to 2017-10-30T00:00:00+00:00) 2017_43
CREATE TABLE ${table}_2017_43 (
    CHECK ( acp_ts >= 1508716800 and acp_ts < 1509321600 )
) INHERITS (${table});

-- 1509321600 - 1509926400 (2017-10-30T00:00:00+00:00 to 2017-11-06T00:00:00+00:00) 2017_44
CREATE TABLE ${table}_2017_44 (
    CHECK ( acp_ts >= 1509321600 and acp_ts < 1509926400 )
) INHERITS (${table});

-- 1509926400 - 1510531200 (2017-11-06T00:00:00+00:00 to 2017-11-13T00:00:00+00:00) 2017_45
CREATE TABLE ${table}_2017_45 (
    CHECK ( acp_ts >= 1509926400 and acp_ts < 1510531200 )
) INHERITS (${table});

-- 1510531200 - 1511136000 (2017-11-13T00:00:00+00:00 to 2017-11-20T00:00:00+00:00) 2017_46
CREATE TABLE ${table}_2017_46 (
    CHECK ( acp_ts >= 1510531200 and acp_ts < 1511136000 )
) INHERITS (${table});

-- 1511136000 - 1511740800 (2017-11-20T00:00:00+00:00 to 2017-11-27T00:00:00+00:00) 2017_47
CREATE TABLE ${table}_2017_47 (
    CHECK ( acp_ts >= 1511136000 and acp_ts < 1511740800 )
) INHERITS (${table});

-- 1511740800 - 1512345600 (2017-11-27T00:00:00+00:00 to 2017-12-04T00:00:00+00:00) 2017_48
CREATE TABLE ${table}_2017_48 (
    CHECK ( acp_ts >= 1511740800 and acp_ts < 1512345600 )
) INHERITS (${table});

-- 1512345600 - 1512950400 (2017-12-04T00:00:00+00:00 to 2017-12-11T00:00:00+00:00) 2017_49
CREATE TABLE ${table}_2017_49 (
    CHECK ( acp_ts >= 1512345600 and acp_ts < 1512950400 )
) INHERITS (${table});

-- 1512950400 - 1513555200 (2017-12-11T00:00:00+00:00 to 2017-12-18T00:00:00+00:00) 2017_50
CREATE TABLE ${table}_2017_50 (
    CHECK ( acp_ts >= 1512950400 and acp_ts < 1513555200 )
) INHERITS (${table});

-- 1513555200 - 1514160000 (2017-12-18T00:00:00+00:00 to 2017-12-25T00:00:00+00:00) 2017_51
CREATE TABLE ${table}_2017_51 (
    CHECK ( acp_ts >= 1513555200 and acp_ts < 1514160000 )
) INHERITS (${table});

-- 1514160000 - 1514764800 (2017-12-25T00:00:00+00:00 to 2018-01-01T00:00:00+00:00) 2017_52
CREATE TABLE ${table}_2017_52 (
    CHECK ( acp_ts >= 1514160000 and acp_ts < 1514764800 )
) INHERITS (${table});

-- 1514764800 - 1515369600 (2018-01-01T00:00:00+00:00 to 2018-01-08T00:00:00+00:00) 2018_01
CREATE TABLE ${table}_2018_01 (
    CHECK ( acp_ts >= 1514764800 and acp_ts < 1515369600 )
) INHERITS (${table});

-- 1515369600 - 1515974400 (2018-01-08T00:00:00+00:00 to 2018-01-15T00:00:00+00:00) 2018_02
CREATE TABLE ${table}_2018_02 (
    CHECK ( acp_ts >= 1515369600 and acp_ts < 1515974400 )
) INHERITS (${table});

-- 1515974400 - 1516579200 (2018-01-15T00:00:00+00:00 to 2018-01-22T00:00:00+00:00) 2018_03
CREATE TABLE ${table}_2018_03 (
    CHECK ( acp_ts >= 1515974400 and acp_ts < 1516579200 )
) INHERITS (${table});

-- 1516579200 - 1517184000 (2018-01-22T00:00:00+00:00 to 2018-01-29T00:00:00+00:00) 2018_04
CREATE TABLE ${table}_2018_04 (
    CHECK ( acp_ts >= 1516579200 and acp_ts < 1517184000 )
) INHERITS (${table});

-- 1517184000 - 1517788800 (2018-01-29T00:00:00+00:00 to 2018-02-05T00:00:00+00:00) 2018_05
CREATE TABLE ${table}_2018_05 (
    CHECK ( acp_ts >= 1517184000 and acp_ts < 1517788800 )
) INHERITS (${table});


CREATE OR REPLACE FUNCTION ${table}_insert_trigger()
RETURNS TRIGGER AS \$\$
BEGIN
    IF ( NEW.acp_ts >= 1507507200 AND
            NEW.acp_ts < 1508112000 ) THEN
       INSERT INTO ${table}_2017_41 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1508112000 AND
            NEW.acp_ts < 1508716800 ) THEN
       INSERT INTO ${table}_2017_42 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1508716800 AND
            NEW.acp_ts < 1509321600 ) THEN
       INSERT INTO ${table}_2017_43 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1509321600 AND
            NEW.acp_ts < 1509926400 ) THEN
       INSERT INTO ${table}_2017_44 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1509926400 AND
            NEW.acp_ts < 1510531200 ) THEN
       INSERT INTO ${table}_2017_45 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1510531200 AND
            NEW.acp_ts < 1511136000 ) THEN
       INSERT INTO ${table}_2017_46 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1511136000 AND
            NEW.acp_ts < 1511740800 ) THEN
       INSERT INTO ${table}_2017_47 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1511740800 AND
            NEW.acp_ts < 1512345600 ) THEN
       INSERT INTO ${table}_2017_48 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1512345600 AND
            NEW.acp_ts < 1512950400 ) THEN
       INSERT INTO ${table}_2017_49 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1512950400 AND
            NEW.acp_ts < 1513555200 ) THEN
       INSERT INTO ${table}_2017_50 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1513555200 AND
            NEW.acp_ts < 1514160000 ) THEN
       INSERT INTO ${table}_2017_51 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1514160000 AND
            NEW.acp_ts < 1514764800 ) THEN
       INSERT INTO ${table}_2017_52 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1514764800 AND
            NEW.acp_ts < 1515369600 ) THEN
       INSERT INTO ${table}_2018_01 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1515369600 AND
            NEW.acp_ts < 1515974400 ) THEN
       INSERT INTO ${table}_2018_02 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1515974400 AND
            NEW.acp_ts < 1516579200 ) THEN
       INSERT INTO ${table}_2018_03 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1516579200 AND
            NEW.acp_ts < 1517184000 ) THEN
       INSERT INTO ${table}_2018_04 VALUES (NEW.*);
    ELSIF ( NEW.acp_ts >= 1517184000 AND
            NEW.acp_ts < 1517788800 ) THEN
       INSERT INTO ${table}_2018_05 VALUES (NEW.*);
    ELSE
        RAISE EXCEPTION 'Date out of range.  Fix the ${table}_insert_trigger() function!';
    END IF;
    RETURN NULL;
END;
\$\$
LANGUAGE plpgsql;

CREATE TRIGGER insert_${table}_trigger
    BEFORE INSERT ON ${table}
    FOR EACH ROW EXECUTE PROCEDURE ${table}_insert_trigger();

\copy ${table} (acp_id, acp_lng, acp_lat, acp_ts, location2d, location4d, info) FROM PROGRAM './"${loader}" "${load_path}"' (FORMAT CSV, FREEZE TRUE)

CREATE INDEX ${table}_2017_41_acp_id ON ${table}_2017_41 (acp_id);
CREATE INDEX ${table}_2017_41_acp_lng ON ${table}_2017_41 (acp_lng);
CREATE INDEX ${table}_2017_41_acp_lat ON ${table}_2017_41 (acp_lat);
CREATE INDEX ${table}_2017_41_acp_ts ON ${table}_2017_41 (acp_ts);
CREATE INDEX ${table}_2017_41_location2d on ${table}_2017_41 USING GIST (location2d);
CREATE INDEX ${table}_2017_41_location2d_geom on ${table}_2017_41 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_41_location4d on ${table}_2017_41 USING GIST (location4d);
CREATE INDEX ${table}_2017_41_location4d_geom_nd on ${table}_2017_41 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_41_info ON ${table}_2017_41 USING GIN (info);

CREATE INDEX ${table}_2017_42_acp_id ON ${table}_2017_42 (acp_id);
CREATE INDEX ${table}_2017_42_acp_lng ON ${table}_2017_42 (acp_lng);
CREATE INDEX ${table}_2017_42_acp_lat ON ${table}_2017_42 (acp_lat);
CREATE INDEX ${table}_2017_42_acp_ts ON ${table}_2017_42 (acp_ts);
CREATE INDEX ${table}_2017_42_location2d on ${table}_2017_42 USING GIST (location2d);
CREATE INDEX ${table}_2017_42_location2d_geom on ${table}_2017_42 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_42_location4d on ${table}_2017_42 USING GIST (location4d);
CREATE INDEX ${table}_2017_42_location4d_geom_nd on ${table}_2017_42 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_42_info ON ${table}_2017_42 USING GIN (info);

CREATE INDEX ${table}_2017_43_acp_id ON ${table}_2017_43 (acp_id);
CREATE INDEX ${table}_2017_43_acp_lng ON ${table}_2017_43 (acp_lng);
CREATE INDEX ${table}_2017_43_acp_lat ON ${table}_2017_43 (acp_lat);
CREATE INDEX ${table}_2017_43_acp_ts ON ${table}_2017_43 (acp_ts);
CREATE INDEX ${table}_2017_43_location2d on ${table}_2017_43 USING GIST (location2d);
CREATE INDEX ${table}_2017_43_location2d_geom on ${table}_2017_43 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_43_location4d on ${table}_2017_43 USING GIST (location4d);
CREATE INDEX ${table}_2017_43_location4d_geom_nd on ${table}_2017_43 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_43_info ON ${table}_2017_43 USING GIN (info);

CREATE INDEX ${table}_2017_44_acp_id ON ${table}_2017_44 (acp_id);
CREATE INDEX ${table}_2017_44_acp_lng ON ${table}_2017_44 (acp_lng);
CREATE INDEX ${table}_2017_44_acp_lat ON ${table}_2017_44 (acp_lat);
CREATE INDEX ${table}_2017_44_acp_ts ON ${table}_2017_44 (acp_ts);
CREATE INDEX ${table}_2017_44_location2d on ${table}_2017_44 USING GIST (location2d);
CREATE INDEX ${table}_2017_44_location2d_geom on ${table}_2017_44 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_44_location4d on ${table}_2017_44 USING GIST (location4d);
CREATE INDEX ${table}_2017_44_location4d_geom_nd on ${table}_2017_44 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_44_info ON ${table}_2017_44 USING GIN (info);

CREATE INDEX ${table}_2017_45_acp_id ON ${table}_2017_45 (acp_id);
CREATE INDEX ${table}_2017_45_acp_lng ON ${table}_2017_45 (acp_lng);
CREATE INDEX ${table}_2017_45_acp_lat ON ${table}_2017_45 (acp_lat);
CREATE INDEX ${table}_2017_45_acp_ts ON ${table}_2017_45 (acp_ts);
CREATE INDEX ${table}_2017_45_location2d on ${table}_2017_45 USING GIST (location2d);
CREATE INDEX ${table}_2017_45_location2d_geom on ${table}_2017_45 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_45_location4d on ${table}_2017_45 USING GIST (location4d);
CREATE INDEX ${table}_2017_45_location4d_geom_nd on ${table}_2017_45 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_45_info ON ${table}_2017_45 USING GIN (info);

CREATE INDEX ${table}_2017_46_acp_id ON ${table}_2017_46 (acp_id);
CREATE INDEX ${table}_2017_46_acp_lng ON ${table}_2017_46 (acp_lng);
CREATE INDEX ${table}_2017_46_acp_lat ON ${table}_2017_46 (acp_lat);
CREATE INDEX ${table}_2017_46_acp_ts ON ${table}_2017_46 (acp_ts);
CREATE INDEX ${table}_2017_46_location2d on ${table}_2017_46 USING GIST (location2d);
CREATE INDEX ${table}_2017_46_location2d_geom on ${table}_2017_46 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_46_location4d on ${table}_2017_46 USING GIST (location4d);
CREATE INDEX ${table}_2017_46_location4d_geom_nd on ${table}_2017_46 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_46_info ON ${table}_2017_46 USING GIN (info);

CREATE INDEX ${table}_2017_47_acp_id ON ${table}_2017_47 (acp_id);
CREATE INDEX ${table}_2017_47_acp_lng ON ${table}_2017_47 (acp_lng);
CREATE INDEX ${table}_2017_47_acp_lat ON ${table}_2017_47 (acp_lat);
CREATE INDEX ${table}_2017_47_acp_ts ON ${table}_2017_47 (acp_ts);
CREATE INDEX ${table}_2017_47_location2d on ${table}_2017_47 USING GIST (location2d);
CREATE INDEX ${table}_2017_47_location2d_geom on ${table}_2017_47 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_47_location4d on ${table}_2017_47 USING GIST (location4d);
CREATE INDEX ${table}_2017_47_location4d_geom_nd on ${table}_2017_47 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_47_info ON ${table}_2017_47 USING GIN (info);

CREATE INDEX ${table}_2017_48_acp_id ON ${table}_2017_48 (acp_id);
CREATE INDEX ${table}_2017_48_acp_lng ON ${table}_2017_48 (acp_lng);
CREATE INDEX ${table}_2017_48_acp_lat ON ${table}_2017_48 (acp_lat);
CREATE INDEX ${table}_2017_48_acp_ts ON ${table}_2017_48 (acp_ts);
CREATE INDEX ${table}_2017_48_location2d on ${table}_2017_48 USING GIST (location2d);
CREATE INDEX ${table}_2017_48_location2d_geom on ${table}_2017_48 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_48_location4d on ${table}_2017_48 USING GIST (location4d);
CREATE INDEX ${table}_2017_48_location4d_geom_nd on ${table}_2017_48 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_48_info ON ${table}_2017_48 USING GIN (info);

CREATE INDEX ${table}_2017_49_acp_id ON ${table}_2017_49 (acp_id);
CREATE INDEX ${table}_2017_49_acp_lng ON ${table}_2017_49 (acp_lng);
CREATE INDEX ${table}_2017_49_acp_lat ON ${table}_2017_49 (acp_lat);
CREATE INDEX ${table}_2017_49_acp_ts ON ${table}_2017_49 (acp_ts);
CREATE INDEX ${table}_2017_49_location2d on ${table}_2017_49 USING GIST (location2d);
CREATE INDEX ${table}_2017_49_location2d_geom on ${table}_2017_49 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_49_location4d on ${table}_2017_49 USING GIST (location4d);
CREATE INDEX ${table}_2017_49_location4d_geom_nd on ${table}_2017_49 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_49_info ON ${table}_2017_49 USING GIN (info);

CREATE INDEX ${table}_2017_50_acp_id ON ${table}_2017_50 (acp_id);
CREATE INDEX ${table}_2017_50_acp_lng ON ${table}_2017_50 (acp_lng);
CREATE INDEX ${table}_2017_50_acp_lat ON ${table}_2017_50 (acp_lat);
CREATE INDEX ${table}_2017_50_acp_ts ON ${table}_2017_50 (acp_ts);
CREATE INDEX ${table}_2017_50_location2d on ${table}_2017_50 USING GIST (location2d);
CREATE INDEX ${table}_2017_50_location2d_geom on ${table}_2017_50 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_50_location4d on ${table}_2017_50 USING GIST (location4d);
CREATE INDEX ${table}_2017_50_location4d_geom_nd on ${table}_2017_50 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_50_info ON ${table}_2017_50 USING GIN (info);

CREATE INDEX ${table}_2017_51_acp_id ON ${table}_2017_51 (acp_id);
CREATE INDEX ${table}_2017_51_acp_lng ON ${table}_2017_51 (acp_lng);
CREATE INDEX ${table}_2017_51_acp_lat ON ${table}_2017_51 (acp_lat);
CREATE INDEX ${table}_2017_51_acp_ts ON ${table}_2017_51 (acp_ts);
CREATE INDEX ${table}_2017_51_location2d on ${table}_2017_51 USING GIST (location2d);
CREATE INDEX ${table}_2017_51_location2d_geom on ${table}_2017_51 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_51_location4d on ${table}_2017_51 USING GIST (location4d);
CREATE INDEX ${table}_2017_51_location4d_geom_nd on ${table}_2017_51 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_51_info ON ${table}_2017_51 USING GIN (info);

CREATE INDEX ${table}_2017_52_acp_id ON ${table}_2017_52 (acp_id);
CREATE INDEX ${table}_2017_52_acp_lng ON ${table}_2017_52 (acp_lng);
CREATE INDEX ${table}_2017_52_acp_lat ON ${table}_2017_52 (acp_lat);
CREATE INDEX ${table}_2017_52_acp_ts ON ${table}_2017_52 (acp_ts);
CREATE INDEX ${table}_2017_52_location2d on ${table}_2017_52 USING GIST (location2d);
CREATE INDEX ${table}_2017_52_location2d_geom on ${table}_2017_52 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2017_52_location4d on ${table}_2017_52 USING GIST (location4d);
CREATE INDEX ${table}_2017_52_location4d_geom_nd on ${table}_2017_52 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2017_52_info ON ${table}_2017_52 USING GIN (info);

CREATE INDEX ${table}_2018_01_acp_id ON ${table}_2018_01 (acp_id);
CREATE INDEX ${table}_2018_01_acp_lng ON ${table}_2018_01 (acp_lng);
CREATE INDEX ${table}_2018_01_acp_lat ON ${table}_2018_01 (acp_lat);
CREATE INDEX ${table}_2018_01_acp_ts ON ${table}_2018_01 (acp_ts);
CREATE INDEX ${table}_2018_01_location2d on ${table}_2018_01 USING GIST (location2d);
CREATE INDEX ${table}_2018_01_location2d_geom on ${table}_2018_01 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2018_01_location4d on ${table}_2018_01 USING GIST (location4d);
CREATE INDEX ${table}_2018_01_location4d_geom_nd on ${table}_2018_01 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2018_01_info ON ${table}_2018_01 USING GIN (info);

CREATE INDEX ${table}_2018_02_acp_id ON ${table}_2018_02 (acp_id);
CREATE INDEX ${table}_2018_02_acp_lng ON ${table}_2018_02 (acp_lng);
CREATE INDEX ${table}_2018_02_acp_lat ON ${table}_2018_02 (acp_lat);
CREATE INDEX ${table}_2018_02_acp_ts ON ${table}_2018_02 (acp_ts);
CREATE INDEX ${table}_2018_02_location2d on ${table}_2018_02 USING GIST (location2d);
CREATE INDEX ${table}_2018_02_location2d_geom on ${table}_2018_02 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2018_02_location4d on ${table}_2018_02 USING GIST (location4d);
CREATE INDEX ${table}_2018_02_location4d_geom_nd on ${table}_2018_02 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2018_02_info ON ${table}_2018_02 USING GIN (info);

CREATE INDEX ${table}_2018_03_acp_id ON ${table}_2018_03 (acp_id);
CREATE INDEX ${table}_2018_03_acp_lng ON ${table}_2018_03 (acp_lng);
CREATE INDEX ${table}_2018_03_acp_lat ON ${table}_2018_03 (acp_lat);
CREATE INDEX ${table}_2018_03_acp_ts ON ${table}_2018_03 (acp_ts);
CREATE INDEX ${table}_2018_03_location2d on ${table}_2018_03 USING GIST (location2d);
CREATE INDEX ${table}_2018_03_location2d_geom on ${table}_2018_03 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2018_03_location4d on ${table}_2018_03 USING GIST (location4d);
CREATE INDEX ${table}_2018_03_location4d_geom_nd on ${table}_2018_03 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2018_03_info ON ${table}_2018_03 USING GIN (info);

CREATE INDEX ${table}_2018_04_acp_id ON ${table}_2018_04 (acp_id);
CREATE INDEX ${table}_2018_04_acp_lng ON ${table}_2018_04 (acp_lng);
CREATE INDEX ${table}_2018_04_acp_lat ON ${table}_2018_04 (acp_lat);
CREATE INDEX ${table}_2018_04_acp_ts ON ${table}_2018_04 (acp_ts);
CREATE INDEX ${table}_2018_04_location2d on ${table}_2018_04 USING GIST (location2d);
CREATE INDEX ${table}_2018_04_location2d_geom on ${table}_2018_04 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2018_04_location4d on ${table}_2018_04 USING GIST (location4d);
CREATE INDEX ${table}_2018_04_location4d_geom_nd on ${table}_2018_04 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2018_04_info ON ${table}_2018_04 USING GIN (info);

CREATE INDEX ${table}_2018_05_acp_id ON ${table}_2018_05 (acp_id);
CREATE INDEX ${table}_2018_05_acp_lng ON ${table}_2018_05 (acp_lng);
CREATE INDEX ${table}_2018_05_acp_lat ON ${table}_2018_05 (acp_lat);
CREATE INDEX ${table}_2018_05_acp_ts ON ${table}_2018_05 (acp_ts);
CREATE INDEX ${table}_2018_05_location2d on ${table}_2018_05 USING GIST (location2d);
CREATE INDEX ${table}_2018_05_location2d_geom on ${table}_2018_05 USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_2018_05_location4d on ${table}_2018_05 USING GIST (location4d);
CREATE INDEX ${table}_2018_05_location4d_geom_nd on ${table}_2018_05 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_2018_05_info ON ${table}_2018_05 USING GIN (info);

COMMIT;

EOF

