
Using siri\_vm\_5
=============

```
             Table "public.siri_vm_5"
   Column    |          Type           | Modifiers
-------------+-------------------------+-----------
 acp_id      | character(20)           | not null
 acp_lng     | double precision        | not null
 acp_lat     | double precision        | not null
 acp_ts      | bigint                  | not null
 location2d  | geography(Point,4326)   | not null
 location4d  | geography(PointZM,4326) | not null
 info        | jsonb                   | not null
 acp_ts_date | date                    |
Triggers:
    insert_siri_vm_5_trigger BEFORE INSERT ON siri_vm_5 FOR EACH ROW EXECUTE PROCEDURE siri_vm_5_insert_trigger()
Number of child tables: 17 (Use \d+ to list them.)

         Table "public.siri_vm_5_2017_41"
   Column    |          Type           | Modifiers
-------------+-------------------------+-----------
 acp_id      | character(20)           | not null
 acp_lng     | double precision        | not null
 acp_lat     | double precision        | not null
 acp_ts      | bigint                  | not null
 location2d  | geography(Point,4326)   | not null
 location4d  | geography(PointZM,4326) | not null
 info        | jsonb                   | not null
 acp_ts_date | date                    |
Indexes:
    "siri_vm_5_2017_41_acp_id" btree (acp_id)
    "siri_vm_5_2017_41_acp_lat" btree (acp_lat)
    "siri_vm_5_2017_41_acp_lng" btree (acp_lng)
    "siri_vm_5_2017_41_acp_ts" btree (acp_ts)
    "siri_vm_5_2017_41_info" gin (info)
    "siri_vm_5_2017_41_location2d" gist (location2d)
    "siri_vm_5_2017_41_location2d_geom" gist ((location2d::geometry))
    "siri_vm_5_2017_41_location4d" gist (location4d)
    "siri_vm_5_2017_41_location4d_geom_nd" gist ((location4d::geometry) gist_geometry_ops_nd)
Check constraints:
    "siri_vm_5_2017_41_acp_ts_check" CHECK (acp_ts >= 1507507200 AND acp_ts < 1508112000)
Inherits: siri_vm_5
```

This schema puts the acm\_\* fields into their own columns and indexes
them, extracts the 2d and 4d positions as geoGRAHPy and indexes those (a
few ways, to  see what happens) and indexes info as a whole. Significant
issues are  doing any sort of date extraction from the (string)
OriginAimedDepartureTime field, and the fact that location indexes are
all in geoGRAPHy and so can only be used with  geogRAPHy comparison
operators (which doesn't include '~'). There's also the issue that I've
never managed to get a gist_geometry_ops_nd index to be used for
anything...

Generally end up using e.g. `ST_MakeEnvelope (0.08008, 52.205029,
0.108576, 52.215548, 4326) ~ location2d::geometry` for containment tests. Time ranges 
1507762800 = 2017-10-12 00:00:00+01:00, 1507849200 = 2017-10-13 00:00:00+01:00


Small box
---------

The box is this:
http://bboxfinder.com/#52.205029,0.080080,52.215548,0.108576 (roughly
Maddingly Road inbound). Returns about 30,000 records

```execute
select info from siri_vm_5 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548
```

```execute
select info from siri_vm_5 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry)
```

One day
-------

Try just retrieving a full day's data:

```execute
select info from siri_vm_5 where acp_ts >= 1507762800 and acp_ts < 1507849200;
```

Small box and one day
---------------------

Add in a 24 hour time constraint:

```execute
select info from siri_vm_5 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548 and acp_ts >= 1507762800 and acp_ts < 1507849200;
```

```execute
select info from siri_vm_5 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;
```

Big box and one day
-------------------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000
http://bboxfinder.com/#52.110000,-0.100000,52.300000,0.250000

```execute
select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200;
```

```execute
select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;
```

Big box, one day and acp\_id
---------------------------

acp\_id has it's own column and index. This is the IJL 'indicitave' query

```execute
select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';
```

```execute
select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';
```

Big box, one day and "VehicleRef" in place of acp\_id
----------------------------------------------------

Try using info @> '{"VehicleRef": "WP-107"} instead

```execute
select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';
```


```execute
select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';
```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

```execute
select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
```

```execute
select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
```
