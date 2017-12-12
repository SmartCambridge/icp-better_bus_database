
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

Loading times:

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

```
Testing "select info from siri_vm_4 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548
                                                                                               QUERY PLAN                                                                                               
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=86948.70..399889.97 rows=88062 width=739) (actual time=1874.141..260740.242 rows=363275 loops=1)
   Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   Heap Blocks: exact=349629
   ->  BitmapAnd  (cost=86948.70..86948.70 rows=88062 width=0) (actual time=1757.520..1757.520 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_acp_lng  (cost=0.00..23023.52 rows=1097896 width=0) (actual time=543.768..543.768 rows=1131691 loops=1)
               Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_4_acp_lat  (cost=0.00..63880.90 rows=3046433 width=0) (actual time=954.080..954.080 rows=3002448 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
 Planning time: 94.700 ms
 Execution time: 260836.533 ms
(10 rows)


latency average: 1556.459 ms
latency stddev: 27.666 ms

```

```
Testing "select info from siri_vm_4 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry)" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry)
                                                                                                                          QUERY PLAN                                                                                                                           
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=1330.77..142445.69 rows=37981 width=739) (actual time=13802.240..272452.122 rows=363275 loops=1)
   Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   Heap Blocks: exact=349629
   ->  Bitmap Index Scan on siri_vm_4_location2d_geom  (cost=0.00..1321.28 rows=37981 width=0) (actual time=13647.534..13647.534 rows=363275 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
 Planning time: 687.524 ms
 Execution time: 272559.165 ms
(7 rows)


latency average: 206.217 ms
latency stddev: 27.406 ms

```

One day
-------

Try just retrieving a full day's data:

```
Testing "select info from siri_vm_4 where acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=16420.68..1995575.20 rows=773865 width=739) (actual time=168.462..5756.215 rows=792867 loops=1)
   Recheck Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Heap Blocks: exact=88173
   ->  Bitmap Index Scan on siri_vm_4_acp_ts  (cost=0.00..16227.22 rows=773865 width=0) (actual time=141.338..141.338 rows=792867 loops=1)
         Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
 Planning time: 129.737 ms
 Execution time: 5806.032 ms
(7 rows)


latency average: 118.026 ms
latency stddev: 17.749 ms

```

Small box and one day
---------------------

Add in a 24 hour time constraint:

```
Testing "select info from siri_vm_4 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548 and acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548 and acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                                                                         QUERY PLAN                                                                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=103133.48..110243.72 rows=1794 width=739) (actual time=1488.610..7277.932 rows=7968 loops=1)
   Recheck Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   Heap Blocks: exact=7735
   ->  BitmapAnd  (cost=103133.48..103133.48 rows=1794 width=0) (actual time=1483.028..1483.028 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_acp_ts  (cost=0.00..16227.22 rows=773865 width=0) (actual time=141.759..141.759 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         ->  Bitmap Index Scan on siri_vm_4_acp_lng  (cost=0.00..23023.52 rows=1097896 width=0) (actual time=360.077..360.077 rows=1131691 loops=1)
               Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_4_acp_lat  (cost=0.00..63880.90 rows=3046433 width=0) (actual time=949.508..949.508 rows=3002448 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
 Planning time: 120.735 ms
 Execution time: 7280.187 ms
(12 rows)


latency average: 1288.270 ms
latency stddev: 24.990 ms

```

```
Testing "select info from siri_vm_4 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                                                                                                    QUERY PLAN                                                                                                                                                    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=17549.13..20629.26 rows=774 width=739) (actual time=14307.805..19580.101 rows=7968 loops=1)
   Recheck Cond: (('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Heap Blocks: exact=7735
   ->  BitmapAnd  (cost=17549.13..17549.13 rows=774 width=0) (actual time=14270.289..14270.289 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_location2d_geom  (cost=0.00..1321.28 rows=37981 width=0) (actual time=14064.105..14064.105 rows=363275 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         ->  Bitmap Index Scan on siri_vm_4_acp_ts  (cost=0.00..16227.22 rows=773865 width=0) (actual time=138.244..138.244 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
 Planning time: 803.648 ms
 Execution time: 19595.287 ms
(10 rows)


latency average: 213.442 ms
latency stddev: 28.107 ms

```

Big box and one day
-------------------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000

```
Testing "select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                       QUERY PLAN                                                                        
---------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=318896.69..1242506.85 rows=156228 width=739) (actual time=4777.157..10623.799 rows=269210 loops=1)
   Recheck Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (acp_lng >= '-0.1'::double precision) AND (acp_lng <= '0.25'::double precision))
   Filter: ((acp_lat >= '52.11'::double precision) AND (acp_lat <= '52.3'::double precision))
   Rows Removed by Filter: 39518
   Heap Blocks: exact=86714
   ->  BitmapAnd  (cost=318896.69..318896.69 rows=294036 width=0) (actual time=4718.670..4718.670 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_acp_ts  (cost=0.00..16227.22 rows=773865 width=0) (actual time=141.639..141.639 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         ->  Bitmap Index Scan on siri_vm_4_acp_lng  (cost=0.00..302591.12 rows=14431055 width=0) (actual time=4547.026..4547.026 rows=14489334 loops=1)
               Index Cond: ((acp_lng >= '-0.1'::double precision) AND (acp_lng <= '0.25'::double precision))
 Planning time: 120.608 ms
 Execution time: 10646.938 ms
(12 rows)


latency average: 4458.203 ms
latency stddev: 46.405 ms

```

```
Testing "select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                                                                                                    QUERY PLAN                                                                                                                                                    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=17549.13..20629.26 rows=774 width=739) (actual time=451913.299..457150.274 rows=269210 loops=1)
   Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Heap Blocks: exact=85220
   ->  BitmapAnd  (cost=17549.13..17549.13 rows=774 width=0) (actual time=451869.175..451869.175 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_location2d_geom  (cost=0.00..1321.28 rows=37981 width=0) (actual time=450979.187..450979.187 rows=12639959 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry)
         ->  Bitmap Index Scan on siri_vm_4_acp_ts  (cost=0.00..16227.22 rows=773865 width=0) (actual time=139.712..139.712 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
 Planning time: 711.998 ms
 Execution time: 457193.185 ms
(10 rows)


latency average: 5090.329 ms
latency stddev: 38.051 ms

```

Big box, one day and acp\_id
---------------------------

acp\_id has it's own column and index. This is the IJL 'indicitave' query

```
Testing "select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';
                                                                                    QUERY PLAN                                                                                    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=17533.85..21404.47 rows=196 width=739) (actual time=225.526..5337.461 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::bpchar) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision))
   Heap Blocks: exact=2449
   ->  BitmapAnd  (cost=17533.85..17533.85 rows=972 width=0) (actual time=213.854..213.854 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_acp_id  (cost=0.00..1306.29 rows=47696 width=0) (actual time=56.375..56.375 rows=79114 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
         ->  Bitmap Index Scan on siri_vm_4_acp_ts  (cost=0.00..16227.22 rows=773865 width=0) (actual time=143.234..143.234 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
 Planning time: 129.162 ms
 Execution time: 5339.071 ms
(11 rows)


latency average: 89.356 ms
latency stddev: 21.652 ms

```

```
Testing "select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';
                                                                                                                                         QUERY PLAN                                                                                                                                          
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=2627.81..2820.41 rows=1 width=739) (actual time=596547.492..645834.677 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::bpchar) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
   Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Rows Removed by Filter: 76661
   Heap Blocks: exact=79033
   ->  BitmapAnd  (cost=2627.81..2627.81 rows=48 width=0) (actual time=450440.814..450440.814 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_acp_id  (cost=0.00..1306.29 rows=47696 width=0) (actual time=61.300..61.300 rows=79114 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
         ->  Bitmap Index Scan on siri_vm_4_location2d_geom  (cost=0.00..1321.28 rows=37981 width=0) (actual time=450342.941..450342.941 rows=12639959 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry)
 Planning time: 711.663 ms
 Execution time: 645848.581 ms
(12 rows)


latency average: 4433.860 ms
latency stddev: 46.064 ms

```

Big box, one day and "VehicleRef" in place of acp\_id
----------------------------------------------------

Try using info @> '{"VehicleRef": "WP-107"} instead

```
Testing "select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';
                                                                                    QUERY PLAN                                                                                    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=16616.40..19702.34 rows=156 width=739) (actual time=763.236..6066.737 rows=2453 loops=1)
   Recheck Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision))
   Heap Blocks: exact=2449
   ->  BitmapAnd  (cost=16616.40..16616.40 rows=774 width=0) (actual time=717.813..717.813 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_info  (cost=0.00..388.85 rows=37981 width=0) (actual time=563.689..563.689 rows=79114 loops=1)
               Index Cond: (info @> '{"VehicleRef": "WP-106"}'::jsonb)
         ->  Bitmap Index Scan on siri_vm_4_acp_ts  (cost=0.00..16227.22 rows=773865 width=0) (actual time=140.281..140.281 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
 Planning time: 135.939 ms
 Execution time: 6068.402 ms
(11 rows)


latency average: 210.395 ms
latency stddev: 10.877 ms

```


```
Testing "select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';
                                                                                                                                                 QUERY PLAN                                                                                                                                                  
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=1710.38..1862.90 rows=1 width=739) (actual time=597105.815..646259.654 rows=2453 loops=1)
   Recheck Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
   Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Rows Removed by Filter: 76661
   Heap Blocks: exact=79033
   ->  BitmapAnd  (cost=1710.38..1710.38 rows=38 width=0) (actual time=450974.448..450974.448 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_info  (cost=0.00..388.85 rows=37981 width=0) (actual time=572.376..572.376 rows=79114 loops=1)
               Index Cond: (info @> '{"VehicleRef": "WP-106"}'::jsonb)
         ->  Bitmap Index Scan on siri_vm_4_location2d_geom  (cost=0.00..1321.28 rows=37981 width=0) (actual time=450365.150..450365.150 rows=12639959 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry)
 Planning time: 750.785 ms
 Execution time: 646269.619 ms
(12 rows)


latency average: 4619.271 ms
latency stddev: 57.872 ms

```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

```
Testing "select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
                                                                                                              QUERY PLAN                                                                                                               
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=100.38..253.18 rows=1 width=739) (actual time=149173.918..198136.064 rows=2453 loops=1)
   Recheck Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
   Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Rows Removed by Filter: 76661
   Heap Blocks: exact=79033
   ->  Bitmap Index Scan on siri_vm_4_info  (cost=0.00..100.38 rows=38 width=0) (actual time=1250.494..1250.494 rows=79114 loops=1)
         Index Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
 Planning time: 135.903 ms
 Execution time: 198137.830 ms
(9 rows)


latency average: 545.761 ms
latency stddev: 30.189 ms

```

```
Testing "select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
                                                                                                                                                 QUERY PLAN                                                                                                                                                 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=100.38..252.99 rows=1 width=739) (actual time=148565.718..197711.300 rows=2453 loops=1)
   Recheck Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
   Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
   Rows Removed by Filter: 76661
   Heap Blocks: exact=79033
   ->  Bitmap Index Scan on siri_vm_4_info  (cost=0.00..100.38 rows=38 width=0) (actual time=1297.056..1297.056 rows=79114 loops=1)
         Index Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
 Planning time: 725.853 ms
 Execution time: 197712.987 ms
(9 rows)


latency average: 539.551 ms
latency stddev: 37.996 ms

```
