
The bounding box is roughly Sawston <-> Cotenham, Camborne <-> Fulbourn: 
[http://bboxfinder.com/#52.110000,-0.100000,52.300000,0.250000](http://bboxfinder.com/#52.110000,-0.100000,52.300000,0.250000)

Using siri\_vm
==============

```
CREATE TABLE siri_vm (
    id                       BIGSERIAL PRIMARY KEY,
    acp_id                   TEXT,
    location4d               GEOGRAPHY(POINTZM,4326),
    acp_ts                   TIMESTAMP WITH TIME ZONE,
    info                     JSONB,
    file_ts                  TIMESTAMP WITH TIME ZONE
   );

CREATE INDEX siri_vm_acp_id ON siri_vm (acp_id);
CREATE INDEX siri_vm_location4d ON siri_vm USING GIST ((location4d::geometry));
CREATE INDEX siri_vm_acp_ts ON siri_vm (acp_ts);
CREATE INDEX siri_vm_info ON siri_vm USING GIN (info);
```

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
 Bitmap Heap Scan on siri_vm  (cost=2188.52..2369.07 rows=1 width=739) (actual time=523660.424..563214.646 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::text) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 61723
   Heap Blocks: exact=70203
   ->  BitmapAnd  (cost=2188.52..2188.52 rows=45 width=0) (actual time=412544.676..412544.676 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_acp_id  (cost=0.00..1038.59 rows=45070 width=0) (actual time=204.635..204.635 rows=70266 loops=1)
               Index Cond: (acp_id = 'WP-106'::text)
         ->  Bitmap Index Scan on siri_vm_location4d_geom  (cost=0.00..1149.68 rows=34834 width=0) (actual time=412303.950..412303.950 rows=11581172 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
 Planning time: 710.521 ms
 Execution time: 563229.875 ms
(12 rows)


latency average: 3961.182 ms
latency stddev: 75.983 ms

```

Using siri\_vm2
===============

```
REATE TABLE siri_vm2 (
    id                       BIGSERIAL NOT NULL,
    file_ts                  TIMESTAMP WITH TIME ZONE NOT NULL,
    acp_id                   CHAR(20) NOT NULL,
    acp_ts                   TIMESTAMP WITH TIME ZONE NOT NULL,
    location4d               GEOMETRY(POINTZM,27700),
    line_ref                 CHAR(10) NOT NULL,
    origin_ref               CHAR(20) NOT NULL,
    origin_departure_ts      TIMESTAMP WITH TIME ZONE NOT NULL,
    info                     JSONB NOT NULL,
    temp_geom                GEOMETRY(POINTZM,4326) NOT NULL
   );

CREATE UNIQUE INDEX siri_vm2_pkey ON siri_vm2 (id);
ALTER TABLE siri_vm2 ADD PRIMARY KEY USING INDEX siri_vm2_pkey;
CREATE INDEX siri_vm2_acp_id ON siri_vm2 (acp_id);
CREATE INDEX siri_vm2_acp_ts ON siri_vm2 (acp_ts);
CREATE INDEX siri_vm2_location4d ON siri_vm2 USING GIST (location4d);
CREATE INDEX siri_vm2_line_ref ON siri_vm2 (line_ref);
CREATE INDEX siri_vm2_origin_ref ON siri_vm2 (origin_ref);
CREATE INDEX siri_vm2_origin_departure_ts ON siri_vm2 (origin_departure_ts);
```

Changes from siri_vm:

* `location4d` now a SRID27700 GEOMETRY 
* `VehicleID` (as `acp_id`), `line_ref`, `origin_ref`, `origin_departure_ts`
  broken out into their own index
* No index on `info`
* `temp_geom` just used to load `location4d`: `update siri_vm2 set location4d = ST_Transform(temp_geom, 27700);`

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
 Bitmap Heap Scan on siri_vm2  (cost=2538.58..2719.17 rows=1 width=739) (actual time=681372.442..718626.020 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::bpchar) AND ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d))
   Filter: ((acp_ts >= '2017-10-12 00:00:00+01'::timestamp with time zone) AND (acp_ts < '2017-10-13 00:00:00+01'::timestamp with time zone))
   Rows Removed by Filter: 70420
   Heap Blocks: exact=72819
   ->  BitmapAnd  (cost=2538.58..2538.58 rows=45 width=0) (actual time=526532.462..526532.462 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm2_acp_id  (cost=0.00..1234.79 rows=45097 width=0) (actual time=69.638..69.638 rows=72873 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
         ->  Bitmap Index Scan on siri_vm2_location4d  (cost=0.00..1303.53 rows=35615 width=0) (actual time=526425.790..526425.790 rows=11936279 loops=1)
               Index Cond: ('0103000020346C00000100000005000000478B15EC452E2041B65BABA69E340E41F1DA603DF2292041D226A79B7A641041E41B3D3E61E420411C8999A52A6F1041E2936B1F81E920411023FF05084A0E41478B15EC452E2041B65BABA69E340E41'::geometry ~ location4d)
 Planning time: 832.921 ms
 Execution time: 718628.354 ms
(12 rows)


latency average: 4254.040 ms
latency stddev: 48.792 ms

```

Using siri\_vm\_4
===============

```
CREATE TABLE ${table} (
    acp_id                   CHAR(20) NOT NULL,
    acp_lng                  DOUBLE PRECISION NOT NULL,
    acp_lat                  DOUBLE PRECISION NOT NULL,
    acp_ts                   BIGINT NOT NULL,
    location2d               GEOGRAPHY(POINT,4326) NOT NULL,
    location4d               GEOGRAPHY(POINTZM,4326) NOT NULL,
    info                     JSONB NOT NULL
   );

CREATE INDEX ${table}_acp_id ON ${table} (acp_id);
CREATE INDEX ${table}_acp_lng ON ${table} (acp_lng);
CREATE INDEX ${table}_acp_lat ON ${table} (acp_lat);
CREATE INDEX ${table}_acp_ts ON ${table} (acp_ts);
CREATE INDEX ${table}_location2d on ${table} USING GIST (location2d);
CREATE INDEX ${table}_location2d_geom on ${table} USING GIST (cast(location2d as geometry));
CREATE INDEX ${table}_location4d on ${table} USING GIST (location4d);
CREATE INDEX ${table}_location4d_geom_nd on ${table} USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);
CREATE INDEX ${table}_info ON ${table} USING GIN (info);
```

Time ranges 
1507762800 = 2017-10-12 00:00:00+01:00, 1507849200 = 2017-10-13 00:00:00+01:00

This schema puts the `acm_*` fields into their own columns and indexes
them, extracts the 2d and 4d positions as geoGRAHPy and indexes those (a
few ways, to  see what happens) and indexes info as a whole. 

Significant
issues are  doing any sort of date extraction from the (string)
`OriginAimedDepartureTime` field, and the fact that location indexes are
all in geoGRAPHy and so can only be used directly with geogRAPHy comparison
operators (which doesn't include '~'). There's also the issue that I've
never managed to get a gist_geometry_ops_nd index to be used for
anything...


```
Testing "select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';
                                                                                    QUERY PLAN                                                                                    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=17533.85..21404.47 rows=196 width=739) (actual time=225.761..5621.013 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::bpchar) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision))
   Heap Blocks: exact=2449
   ->  BitmapAnd  (cost=17533.85..17533.85 rows=972 width=0) (actual time=215.293..215.293 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_acp_id  (cost=0.00..1306.29 rows=47696 width=0) (actual time=55.596..55.596 rows=79114 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
         ->  Bitmap Index Scan on siri_vm_4_acp_ts  (cost=0.00..16227.22 rows=773865 width=0) (actual time=144.300..144.300 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
 Planning time: 128.641 ms
 Execution time: 5622.646 ms
(11 rows)


latency average: 89.901 ms
latency stddev: 19.088 ms

```

```
Testing "select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_4 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location4d::geometry) and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';
                                                                                                                     QUERY PLAN                                                                                                                      
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on siri_vm_4  (cost=17533.75..21399.51 rows=1 width=739) (actual time=225.572..5345.784 rows=2453 loops=1)
   Recheck Cond: ((acp_id = 'WP-106'::bpchar) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   Filter: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location4d)::geometry)
   Heap Blocks: exact=2449
   ->  BitmapAnd  (cost=17533.75..17533.75 rows=972 width=0) (actual time=214.426..214.426 rows=0 loops=1)
         ->  Bitmap Index Scan on siri_vm_4_acp_id  (cost=0.00..1306.29 rows=47696 width=0) (actual time=54.922..54.922 rows=79114 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
         ->  Bitmap Index Scan on siri_vm_4_acp_ts  (cost=0.00..16227.22 rows=773865 width=0) (actual time=144.765..144.765 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
 Planning time: 736.779 ms
 Execution time: 5347.533 ms
(11 rows)


latency average: 92.462 ms
latency stddev: 29.399 ms

```

Using siri\_vm\_5
===============

Exactly the same database as `siri_vm_4`, except partitioned by week.

```
Testing "select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';
                                                                                                                                 QUERY PLAN                                                                                                                                  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..15197.17 rows=243 width=737) (actual time=11170.790..16488.848 rows=2453 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.000..0.000 rows=0 loops=1)
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (acp_id = 'WP-106'::bpchar))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=115.41..15197.17 rows=242 width=740) (actual time=11170.787..16487.296 rows=2453 loops=1)
         Recheck Cond: (acp_id = 'WP-106'::bpchar)
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 3825
         Heap Blocks: exact=6272
         ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_id  (cost=0.00..115.34 rows=4122 width=0) (actual time=11.591..11.591 rows=6278 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
 Planning time: 417.088 ms
 Execution time: 16489.806 ms
(12 rows)


latency average: 12.982 ms
latency stddev: 16.975 ms

```

```
Testing "select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800  and acp_ts < 1507849200 and acp_id = 'WP-106';
                                                                                                                                                                    QUERY PLAN                                                                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..232.96 rows=2 width=386) (actual time=36634.662..41919.202 rows=2453 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (acp_id = 'WP-106'::bpchar) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=216.91..232.96 rows=1 width=740) (actual time=36634.659..41917.742 rows=2453 loops=1)
         Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry) AND (acp_id = 'WP-106'::bpchar))
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 3825
         Heap Blocks: exact=6272
         ->  BitmapAnd  (cost=216.91..216.91 rows=4 width=0) (actual time=25077.903..25077.903 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_41_location2d_geom  (cost=0.00..101.31 rows=2787 width=0) (actual time=25009.821..25009.821 rows=944843 loops=1)
                     Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry)
               ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_id  (cost=0.00..115.34 rows=4122 width=0) (actual time=7.854..7.854 rows=6278 loops=1)
                     Index Cond: (acp_id = 'WP-106'::bpchar)
 Planning time: 949.993 ms
 Execution time: 41928.235 ms
(15 rows)


latency average: 246.741 ms
latency stddev: 31.778 ms

```
