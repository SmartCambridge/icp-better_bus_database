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

 But still 70 sec! cold. More like 2 sec with a warm cache. With
 work_mem at 2GB, more like 1.1s

Adjusting work_mem helps with lots of in-memory operations. Default
(seems to be) 4GB

Add in a 24 hour time constraint:

```
explain analyse select info from siri_vm where (ST_MakeEnvelope 
    (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~
    location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
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
 Bitmap Heap Scan on siri_vm  (cost=19937.52..23504.39 rows=898 width=739) (actual time=2165.059..2712.268 rows=269210 loops=1)
   Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Index Recheck: 492359
   Heap Blocks: exact=650 lossy=84465
   ->  BitmapAnd  (cost=19937.52..19937.52 rows=898 width=0) (actual time=2164.833..2164.833 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1105.35 rows=31590 width=0) (actual time=1916.180..1916.180 rows=10512610 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_ts  (cost=0.00..18831.47 rows=897891 width=0) (actual time=71.005..71.005 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.264 ms
 Execution time: 2720.730 ms
```

Slower cold.

