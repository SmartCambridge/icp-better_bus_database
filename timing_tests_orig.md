Geo-spatial indexing/searching
==============================

First schema
============

Starts with this table of tfc-app4:

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
    "siri_vm_location4d" gist (location4d)
    "siri_vm_ts" btree (acp_ts)
```

populated with 31,589,550 rows containing SIRI-VM data from 2017-10-11
14:16:48+01 to 2017-11-27 17:18:12+00

Just a box
----------

```
explain select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry);
```

The box is this:
http://bboxfinder.com/#52.205029,0.080080,52.215548,0.108576 (roughly
Maddingly Road inbound)

```
 Seq Scan on siri_vm  (cost=0.00..3983793.25 rows=31590 width=738)
   Filter: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
```

Note: returns about 30,000 records.

Sequential scan because only location4d is indexed, not
location4d::geometry. But ~ only
works on geometry, so we need

```
create index siri_vm_location4d_geom on siri_vm using gist ((location4d::geometry));
```

```
 Bitmap Heap Scan on siri_vm  (cost=1113.24..118452.48 rows=31590 width=738) (actual time=218.153..70786.350 rows=304784 loops=1)
   Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
   Rows Removed by Index Recheck: 2203505
   Heap Blocks: exact=16364 lossy=276822
   ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1105.35 rows=31590 width=0) (actual time=201.826..201.826 rows=304784 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
 Planning time: 0.137 ms
 Execution time: 70848.536 ms
 ```

But still 70 sec! cold. More like 2 sec with a warm cache.

latency average: 2162.856 ms
latency stddev: 144.521 ms

Adjusting work_mem helps with lots of in-memory operations. Default
(seems to be) 4GB. With work_mem at 2GB, more like 1.1s

```
set work_mem to '2GB';

latency average: 1238.589 ms
latency stddev: 34.042 ms
```


Box and time range
------------------

Add in a 24 hour time constraint:

```
explain analyse select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

```
 Bitmap Heap Scan on siri_vm  (cost=15941.50..18753.54 rows=707 width=738) (actual time=404.564..434.703 rows=7968 loops=1)
   Recheck Cond: (('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=7722
   ->  BitmapAnd  (cost=15941.50..15941.50 rows=707 width=0) (actual time=401.876..401.876 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1105.35 rows=31590 width=0) (actual time=134.298..134.298 rows=304784 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_ts  (cost=0.00..14835.55 rows=707499 width=0) (actual time=195.828..195.828 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 5.840 ms
 Execution time: 435.214 ms
 ```

Somewhere between 0.3 and 0.6s warmed, and about 8000 rows.

Retrieve full day
-----------------

Try just retrieving a full day's data:

```
explain analyse select info from siri_vm where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
 ```

```
 Index Scan using siri_vm_ts on siri_vm  (cost=0.56..2104591.19 rows=990110 width=739) (actual time=9.509..8910.723 rows=792867 loops=1)
   Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 26.191 ms
 Execution time: 8952.538 ms
```

Cold took >60 sec, but warm more like 0.3/0.5s

latency average: 0.637 ms
latency stddev: 0.507 ms

Bigger box
----------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000

```
explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

```
 Bitmap Heap Scan on siri_vm  (cost=22324.08..26256.38 rows=990 width=739) (actual time=396548.236..397134.604 rows=269210 loops=1)
   Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Index Recheck: 492396
   Heap Blocks: exact=632 lossy=84483
   ->  BitmapAnd  (cost=22324.08..22324.08 rows=990 width=0) (actual time=396548.013..396548.013 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=396203.951..396203.951 rows=11581172 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_ts  (cost=0.00..21173.66 rows=990110 width=0) (actual time=135.472..135.472 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.281 ms
 Execution time: 397142.672 ms
```

That was nearly 400 sec  (>6m30)!!!!

latency average: 5388.655 ms
latency stddev: 65.375 ms

Add in acp_id
-------------

[acp_id has it's own column and index]

```
explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
```

```
 Bitmap Heap Scan on siri_vm  (cost=2032.70..2197.20 rows=1 width=739) (actual time=66376.162..66481.637 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::text) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 61723
   Heap Blocks: exact=64117
   ->  BitmapAnd  (cost=2032.70..2032.70 rows=41 width=0) (actual time=4124.902..4124.902 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_acp_id  (cost=0.00..927.10 rows=40872 width=0) (actual time=51.124..51.124 rows=64176 loops=1)
               Index Cond: (acp_id = 'WP-106'::text)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1105.35 rows=31590 width=0) (actual time=4051.389..4051.389 rows=10512610 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
 Planning time: 0.294 ms
 Execution time: 66491.714 ms
 ```

66 sec, but subsequently 7, 6, 6, 9, 9, 5, 5, 7, 7, 8

latency average: 4778.068 ms
latency stddev: 36.656 ms

Try using info @> '{"VehicleRef": "WP-107"} instead:

```
explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}';
 ```

```
  Bitmap Heap Scan on siri_vm  (cost=1438.52..1566.95 rows=1 width=739) (actual time=9309.615..9356.054 rows=2270 loops=1)
   Recheck Cond: ((info @> '{"VehicleRef": "WP-107"}'::jsonb) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 51140
   Heap Blocks: exact=53362
   ->  BitmapAnd  (cost=1438.52..1438.52 rows=32 width=0) (actual time=9148.898..9148.898 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_info  (cost=0.00..332.92 rows=31590 width=0) (actual time=178.296..178.296 rows=53410 loops=1)
               Index Cond: (info @> '{"VehicleRef": "WP-107"}'::jsonb)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1105.35 rows=31590 width=0) (actual time=8950.401..8950.401 rows=10512610 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
 Planning time: 0.376 ms
 Execution time: 9360.919 ms
```

Subsequently 6 9 9 6 9 9 9 9 7 7

latency average: 9830.164 ms
latency stddev: 1749.592 ms

Add in VehicleRef and LineRef
-----------------------------

```
explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}' and info @> '{"LineRef": "U"}';
```

```
 Bitmap Heap Scan on siri_vm  (cost=100.32..228.83 rows=1 width=739) (actual time=443.043..485.343 rows=2270 loops=1)
   Recheck Cond: ((info @> '{"VehicleRef": "WP-107"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry))
   Rows Removed by Filter: 51140
   Heap Blocks: exact=53362
   ->  Bitmap Index Scan on siri_vm_info  (cost=0.00..100.32 rows=32 width=0) (actual time=285.300..285.300 rows=53410 loops=1)
         Index Cond: ((info @> '{"VehicleRef": "WP-107"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
 Planning time: 0.317 ms
 Execution time: 485.458 ms
```

latency average: 393.492 ms
latency stddev: 28.742 ms

Add a LineRef column
--------------------

```
alter table siri_vm add column line_ref text;
update siri_vm set line_ref = info->>'LineRef';
set maintenance_work_mem '2GB';
create index siri_vm_line_ref on siri_vm (line_ref);
```

...except that this takes **for ever** (presumably becasue it has to
rewrite the entire table and all the indexes)

New schema
==========

So, let's try the data ina  new schema:

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
  * VehicleID (as acp_id), line_ref, origin_ref, origin_departure_ts
  broken out into their own index
  * no index on info

Just a box
----------

```
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326),27700) ~ location4d);
```

```
 Bitmap Heap Scan on siri_vm2  (cost=1372.64..162110.93 rows=42351 width=739) (actual time=170.809..218823.582 rows=346609 loops=1)
   Recheck Cond: ('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d)
   Rows Removed by Index Recheck: 2136345
   Heap Blocks: exact=27848 lossy=306840
   ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1362.05 rows=42351 width=0) (actual time=161.446..161.446 rows=346609 loops=1)
         Index Cond: ('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d)
 Planning time: 0.523 ms
 Execution time: 218898.096 ms
 ```

So, testing these with `pgbench tfcapi -n -t 10 -P 5 -f -`

latency average: 3347.923 ms
latency stddev: 70.444 ms

Box and time range
------------------

```
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326), 27700) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

```
 Bitmap Heap Scan on siri_vm2  (cost=18817.98..22438.17 rows=908 width=739) (actual time=331.819..383.104 rows=8206 loops=1)
   Recheck Cond: (('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Index Recheck: 52421
   Heap Blocks: exact=462 lossy=7520
   ->  BitmapAnd  (cost=18817.98..18817.98 rows=908 width=0) (actual time=331.604..331.604 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1362.05 rows=42351 width=0) (actual time=157.156..157.156 rows=346609 loops=1)
               Index Cond: ('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..17455.22 rows=907866 width=0) (actual time=136.274..136.274 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 46.940 ms
 Execution time: 383.706 ms
```

latency average: 661.665 ms
latency stddev: 134.629 ms

Full day
--------

```
explain analyse select info from siri_vm2 where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

```
  Bitmap Heap Scan on siri_vm2  (cost=17682.19..2672390.52 rows=907866 width=739) (actual time=149.188..5279.087 rows=792867 loops=1)
   Recheck Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Index Recheck: 13
   Heap Blocks: exact=46190 lossy=53064
   ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..17455.22 rows=907866 width=0) (actual time=138.007..138.007 rows=792867 loops=1)
         Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.217 ms
 Execution time: 5337.592 ms
```

latency average: 514.223 ms
latency stddev: 30.174 ms

Note BTW that for 12 hours the planner uses a plain index scan

Bigger box
----------

(Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000

```
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326),27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

```
 Bitmap Heap Scan on siri_vm2  (cost=18817.98..22438.17 rows=908 width=739) (actual time=58569.337..59119.304 rows=271161 loops=1)
   Recheck Cond: (('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Index Recheck: 480904
   Heap Blocks: exact=552 lossy=93896
   ->  BitmapAnd  (cost=18817.98..18817.98 rows=908 width=0) (actual time=58569.111..58569.111 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1362.05 rows=42351 width=0) (actual time=58183.704..58183.704 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..17455.22 rows=907866 width=0) (actual time=134.450..134.450 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.601 ms
 Execution time: 59127.608 ms
```

latency average: 5783.180 ms
latency stddev: 64.941 ms

Add in acp_id
-------------

```
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
```

```
 Bitmap Heap Scan on siri_vm2  (cost=2696.44..2917.13 rows=1 width=739) (actual time=140501.509..167049.933 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::bpchar) AND ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 70420
   Heap Blocks: exact=72819
   ->  BitmapAnd  (cost=2696.44..2696.44 rows=55 width=0) (actual time=9666.666..9666.666 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_acp_id  (cost=0.00..1334.14 rows=55143 width=0) (actual time=64.602..64.602 rows=72873 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1362.05 rows=42351 width=0) (actual time=9574.839..9574.839 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
 Planning time: 0.821 ms
 Execution time: 167058.216 ms
 ```

latency average: 5135.257 ms
latency stddev: 48.409 ms

Try using the (unindexed) info @> '{"VehicleRef": "WP-107"}'

```
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}';
```

```
 Bitmap Heap Scan on siri_vm2  (cost=18817.53..22439.99 rows=1 width=739) (actual time=9085.180..9476.801 rows=2270 loops=1)
   Recheck Cond: (('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Filter: (info @> '{"VehicleRef": "WP-107"}'::jsonb)
   Rows Removed by Filter: 268891
   Heap Blocks: exact=94441
   ->  BitmapAnd  (cost=18817.53..18817.53 rows=908 width=0) (actual time=9046.220..9046.220 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1362.05 rows=42351 width=0) (actual time=8123.469..8123.469 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..17455.22 rows=907866 width=0) (actual time=67.291..67.291 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.665 ms
 Execution time: 9484.727 ms
```

latency average: 5676.849 ms
latency stddev: 28.901 ms

Add in VehicleRef and LineRef
-----------------------------

```
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}' and info @> '{"LineRef": "U"}';
```

```
 Bitmap Heap Scan on siri_vm2  (cost=18817.53..22442.26 rows=1 width=739) (actual time=5715.673..6104.843 rows=2270 loops=1)
   Recheck Cond: (('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Filter: ((info @> '{"VehicleRef": "WP-107"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
   Rows Removed by Filter: 268891
   Heap Blocks: exact=94441
   ->  BitmapAnd  (cost=18817.53..18817.53 rows=908 width=0) (actual time=5676.672..5676.672 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1362.05 rows=42351 width=0) (actual time=4752.022..4752.022 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..17455.22 rows=907866 width=0) (actual time=71.151..71.151 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.672 ms
 Execution time: 6113.423 ms
```

latency average: 5687.260 ms
latency stddev: 39.273 ms

```
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-107' and line_ref = 'U';
```

```
 Bitmap Heap Scan on siri_vm2  (cost=2696.44..2917.27 rows=1 width=739) (actual time=96939.861..115951.146 rows=2270 loops=1)
   Recheck Cond: ((acp_id = 'WP-107'::bpchar) AND ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone) AND (line_ref = 'U'::bpchar))
   Rows Removed by Filter: 51140
   Heap Blocks: exact=53366
   ->  BitmapAnd  (cost=2696.44..2696.44 rows=55 width=0) (actual time=4858.979..4858.979 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_acp_id  (cost=0.00..1334.14 rows=55143 width=0) (actual time=39.470..39.470 rows=53410 loops=1)
               Index Cond: (acp_id = 'WP-107'::bpchar)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1362.05 rows=42351 width=0) (actual time=4800.087..4800.087 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
 Planning time: 0.756 ms
 Execution time: 115967.892 ms
```

latency average: 4887.268 ms
latency stddev: 33.414 ms

Trying to use 4-d index
-----------------------

This should match the 'Bigger box' search above:

```
explain
select info from siri_vm2 where
  ST_MakeLine(
    ST_Transform(
      ST_SetSRID(
        ST_MakePoint(
          -0.100000,
          52.110000,
          0,
          EXTRACT (EPOCH from TIMESTAMP WITH TIME ZONE '2017-10-12 00:00:00+01:00')
        ),
        4326
      ),
      27700
    ),
    ST_Transform(
      ST_SetSRID(
        ST_MakePoint(
          0.250000,
          52.300000,
          0,
          EXTRACT (EPOCH from TIMESTAMP WITH TIME ZONE '2017-10-13 00:00:00+01:00')
        ),
        4326
      ),
      27700
    )
  )
  &&&
  location4d;
```

Initial result is

```
 Index Scan using siri_vm2_location4d on siri_vm2  (cost=0.44..14466.76 rows=3561 width=739)
   Index Cond: (st_makeline(st_transform(st_setsrid(st_makepoint('-0.1'::double precision, '52.11'::double precision, '0'::double precision, date_part('epoch'::text, '2017-10-12 00:00:00+01'::timestamp with time zone)), 4326), 27700), st_transform(st_setsrid(st_makepoint('0.25'::double precision, '52.3'::double precision, '0'::double precision, date_part('epoch'::text, '2017-10-13 00:00:00+01'::timestamp with time zone)), 4326), 27700)) &&& location4d)
```

This should be becasue the index needs to be (re-)built with
'gist_geometry_ops_nd', except that doing so causes both && and &&&
searches to fall back to sequential scans. Ugh?

Building the plain index takes 73 minuites, building the
gist_geometry_ops_nd version aparently took only 20?



