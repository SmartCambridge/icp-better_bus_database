Geo-spatial indexing/searching
==============================

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

Adjusting work_mem helps with lots of in-memory operations. Default
(seems to be) 4GB. With work_mem at 2GB, more like 1.1s

```
set work_mem to '2GB';
```

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

 Try just retrieving a full day's data:

```
 explain analyse select info from siri_vm where acp_ts >= '2017-10-12 12:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
 ```

```
 Index Scan using siri_vm_ts on siri_vm  (cost=0.56..918761.77 rows=410807 width=738) (actual time=0.057..348.011 rows=467263 loops=1)
   Index Cond: ((acp_ts >= '2017-10-12 12:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.122 ms
 Execution time: 366.795 ms
```

Cold took >60 sec, but warm more like 0.3/0.5s

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000

```
explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
```

```
 Bitmap Heap Scan on siri_vm  (cost=19937.52..23504.39 rows=898 width=739) (actual time=4781.731..5074.267 rows=269210 loops=1)
   Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=85109
   ->  BitmapAnd  (cost=19937.52..19937.52 rows=898 width=0) (actual time=4748.800..4748.800 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1105.35 rows=31590 width=0) (actual time=4024.911..4024.911 rows=10512610 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_ts  (cost=0.00..18831.47 rows=897891 width=0) (actual time=65.542..65.542 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.273 ms
 Execution time: 5087.896 ms
```

7 sec cold.

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

Add a LineRef column
--------------------

```
alter table siri_vm add column line_ref text;
update siri_vm set line_ref = info->>'LineRef';
set maintenance_work_mem '2GB';
create index siri_vm_line_ref on siri_vm (line_ref);
```

