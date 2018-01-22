
Using journey
=============

```
                                                Table "public.journey"
      Column      |           Type           | Collation | Nullable |                     Default
------------------+--------------------------+-----------+----------+-------------------------------------------------
 acp_journey_id   | bigint                   |           | not null | nextval('journey_acp_journey_id_seq'::regclass)
 vehicle_ref      | text                     |           | not null |
 destination_ref  | text                     |           | not null |
 destination_name | text                     |           | not null |
 direction_ref    | text                     |           | not null |
 line_ref         | text                     |           | not null |
 operator_ref     | text                     |           | not null |
 departure_time   | timestamp with time zone |           | not null |
 origin_ref       | text                     |           | not null |
 origin_name      | text                     |           | not null |
 pos              | pos_report[]             |           |          |
Indexes:
    "journey_pkey" PRIMARY KEY, btree (acp_journey_id)
```

This schema has one row per journeys (grouped by `VehicleRef`, 
`DestinationRef`, `DirectionRef`, `LineRef`, `OperatorRef`,
`OriginAimedDepartureTime`, `OriginRef`. Other data (`Longitude`, 
`Latitude`, `acp_ts`, `Bearing`, `Delay`, `InPanic`) stored as an array 
of records in `pos`.

Small box
---------

The box is this:
http://bboxfinder.com/#52.205029,0.080080,52.215548,0.108576 (roughly
Maddingly Road inbound). Returns about 30,000 records

```
Testing "select * from journey where enclosing_cube(pos) && cube(array[0.08008,52.205029,'-Infinity'::double precision], array[0.108576,52.215548,'Infinity'::double precision]);" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select * from journey where enclosing_cube(pos) && cube(array[0.08008,52.205029,'-Infinity'::double precision], array[0.108576,52.215548,'Infinity'::double precision]);
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on journey  (cost=124.72..5579.92 rows=1605 width=558) (actual time=1215.521..2008.780 rows=43127 loops=1)
   Recheck Cond: (enclosing_cube(pos) && '(0.08008, 52.205029, -inf),(0.108576, 52.215548, inf)'::cube)
   Heap Blocks: exact=4267
   ->  Bitmap Index Scan on journey_lng_lat_ts  (cost=0.00..124.32 rows=1605 width=0) (actual time=1194.948..1194.948 rows=43127 loops=1)
         Index Cond: (enclosing_cube(pos) && '(0.08008, 52.205029, -inf),(0.108576, 52.215548, inf)'::cube)
 Planning time: 129.801 ms
 Execution time: 2024.141 ms
(7 rows)


latency average: 21.684 ms
latency stddev: 22.114 ms

```

One day
-------

Try just retrieving a full day's data:

```
Testing "select * from journey where enclosing_cube(pos) && cube(array['-Infinity'::double precision,'-Infinity'::double precision,1507762800], array['Infinity'::double precision,'Infinity'::double precision,1507849200]);" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select * from journey where enclosing_cube(pos) && cube(array['-Infinity'::double precision,'-Infinity'::double precision,1507762800], array['Infinity'::double precision,'Infinity'::double precision,1507849200]);
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on journey  (cost=124.72..5579.92 rows=1605 width=558) (actual time=302.301..1791.077 rows=6540 loops=1)
   Recheck Cond: (enclosing_cube(pos) && '(-inf, -inf, 1507762800),(inf, inf, 1507849200)'::cube)
   Heap Blocks: exact=2476
   ->  Bitmap Index Scan on journey_lng_lat_ts  (cost=0.00..124.32 rows=1605 width=0) (actual time=280.930..280.930 rows=6540 loops=1)
         Index Cond: (enclosing_cube(pos) && '(-inf, -inf, 1507762800),(inf, inf, 1507849200)'::cube)
 Planning time: 188.141 ms
 Execution time: 1792.027 ms
(7 rows)


latency average: 3.586 ms
latency stddev: 4.750 ms

```

Small box and one day
---------------------

Add in a 24 hour time constraint:

```
Testing "select * from journey where enclosing_cube(pos) && cube(array[0.08008,52.205029,1507762800],array[0.108576,52.215548,1507849200]);" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select * from journey where enclosing_cube(pos) && cube(array[0.08008,52.205029,1507762800],array[0.108576,52.215548,1507849200]);
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on journey  (cost=124.72..5579.92 rows=1605 width=558) (actual time=169.215..506.187 rows=912 loops=1)
   Recheck Cond: (enclosing_cube(pos) && '(0.08008, 52.205029, 1507762800),(0.108576, 52.215548, 1507849200)'::cube)
   Heap Blocks: exact=339
   ->  Bitmap Index Scan on journey_lng_lat_ts  (cost=0.00..124.32 rows=1605 width=0) (actual time=154.056..154.056 rows=912 loops=1)
         Index Cond: (enclosing_cube(pos) && '(0.08008, 52.205029, 1507762800),(0.108576, 52.215548, 1507849200)'::cube)
 Planning time: 128.207 ms
 Execution time: 506.542 ms
(7 rows)


latency average: 8.013 ms
latency stddev: 20.585 ms

```

Big box and one day
-------------------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000
http://bboxfinder.com/#52.110000,-0.100000,52.300000,0.250000

```
Testing "select * from journey where enclosing_cube(pos) && cube(array[-0.100000,52.110000,1507762800],array[0.250000,52.300000,1507849200]);" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select * from journey where enclosing_cube(pos) && cube(array[-0.100000,52.110000,1507762800],array[0.250000,52.300000,1507849200]);
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on journey  (cost=124.72..5579.92 rows=1605 width=558) (actual time=177.517..807.026 rows=2383 loops=1)
   Recheck Cond: (enclosing_cube(pos) && '(-0.1, 52.11, 1507762800),(0.25, 52.3, 1507849200)'::cube)
   Heap Blocks: exact=831
   ->  Bitmap Index Scan on journey_lng_lat_ts  (cost=0.00..124.32 rows=1605 width=0) (actual time=160.983..160.983 rows=2383 loops=1)
         Index Cond: (enclosing_cube(pos) && '(-0.1, 52.11, 1507762800),(0.25, 52.3, 1507849200)'::cube)
 Planning time: 128.225 ms
 Execution time: 807.541 ms
(7 rows)


latency average: 8.295 ms
latency stddev: 20.723 ms

```

Big box, one day and vehicle\_ref
---------------------------

This is the IJL 'indicitave' query


```
Testing "select * from journey where enclosing_cube(pos) && cube(array[-0.100000,52.110000,1507762800],array[0.250000,52.300000,1507849200]) and vehicle_ref = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select * from journey where enclosing_cube(pos) && cube(array[-0.100000,52.110000,1507762800],array[0.250000,52.300000,1507849200]) and vehicle_ref = 'WP-106';
                                                              QUERY PLAN                                                               
---------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on journey  (cost=124.32..5583.53 rows=2 width=558) (actual time=799.094..807.824 rows=18 loops=1)
   Recheck Cond: (enclosing_cube(pos) && '(-0.1, 52.11, 1507762800),(0.25, 52.3, 1507849200)'::cube)
   Filter: (vehicle_ref = 'WP-106'::text)
   Rows Removed by Filter: 2365
   Heap Blocks: exact=831
   ->  Bitmap Index Scan on journey_lng_lat_ts  (cost=0.00..124.32 rows=1605 width=0) (actual time=161.481..161.481 rows=2383 loops=1)
         Index Cond: (enclosing_cube(pos) && '(-0.1, 52.11, 1507762800),(0.25, 52.3, 1507849200)'::cube)
 Planning time: 127.366 ms
 Execution time: 808.056 ms
(9 rows)


latency average: 8.683 ms
latency stddev: 17.319 ms

```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

```
Testing "select * from journey where enclosing_cube(pos) && cube(array[-0.100000,52.110000,1507762800],array[0.250000,52.300000,1507849200]) and vehicle_ref = 'WP-106' and line_ref = 'U';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select * from journey where enclosing_cube(pos) && cube(array[-0.100000,52.110000,1507762800],array[0.250000,52.300000,1507849200]) and vehicle_ref = 'WP-106' and line_ref = 'U';
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on journey  (cost=197.07..276.56 rows=1 width=558) (actual time=198.849..203.097 rows=18 loops=1)
   Recheck Cond: ((line_ref = 'U'::text) AND (enclosing_cube(pos) && '(-0.1, 52.11, 1507762800),(0.25, 52.3, 1507849200)'::cube))
   Filter: (vehicle_ref = 'WP-106'::text)
   Rows Removed by Filter: 78
   Heap Blocks: exact=22
   ->  BitmapAnd  (cost=197.07..197.07 rows=19 width=0) (actual time=177.800..177.800 rows=0 loops=1)
         ->  Bitmap Index Scan on journey_line_ref  (cost=0.00..72.50 rows=3744 width=0) (actual time=13.951..13.951 rows=3790 loops=1)
               Index Cond: (line_ref = 'U'::text)
         ->  Bitmap Index Scan on journey_lng_lat_ts  (cost=0.00..124.32 rows=1605 width=0) (actual time=163.800..163.800 rows=2383 loops=1)
               Index Cond: (enclosing_cube(pos) && '(-0.1, 52.11, 1507762800),(0.25, 52.3, 1507849200)'::cube)
 Planning time: 136.007 ms
 Execution time: 203.322 ms
(12 rows)


latency average: 7.099 ms
latency stddev: 14.960 ms

```
 
