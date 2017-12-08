# Database query tests for various TFC siri_vm tables

The bounding box is roughly Sawston <-> Cotenham, Camborne <-> Fulbourn: 
[http://bboxfinder.com/#52.110000,-0.100000,52.300000,0.250000](http://bboxfinder.com/#52.110000,-0.100000,52.300000,0.250000)

Using siri\_vm
==============

```
CREATE TABLE siri_vm (
    id                       BIGSERIAL PRIMARY KEY,
    acp_id                   TEXT,
    location4d               GEOGRAPHY(POINTZM,4326),
    acp_ts                   TIMESTAMP WITH TIME ZONE,
    info                     JSONB,
    file_ts                  TIMESTAMP WITH TIME ZONE
   );

CREATE INDEX siri_vm_acp_id ON siri_vm (acp_id);
CREATE INDEX siri_vm_location4d ON siri_vm USING GIST ((location4d::geometry));
CREATE INDEX siri_vm_acp_ts ON siri_vm (acp_ts);
CREATE INDEX siri_vm_info ON siri_vm USING GIN (info);
```

```execute
select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
```

Using siri\_vm2
===============

```
REATE TABLE siri_vm2 (
    id                       BIGSERIAL NOT NULL,
    file_ts                  TIMESTAMP WITH TIME ZONE NOT NULL,
    acp_id                   CHAR(20) NOT NULL,
    acp_ts                   TIMESTAMP WITH TIME ZONE NOT NULL,
    location4d               GEOMETRY(POINTZM,27700),
    line_ref                 CHAR(10) NOT NULL,
    origin_ref               CHAR(20) NOT NULL,
    origin_departure_ts      TIMESTAMP WITH TIME ZONE NOT NULL,
    info                     JSONB NOT NULL,
    temp_geom                GEOMETRY(POINTZM,4326) NOT NULL
   );

CREATE UNIQUE INDEX siri_vm2_pkey ON siri_vm2 (id);
ALTER TABLE siri_vm2 ADD PRIMARY KEY USING INDEX siri_vm2_pkey;
CREATE INDEX siri_vm2_acp_id ON siri_vm2 (acp_id);
CREATE INDEX siri_vm2_acp_ts ON siri_vm2 (acp_ts);
CREATE INDEX siri_vm2_location4d ON siri_vm2 USING GIST (location4d);
CREATE INDEX siri_vm2_line_ref ON siri_vm2 (line_ref);
CREATE INDEX siri_vm2_origin_ref ON siri_vm2 (origin_ref);
CREATE INDEX siri_vm2_origin_departure_ts ON siri_vm2 (origin_departure_ts);
```

Changes from siri_vm:

* `location4d` now a SRID27700 GEOMETRY 
* `VehicleID` (as `acp_id`), `line_ref`, `origin_ref`, `origin_departure_ts`
  broken out into their own index
* No index on `info`
* `temp_geom` just used to load `location4d`: `update siri_vm2 set location4d = ST_Transform(temp_geom, 27700);`

```execute
select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
```

Using siri\_vm\_4
===============

```
CREATE TABLE ${table} (
    acp_id                   CHAR(20) NOT NULL,
    acp_lng                  DOUBLE PRECISION NOT NULL,
    acp_lat                  DOUBLE PRECISION NOT NULL,
    acp_ts                   BIGINT NOT NULL,
    location2d               GEOGRAPHY(POINT,4326) NOT NULL,
    location4d               GEOGRAPHY(POINTZM,4326) NOT NULL,
    info                     JSONB NOT NULL
   );

CREATE INDEX ${table}_acp_id ON ${table} (acp_id);
CREATE INDEX ${table}_acp_lng ON ${table} (acp_lng);
CREATE INDEX ${table}_acp_lat ON ${table} (acp_lat);
CREATE INDEX ${table}_acp_ts ON ${table} (acp_ts);
CREATE INDEX ${table}_location2d on ${table} USING GIST (location2d);
CREATE INDEX ${table}_location2d_geom on ${table} USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_location4d on ${table} USING GIST (location4d);
CREATE INDEX ${table}_location4d_geom_nd on ${table} USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_info ON ${table} USING GIN (info);
```

Time ranges 
1507762800 = 2017-10-12 00:00:00+01:00, 1507849200 = 2017-10-13 00:00:00+01:00

This schema puts the `acm_*` fields into their own columns and indexes
them, extracts the 2d and 4d positions as geoGRAHPy and indexes those (a
few ways, to  see what happens) and indexes info as a whole. 

Significant
issues are  doing any sort of date extraction from the (string)
`OriginAimedDepartureTime` field, and the fact that location indexes are
all in geoGRAPHy and so can only be used directly with geogRAPHy comparison
operators (which doesn't include '~'). There's also the issue that I've
never managed to get a gist_geometry_ops_nd index to be used for
anything...


```execute
select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';
```

```execute
select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';
```

Using siri\_vm\_5
===============

Exactly the same database as `siri_vm_4`, except partitioned by week.

```execute
select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';
```

```execute
select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';
```
