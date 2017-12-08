# Database query tests for various TFC siri_vm tables

Using siri\_vm
=============

```
                                    Table "public.siri_vm"
   Column   |           Type           |                      Modifiers
------------+--------------------------+------------------------------------------------------
 id         | bigint                   | not null default nextval('siri_vm_id_seq'::regclass)
 acp_id     | text                     |
 location4d | geography(PointZM,4326)  |
 acp_ts     | timestamp with time zone |
 info       | jsonb                    |
 file_ts    | timestamp with time zone |
Indexes:
    "siri_vm_pkey" PRIMARY KEY, btree (id)
    "siri_vm_acp_id" btree (acp_id)
    "siri_vm_info" gin (info)
    "siri_vm_location4d" gist (location4d::geometry)
    "siri_vm_ts" btree (acp_ts)
```

populated with 31,589,550 rows containing SIRI-VM data from 2017-10-11
14:16:48+01 to 2017-11-27 17:18:12+00

Small box
---------

The box is this:
http://bboxfinder.com/#52.205029,0.080080,52.215548,0.108576 (roughly
Maddingly Road inbound). Returns about 30,000 records

```execute
select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry)
```

Small box and one day
---------------------

Add in a 24 hour time constraint:

```execute
select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

One day
-------

Try just retrieving a full day's data:

```execute
select info from siri_vm where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

Big box and one day
-------------------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000

```execute
select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

Big box, one day and acp\_id
---------------------------

acp\_id has it's own column and index

```execute
select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
```

Big box, one day and "VehicleRef"
---------------------------------

Try using info @> '{"VehicleRef": "WP-106"} instead

```execute
select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}';
```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

```execute
select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
```

Using siri\_vm2
==============

```
                                        Table "public.siri_vm2"
       Column        |           Type           |                       Modifiers
---------------------+--------------------------+-------------------------------------------------------
 id                  | bigint                   | not null default nextval('siri_vm2_id_seq'::regclass)
 file_ts             | timestamp with time zone | not null
 acp_id              | character(20)            | not null
 acp_ts              | timestamp with time zone | not null
 location4d          | geometry(PointZM,27700)  |
 line_ref            | character(10)            | not null
 origin_ref          | character(20)            | not null
 origin_departure_ts | timestamp with time zone | not null
 info                | jsonb                    | not null
 temp_geom           | geometry(PointZM,4326)   | not null
Indexes:
    "siri_vm2_pkey" PRIMARY KEY, btree (id)
    "siri_vm2_acp_id" btree (acp_id)
    "siri_vm2_acp_ts" btree (acp_ts)
    "siri_vm2_line_ref" btree (line_ref)
    "siri_vm2_location4d" gist (location4d)
    "siri_vm2_origin_departure_ts" btree (origin_departure_ts)
    "siri_vm2_origin_ref" btree (origin_ref)
```

Changes of note:

* location4d now a SRID27700 GEOMETRY 
* VehicleID (as acp\_id), line\_ref, origin\_ref, origin\_departure\_ts
  broken out into their own index
* no index on info

Small box
---------

```execute
select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326),27700) ~ location4d);
```

Small box and one day
---------------------

```execute
select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326), 27700) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

One day
-------

```execute
select info from siri_vm2 where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

Big box and one day
-------------------

```execute
select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326),27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

Big box, one day and acp\_id
---------------------------

```execute
select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
```

Big box, one day and "VehicleRef"
---------------------------------

Try using the (unindexed) `info @> '{"VehicleRef": "WP-106"}'`

```execute
select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}';
```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

Try using the (unindexed) `info @> '{"VehicleRef": "WP-106"}' and info @> '{"LineRef": "U"}'`

```execute
select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
```

Big box, one day, acp\_id and line\_ref
-------------------------------------

Using indexed columns acp\_id and line\_ref

```execute
select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106' and line_ref = 'U';
```
