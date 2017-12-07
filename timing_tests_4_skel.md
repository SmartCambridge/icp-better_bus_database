
Using siri\_vm\_4
=============

```
             Table "public.siri_vm_4"
   Column   |          Type           | Modifiers
------------+-------------------------+-----------
 acp_id     | character(20)           | not null
 acp_lng    | double precision        | not null
 acp_lat    | double precision        | not null
 acp_ts     | bigint                  | not null
 location2d | geography(Point,4326)   | not null
 location4d | geography(PointZM,4326) | not null
 info       | jsonb                   | not null
Indexes:
    "siri_vm_4_acp_id" btree (acp_id)
    "siri_vm_4_acp_lat" btree (acp_lat)
    "siri_vm_4_acp_lng" btree (acp_lng)
    "siri_vm_4_acp_ts" btree (acp_ts)
    "siri_vm_4_info" gin (info)
    "siri_vm_4_location2d" gist (location2d)
    "siri_vm_4_location2d_geom" gist ((location2d::geometry))
    "siri_vm_4_location4d" gist (location4d)
    "siri_vm_4_location4d_geom_nd" gist ((location4d::geometry) gist_geometry_ops_nd)
```

```
BEGIN;
BEGIN
Time: 0.029 ms
DROP TABLE IF EXISTS siri_vm_4;
DROP TABLE
Time: 2.510 ms
CREATE TABLE siri_vm_4 (
    acp_id                   CHAR(20) NOT NULL,
    acp_lng                  DOUBLE PRECISION NOT NULL,
    acp_lat                  DOUBLE PRECISION NOT NULL,
    acp_ts                   BIGINT NOT NULL,
    location2d               GEOGRAPHY(POINT,4326) NOT NULL,
    location4d               GEOGRAPHY(POINTZM,4326) NOT NULL,
    info                     JSONB NOT NULL
   );
CREATE TABLE
Time: 78.548 ms
COPY  siri_vm_4 ( acp_id, acp_lng, acp_lat, acp_ts, location2d, location4d, info ) FROM STDIN (FORMAT CSV, FREEZE TRUE)
COPY 37980678
Time: 11270490.052 ms
CREATE INDEX siri_vm_4_acp_id ON siri_vm_4 (acp_id);
CREATE INDEX
Time: 512786.429 ms
CREATE INDEX siri_vm_4_acp_lng ON siri_vm_4 (acp_lng);
CREATE INDEX
Time: 243200.378 ms
CREATE INDEX siri_vm_4_acp_lat ON siri_vm_4 (acp_lat);
CREATE INDEX
Time: 244180.254 ms
CREATE INDEX siri_vm_4_acp_ts ON siri_vm_4 (acp_ts);
CREATE INDEX
Time: 230895.257 ms
CREATE INDEX siri_vm_4_location2d on siri_vm_4 USING GIST (location2d);
CREATE INDEX
Time: 1551898.345 ms
CREATE INDEX siri_vm_4_location2d_geom on siri_vm_4 USING GIST (cast(location2d as geometry));
CREATE INDEX
Time: 6254793.236 ms
CREATE INDEX siri_vm_4_location4d on siri_vm_4 USING GIST (location4d);
CREATE INDEX
Time: 1615844.516 ms
CREATE INDEX siri_vm_4_location4d_geom_nd on siri_vm_4 USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX
Time: 1521617.369 ms
CREATE INDEX siri_vm_4_info ON siri_vm_4 USING GIN (info);
CREATE INDEX
Time: 2156703.329 ms
COMMIT;
COMMIT
Time: 199.966 ms

real    426m43.106s
user    57m14.116s
sys     4m9.384s
```

Small box
---------

The box is this:
http://bboxfinder.com/#52.205029,0.080080,52.215548,0.108576 (roughly
Maddingly Road inbound). Returns about 30,000 records

"""
select info from siri_vm_4 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548
"""

"""
select info from siri_vm_4 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry)
"""

One day
-------

Try just retrieving a full day's data:

"""
select info from siri_vm_4 where acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz);
"""

Small box and one day
---------------------

Add in a 24 hour time constraint:

"""
select info from siri_vm_4 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548 and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz);
"""

"""
select info from siri_vm_4 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry) and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz);
"""

Big box and one day
-------------------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000

"""
select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz);
"""

"""
select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz);
"""

Big box, one day and acp\_id
---------------------------

acp\_id has it's own column and index. This is the IJL 'indicitave' query

"""
select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz) and acp_id = 'WP-106';
"""

"""
select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz) and acp_id = 'WP-106';
"""

Big box, one day and "VehicleRef" in place of acp\_id
----------------------------------------------------

Try using info @> '{"VehicleRef": "WP-107"} instead

"""
select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz) and info @> '{"VehicleRef" : "WP-107"}';
"""

"""
select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz) and info @> '{"VehicleRef" : "WP-107"}';
"""

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

"""
select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz) and info @> '{"VehicleRef" : "WP-107"}' and info @> '{"LineRef": "U"}';
"""

"""
select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= extract(epoch from '2017-10-12 00:00:00+01:00'::timestamptz) and acp_ts < extract(epoch from '2017-10-13 00:00:00+01:00'::timestamptz) and info @> '{"VehicleRef" : "WP-107"}' and info @> '{"LineRef": "U"}';
"""
