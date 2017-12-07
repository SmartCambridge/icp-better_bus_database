
Using siri_vm
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
=============================================================================
Testing "select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry)" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry)
                                                                                                                          QUERY PLAN                                                                                                                           
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=1158.38..130545.48 rows=34834 width=739) (actual time=231.938..192224.390 rows=304784 loops=1)
   Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
   Heap Blocks: exact=322184
   ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=131.464..131.464 rows=334993 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
 Planning time: 30.249 ms
 Execution time: 192300.463 ms
(7 rows)


latency average: 656.585 ms
latency stddev: 43.478 ms

```

Small box and one day
---------------------

Add in a 24 hour time constraint:

```
=============================================================================
Testing "select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                                                                                                                                            QUERY PLAN                                                                                                                                                                                            
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=22324.08..26256.38 rows=990 width=739) (actual time=836.530..871.130 rows=7968 loops=1)
   Recheck Cond: (('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=7722
   ->  BitmapAnd  (cost=22324.08..22324.08 rows=990 width=0) (actual time=834.533..834.533 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=573.237..573.237 rows=334993 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_ts  (cost=0.00..21173.66 rows=990110 width=0) (actual time=202.363..202.363 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 98.439 ms
 Execution time: 872.438 ms
(10 rows)


latency average: 721.083 ms
latency stddev: 25.108 ms

```

One day
-------

Try just retrieving a full day's data:

```
=============================================================================
Testing "select info from siri_vm where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using siri_vm_ts on siri_vm  (cost=0.56..2104591.19 rows=990110 width=739) (actual time=0.024..73153.304 rows=792867 loops=1)
   Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.432 ms
 Execution time: 73224.476 ms
(4 rows)


latency average: 3381.701 ms

```

Big box and one day
-------------------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000

```
=============================================================================
Testing "select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                                                                                                                                            QUERY PLAN                                                                                                                                                                                            
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=22324.08..26256.38 rows=990 width=739) (actual time=398973.708..399268.977 rows=269210 loops=1)
   Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=85109
   ->  BitmapAnd  (cost=22324.08..22324.08 rows=990 width=0) (actual time=398940.241..398940.241 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=398079.480..398079.480 rows=11581172 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_ts  (cost=0.00..21173.66 rows=990110 width=0) (actual time=124.234..124.234 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 22.928 ms
 Execution time: 399286.262 ms
(10 rows)


latency average: 8532.958 ms

```

Big box, one day and acp_id
---------------------------

acp_id has it's own column and index

```
=============================================================================
Testing "select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
                                                                                                                                        QUERY PLAN                                                                                                                                         
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=2188.52..2369.07 rows=1 width=739) (actual time=109762.331..140258.383 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::text) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 61723
   Heap Blocks: exact=70203
   ->  BitmapAnd  (cost=2188.52..2188.52 rows=45 width=0) (actual time=10712.771..10712.771 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_acp_id  (cost=0.00..1038.59 rows=45070 width=0) (actual time=200.233..200.233 rows=70266 loops=1)
               Index Cond: (acp_id = 'WP-106'::text)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=10483.112..10483.112 rows=11581172 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
 Planning time: 38.480 ms
 Execution time: 140259.264 ms
(12 rows)


latency average: 10218.210 ms
```

Big box, one day and "VehicleRef"
---------------------------------

Try using info @> '{"VehicleRef": "WP-107"} instead

```
=============================================================================
Testing "select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}';
                                                                                                                                                 QUERY PLAN                                                                                                                                                  
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=2907.18..3047.65 rows=1 width=739) (actual time=92976.439..116680.091 rows=2270 loops=1)
   Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry) AND (info @> '{"VehicleRef": "WP-107"}'::jsonb))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 51140
   Heap Blocks: exact=57348
   ->  BitmapAnd  (cost=2907.18..2907.18 rows=35 width=0) (actual time=14479.230..14479.230 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=10291.617..10291.617 rows=11581172 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
         ->  Bitmap Index Scan on siri_vm_info  (cost=0.00..1757.25 rows=34834 width=0) (actual time=3483.938..3483.938 rows=57398 loops=1)
               Index Cond: (info @> '{"VehicleRef": "WP-107"}'::jsonb)
 Planning time: 39.259 ms
 Execution time: 116700.956 ms
(12 rows)


latency average: 10772.875 ms
latency stddev: 1475.531 ms

```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

```
=============================================================================
Testing "select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}' and info @> '{"LineRef": "U"}';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}' and info @> '{"LineRef": "U"}';
                                                                                                                                                                                         QUERY PLAN                                                                                                                                                                                         
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm  (cost=1504.35..1644.91 rows=1 width=739) (actual time=4620.974..4675.872 rows=2270 loops=1)
   Recheck Cond: ((info @> '{"VehicleRef": "WP-107"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry))
   Rows Removed by Filter: 51140
   Heap Blocks: exact=57348
   ->  Bitmap Index Scan on siri_vm_info  (cost=0.00..1504.35 rows=35 width=0) (actual time=4394.400..4394.400 rows=57398 loops=1)
         Index Cond: ((info @> '{"VehicleRef": "WP-107"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
 Planning time: 23.781 ms
 Execution time: 4676.201 ms
(9 rows)


latency average: 389.690 ms
latency stddev: 28.247 ms

```

Using siri_vm2
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
* VehicleID (as acp_id), line_ref, origin_ref, origin_departure_ts
  broken out into their own index
* no index on info

Small box
---------

```
=============================================================================
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326),27700) ~ location4d);" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326),27700) ~ location4d);
                                                                                                                    QUERY PLAN                                                                                                                     
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=1312.43..137142.70 rows=35614 width=739) (actual time=234.949..255975.895 rows=346609 loops=1)
   Recheck Cond: ('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d)
   Heap Blocks: exact=334688
   ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35614 width=0) (actual time=142.993..142.993 rows=346609 loops=1)
         Index Cond: ('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d)
 Planning time: 140.568 ms
 Execution time: 256064.617 ms
(7 rows)


latency average: 429.623 ms
latency stddev: 239.708 ms

```

Small box and one day
---------------------

```
=============================================================================
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326), 27700) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326), 27700) ~ location4d::geometry) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                                                                                                                                      QUERY PLAN                                                                                                                                                                                      
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=17315.19..20359.21 rows=763 width=739) (actual time=335.548..373.059 rows=8206 loops=1)
   Recheck Cond: (('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=7982
   ->  BitmapAnd  (cost=17315.19..17315.19 rows=763 width=0) (actual time=333.223..333.223 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35614 width=0) (actual time=125.496..125.496 rows=346609 loops=1)
               Index Cond: ('0103000020346C0000010000000500000001AA00603D8C2041E2F8DD8971890F41F066A83AFA8B2041C0E2633E00AE0F41AB37F1682F9B204174E22942C2AF0F41465FEF79739B2041EC537998338B0F4101AA00603D8C2041E2F8DD8971890F41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..16011.04 rows=763447 width=0) (actual time=139.182..139.182 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 54.184 ms
 Execution time: 374.484 ms
(10 rows)


latency average: 280.063 ms
latency stddev: 169.595 ms

```

One day
-------

```
=============================================================================
Testing "select info from siri_vm2 where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm2 where acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=16201.90..2320731.75 rows=763447 width=739) (actual time=105.126..626.785 rows=792867 loops=1)
   Recheck Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=99254
   ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..16011.04 rows=763447 width=0) (actual time=83.245..83.245 rows=792867 loops=1)
         Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 0.711 ms
 Execution time: 655.195 ms
(7 rows)


latency average: 130.899 ms
latency stddev: 45.806 ms

```

Big box and one day
-------------------

```
=============================================================================
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326),27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326),27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00';
                                                                                                                                                                                      QUERY PLAN                                                                                                                                                                                      
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=17315.19..20359.21 rows=763 width=739) (actual time=6363.842..6702.191 rows=271161 loops=1)
   Recheck Cond: (('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Heap Blocks: exact=94441
   ->  BitmapAnd  (cost=17315.19..17315.19 rows=763 width=0) (actual time=6323.943..6323.943 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35614 width=0) (actual time=5378.711..5378.711 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..16011.04 rows=763447 width=0) (actual time=75.497..75.497 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 18.330 ms
 Execution time: 6719.692 ms
(10 rows)


latency average: 6330.865 ms
latency stddev: 67.481 ms

```

Big box, one day and acp_id
---------------------------

```
=============================================================================
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-106';
                                                                                                                                   QUERY PLAN                                                                                                                                    
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=2572.12..2756.73 rows=1 width=739) (actual time=5662.514..5711.649 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::bpchar) AND ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 70420
   Heap Blocks: exact=72819
   ->  BitmapAnd  (cost=2572.12..2572.12 rows=46 width=0) (actual time=5456.939..5456.939 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_acp_id  (cost=0.00..1268.35 rows=46371 width=0) (actual time=54.337..54.337 rows=72873 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35614 width=0) (actual time=5367.083..5367.083 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
 Planning time: 34.830 ms
 Execution time: 5712.202 ms
(12 rows)


latency average: 5460.359 ms
latency stddev: 73.381 ms

```

Big box, one day and "VehicleRef"
---------------------------------

Try using the (unindexed) `info @> '{"VehicleRef": "WP-107"}'`

```
=============================================================================
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}';
                                                                                                                                                                                      QUERY PLAN                                                                                                                                                                                      
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=17314.81..20360.74 rows=1 width=739) (actual time=6283.752..6672.084 rows=2270 loops=1)
   Recheck Cond: (('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Filter: (info @> '{"VehicleRef": "WP-107"}'::jsonb)
   Rows Removed by Filter: 268891
   Heap Blocks: exact=94441
   ->  BitmapAnd  (cost=17314.81..17314.81 rows=763 width=0) (actual time=6243.707..6243.707 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35614 width=0) (actual time=5310.069..5310.069 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..16011.04 rows=763447 width=0) (actual time=75.018..75.018 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 14.301 ms
 Execution time: 6682.004 ms
(12 rows)


latency average: 6520.585 ms
latency stddev: 976.433 ms

```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

Try using the (unindexed) `info @> '{"VehicleRef": "WP-107"}' and info @> '{"LineRef": "U"}'`

```
=============================================================================
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}' and info @> '{"LineRef": "U"}';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and info @> '{"VehicleRef" : "WP-107"}' and info @> '{"LineRef": "U"}';
                                                                                                                                                                                      QUERY PLAN                                                                                                                                                                                      
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=17314.81..20362.64 rows=1 width=739) (actual time=6351.542..6740.724 rows=2270 loops=1)
   Recheck Cond: (('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d) AND (acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Filter: ((info @> '{"VehicleRef": "WP-107"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
   Rows Removed by Filter: 268891
   Heap Blocks: exact=94441
   ->  BitmapAnd  (cost=17314.81..17314.81 rows=763 width=0) (actual time=6311.279..6311.279 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35614 width=0) (actual time=5374.964..5374.964 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
         ->  Bitmap Index Scan on siri_vm2_acp_ts  (cost=0.00..16011.04 rows=763447 width=0) (actual time=75.379..75.379 rows=792867 loops=1)
               Index Cond: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
 Planning time: 19.332 ms
 Execution time: 6749.547 ms
(12 rows)


latency average: 6256.566 ms
latency stddev: 113.829 ms

```

Big box, one day, acp\_id and line\_ref
-------------------------------------

Using indexed columns acp\_id and line\_ref

```
=============================================================================
Testing "select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-107' and line_ref = 'U';" with 10 iterations and work_mem 2GB

set work_mem to '2GB'; explain analyse select info from siri_vm2 where (ST_Transform(ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326), 27700) ~ location4d) and acp_ts >= '2017-10-12 00:00:00+01:00' and acp_ts < '2017-10-13 00:00:00+01:00' and acp_id = 'WP-107' and line_ref = 'U';
                                                                                                                                   QUERY PLAN                                                                                                                                    
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm2  (cost=2572.12..2756.84 rows=1 width=739) (actual time=5516.275..5554.729 rows=2270 loops=1)
   Recheck Cond: ((acp_id = 'WP-107'::bpchar) AND ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone) AND (line_ref = 'U'::bpchar))
   Rows Removed by Filter: 51140
   Heap Blocks: exact=53366
   ->  BitmapAnd  (cost=2572.12..2572.12 rows=46 width=0) (actual time=5371.712..5371.712 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_acp_id  (cost=0.00..1268.35 rows=46371 width=0) (actual time=26.139..26.139 rows=53410 loops=1)
               Index Cond: (acp_id = 'WP-107'::bpchar)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35614 width=0) (actual time=5319.989..5319.989 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
 Planning time: 17.182 ms
 Execution time: 5555.163 ms
(12 rows)


latency average: 5368.009 ms
latency stddev: 75.608 ms

```
