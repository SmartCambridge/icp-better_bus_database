
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

```
Testing "select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry)" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry)
                                                                                                                          QUERY PLAN                                                                                                                           
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=1158.38..130545.48 rows=34834 width=739) (actual time=12978.246..213309.704 rows=304784 loops=1)
   Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
   Heap Blocks: exact=322184
   ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=12833.457..12833.457 rows=334993 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
 Planning time: 694.560 ms
 Execution time: 213400.521 ms
(7 rows)


latency average: 200.346 ms
latency stddev: 25.539 ms

```

Small box and one day
---------------------

Add in a 24 hour time constraint:

```
Testing "select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                                                                                                                                            QUERY PLAN                                                                                                                                                                                            
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=22324.08..26256.38 rows=990 width=739) (actual time=13051.296..17520.797 rows=7968 loops=1)
   Recheck Cond: (('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=7722
   ->  BitmapAnd  (cost=22324.08..22324.08 rows=990 width=0) (actual time=13034.445..13034.445 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=12841.812..12841.812 rows=334993 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_ts  (cost=0.00..21173.66 rows=990110 width=0) (actual time=132.779..132.779 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 718.714 ms
 Execution time: 17536.911 ms
(10 rows)


latency average: 213.602 ms
latency stddev: 37.771 ms

```

One day
-------

Try just retrieving a full day's data:

```
Testing "select info from siri_vm where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using siri_vm_ts on siri_vm  (cost=0.56..2104591.19 rows=990110 width=739) (actual time=23.071..74658.368 rows=792867 loops=1)
   Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 125.548 ms
 Execution time: 74729.333 ms
(4 rows)


latency average: 1.549 ms
latency stddev: 3.471 ms

```

Big box and one day
-------------------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000

```
Testing "select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                                                                                                                                            QUERY PLAN                                                                                                                                                                                            
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=22324.08..26256.38 rows=990 width=739) (actual time=411915.948..416393.219 rows=269210 loops=1)
   Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=85109
   ->  BitmapAnd  (cost=22324.08..22324.08 rows=990 width=0) (actual time=411858.906..411858.906 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=411017.157..411017.157 rows=11581172 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_ts  (cost=0.00..21173.66 rows=990110 width=0) (actual time=155.206..155.206 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 718.676 ms
 Execution time: 416429.955 ms
(10 rows)


latency average: 4597.745 ms
latency stddev: 33.288 ms

```

Big box, one day and acp\_id
---------------------------

acp\_id has it's own column and index

```
Testing "select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
                                                                                                                                        QUERY PLAN                                                                                                                                         
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=2188.52..2369.07 rows=1 width=739) (actual time=521460.771..560231.876 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::text) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 61723
   Heap Blocks: exact=70203
   ->  BitmapAnd  (cost=2188.52..2188.52 rows=45 width=0) (actual time=410519.787..410519.787 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_acp_id  (cost=0.00..1038.59 rows=45070 width=0) (actual time=205.678..205.678 rows=70266 loops=1)
               Index Cond: (acp_id = 'WP-106'::text)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=410278.239..410278.239 rows=11581172 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
 Planning time: 709.900 ms
 Execution time: 560247.207 ms
(12 rows)


latency average: 4016.172 ms
latency stddev: 78.944 ms

```

Big box, one day and "VehicleRef"
---------------------------------

Try using info @> '{"VehicleRef": "WP-106"} instead

```
Testing "select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}';
                                                                                                                                                 QUERY PLAN                                                                                                                                                  
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=2907.18..3047.65 rows=1 width=739) (actual time=526488.111..565175.918 rows=2453 loops=1)
   Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry) AND (info @> '{"VehicleRef": "WP-106"}'::jsonb))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 61723
   Heap Blocks: exact=70203
   ->  BitmapAnd  (cost=2907.18..2907.18 rows=35 width=0) (actual time=415797.114..415797.114 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=410453.623..410453.623 rows=11581172 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_info  (cost=0.00..1757.25 rows=34834 width=0) (actual time=4651.646..4651.646 rows=70266 loops=1)
               Index Cond: (info @> '{"VehicleRef": "WP-106"}'::jsonb)
 Planning time: 738.874 ms
 Execution time: 565184.748 ms
(12 rows)


latency average: 4840.527 ms
latency stddev: 52.581 ms

```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

```
Testing "select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
                                                                                                                                                                                         QUERY PLAN                                                                                                                                                                                         
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=1504.35..1644.91 rows=1 width=739) (actual time=124516.629..163270.900 rows=2453 loops=1)
   Recheck Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry))
   Rows Removed by Filter: 61723
   Heap Blocks: exact=70203
   ->  Bitmap Index Scan on siri_vm_info  (cost=0.00..1504.35 rows=35 width=0) (actual time=12641.645..12641.645 rows=70266 loops=1)
         Index Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
 Planning time: 738.780 ms
 Execution time: 163272.621 ms
(9 rows)


latency average: 485.550 ms
latency stddev: 41.842 ms

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

```
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326),27700) ~ location4d);" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326),27700) ~ location4d);
                                                                                                                    QUERY PLAN                                                                                                                     
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=1312.44..137146.43 rows=35615 width=739) (actual time=16385.925..283326.609 rows=346609 loops=1)
   Recheck Cond: ('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d)
   Heap Blocks: exact=334688
   ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35615 width=0) (actual time=16227.185..16227.185 rows=346609 loops=1)
         Index Cond: ('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d)
 Planning time: 807.814 ms
 Execution time: 283423.000 ms
(7 rows)


latency average: 203.130 ms
latency stddev: 28.102 ms

```

Small box and one day
---------------------

```
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326), 27700) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326), 27700) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                                                                                                                                      QUERY PLAN                                                                                                                                                                                      
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=21092.24..24855.40 rows=944 width=739) (actual time=16460.950..22381.143 rows=8206 loops=1)
   Recheck Cond: (('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=7982
   ->  BitmapAnd  (cost=21092.24..21092.24 rows=944 width=0) (actual time=16441.997..16441.997 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35615 width=0) (actual time=16235.541..16235.541 rows=346609 loops=1)
               Index Cond: ('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..19787.98 rows=943542 width=0) (actual time=140.975..140.975 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 838.158 ms
 Execution time: 22384.560 ms
(10 rows)


latency average: 211.027 ms
latency stddev: 27.003 ms

```

One day
-------

```
Testing "select info from siri_vm2 where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm2 where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=20023.87..2758203.50 rows=943542 width=739) (actual time=194.475..7162.483 rows=792867 loops=1)
   Recheck Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=99254
   ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..19787.98 rows=943542 width=0) (actual time=157.091..157.091 rows=792867 loops=1)
         Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 147.280 ms
 Execution time: 7211.094 ms
(7 rows)


latency average: 130.044 ms
latency stddev: 23.511 ms

```

Big box and one day
-------------------

```
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326),27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326),27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                                                                                                                                      QUERY PLAN                                                                                                                                                                                      
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=21092.24..24855.40 rows=944 width=739) (actual time=531235.284..537060.879 rows=271161 loops=1)
   Recheck Cond: (('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=94441
   ->  BitmapAnd  (cost=21092.24..21092.24 rows=944 width=0) (actual time=531188.289..531188.289 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35615 width=0) (actual time=530201.211..530201.211 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..19787.98 rows=943542 width=0) (actual time=183.403..183.403 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 1987.511 ms
 Execution time: 537129.072 ms
(10 rows)


latency average: 4951.705 ms
latency stddev: 45.528 ms

```

Big box, one day and acp\_id
---------------------------

```
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
                                                                                                                                   QUERY PLAN                                                                                                                                    
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=2538.58..2719.17 rows=1 width=739) (actual time=678464.583..715376.615 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::bpchar) AND ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 70420
   Heap Blocks: exact=72819
   ->  BitmapAnd  (cost=2538.58..2538.58 rows=45 width=0) (actual time=523174.337..523174.337 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_acp_id  (cost=0.00..1234.79 rows=45097 width=0) (actual time=69.922..69.922 rows=72873 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35615 width=0) (actual time=523067.679..523067.679 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
 Planning time: 782.905 ms
 Execution time: 715378.886 ms
(12 rows)


latency average: 4238.140 ms
latency stddev: 74.743 ms

```

Big box, one day and "VehicleRef"
---------------------------------

Try using the (unindexed) `info @> '{"VehicleRef": "WP-106"}'`

```
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}';
                                                                                                                                                                                      QUERY PLAN                                                                                                                                                                                      
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=21091.77..24857.29 rows=1 width=739) (actual time=524888.145..530780.478 rows=2453 loops=1)
   Recheck Cond: (('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Filter: (info @> '{"VehicleRef": "WP-106"}'::jsonb)
   Rows Removed by Filter: 268708
   Heap Blocks: exact=94441
   ->  BitmapAnd  (cost=21091.77..21091.77 rows=944 width=0) (actual time=524791.259..524791.259 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35615 width=0) (actual time=523812.707..523812.707 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..19787.98 rows=943542 width=0) (actual time=147.940..147.940 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 816.132 ms
 Execution time: 530789.799 ms
(12 rows)


latency average: 4904.095 ms
latency stddev: 33.832 ms

```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

Try using the (unindexed) `info @> '{"VehicleRef": "WP-106"}' and info @> '{"LineRef": "U"}'`

```
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
                                                                                                                                                                                      QUERY PLAN                                                                                                                                                                                      
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=21091.77..24859.65 rows=1 width=739) (actual time=524979.678..530805.370 rows=2453 loops=1)
   Recheck Cond: (('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Filter: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
   Rows Removed by Filter: 268708
   Heap Blocks: exact=94441
   ->  BitmapAnd  (cost=21091.77..21091.77 rows=944 width=0) (actual time=524883.524..524883.524 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35615 width=0) (actual time=523945.889..523945.889 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..19787.98 rows=943542 width=0) (actual time=143.685..143.685 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 832.837 ms
 Execution time: 530814.493 ms
(12 rows)


latency average: 4887.171 ms
latency stddev: 46.058 ms

```

Big box, one day, acp\_id and line\_ref
-------------------------------------

Using indexed columns acp\_id and line\_ref

```
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106' and line_ref = 'U';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106' and line_ref = 'U';
                                                                                                                                   QUERY PLAN                                                                                                                                    
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=2538.58..2719.28 rows=1 width=739) (actual time=678138.889..715084.270 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::bpchar) AND ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone) AND (line_ref = 'U'::bpchar))
   Rows Removed by Filter: 70420
   Heap Blocks: exact=72819
   ->  BitmapAnd  (cost=2538.58..2538.58 rows=45 width=0) (actual time=523141.560..523141.560 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_acp_id  (cost=0.00..1234.79 rows=45097 width=0) (actual time=68.239..68.239 rows=72873 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35615 width=0) (actual time=523035.314..523035.314 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
 Planning time: 807.935 ms
 Execution time: 715087.278 ms
(12 rows)


latency average: 4223.525 ms
latency stddev: 80.743 ms

```
