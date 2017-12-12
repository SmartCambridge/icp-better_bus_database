
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

```
Testing "select info from siri_vm_5 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548
                                                                                                  QUERY PLAN                                                                                                  
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..404503.84 rows=89133 width=739) (actual time=177.290..268970.791 rows=367466 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=6246.73..27860.95 rows=6057 width=740) (actual time=177.287..19401.887 rows=26998 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Heap Blocks: exact=26119
         ->  BitmapAnd  (cost=6246.73..6246.73 rows=6057 width=0) (actual time=155.198..155.198 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_lng  (cost=0.00..1604.04 rows=76361 width=0) (actual time=53.551..53.551 rows=84339 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_lat  (cost=0.00..4639.41 rows=221098 width=0) (actual time=82.821..82.821 rows=225438 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_42  (cost=10834.80..49373.40 rows=10824 width=740) (actual time=264.075..34315.435 rows=47777 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Heap Blocks: exact=45952
         ->  BitmapAnd  (cost=10834.80..10834.80 rows=10824 width=0) (actual time=232.716..232.716 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_42_acp_lng  (cost=0.00..2903.08 rows=138265 width=0) (actual time=72.295..72.295 rows=145233 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_42_acp_lat  (cost=0.00..7926.05 rows=377762 width=0) (actual time=128.601..128.601 rows=378712 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_43  (cost=11612.12..56963.29 rows=12923 width=738) (actual time=302.261..32718.194 rows=45733 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Heap Blocks: exact=44176
         ->  BitmapAnd  (cost=11612.12..11612.12 rows=12923 width=0) (actual time=291.638..291.638 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_43_acp_lng  (cost=0.00..3194.15 rows=152172 width=0) (actual time=111.593..111.593 rows=143646 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_43_acp_lat  (cost=0.00..8411.25 rows=401082 width=0) (actual time=147.497..147.497 rows=383653 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_44  (cost=10837.19..49878.20 rows=10985 width=738) (actual time=295.849..33166.973 rows=46313 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Heap Blocks: exact=44609
         ->  BitmapAnd  (cost=10837.19..10837.19 rows=10985 width=0) (actual time=228.481..228.481 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_44_acp_lng  (cost=0.00..2912.90 rows=138847 width=0) (actual time=70.262..70.262 rows=145071 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_44_acp_lat  (cost=0.00..7918.54 rows=377411 width=0) (actual time=127.539..127.539 rows=380789 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_45  (cost=10416.07..46626.97 rows=10141 width=739) (actual time=264.680..32383.576 rows=46980 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Heap Blocks: exact=45020
         ->  BitmapAnd  (cost=10416.07..10416.07 rows=10141 width=0) (actual time=240.885..240.885 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_45_acp_lng  (cost=0.00..2757.39 rows=131296 width=0) (actual time=62.022..62.022 rows=144750 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_45_acp_lat  (cost=0.00..7653.35 rows=364892 width=0) (actual time=146.329..146.329 rows=373552 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_46  (cost=10799.34..49523.96 rows=10894 width=739) (actual time=278.047..32965.445 rows=46602 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Heap Blocks: exact=44782
         ->  BitmapAnd  (cost=10799.34..10799.34 rows=10894 width=0) (actual time=222.575..222.575 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_46_acp_lng  (cost=0.00..2874.23 rows=136980 width=0) (actual time=62.079..62.079 rows=142691 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_46_acp_lat  (cost=0.00..7919.41 rows=377498 width=0) (actual time=129.445..129.445 rows=375029 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_47  (cost=9866.57..45532.70 rows=10026 width=735) (actual time=273.842..30586.075 rows=39707 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Heap Blocks: exact=38148
         ->  BitmapAnd  (cost=9866.57..9866.57 rows=10026 width=0) (actual time=239.864..239.864 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_47_acp_lng  (cost=0.00..2735.30 rows=130287 width=0) (actual time=88.569..88.569 rows=125540 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_47_acp_lat  (cost=0.00..7126.00 rows=339757 width=0) (actual time=123.332..123.332 rows=334594 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_48  (cost=10889.68..49379.18 rows=10793 width=745) (actual time=238.360..33984.455 rows=40632 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Heap Blocks: exact=39307
         ->  BitmapAnd  (cost=10889.68..10889.68 rows=10793 width=0) (actual time=223.526..223.526 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_48_acp_lng  (cost=0.00..2780.83 rows=132440 width=0) (actual time=66.033..66.033 rows=133312 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_48_acp_lat  (cost=0.00..8103.20 rows=386277 width=0) (actual time=127.754..127.754 rows=371760 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_49  (cost=6309.14..29289.00 rows=6481 width=738) (actual time=173.716..19297.573 rows=26724 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Heap Blocks: exact=25695
         ->  BitmapAnd  (cost=6309.14..6309.14 rows=6481 width=0) (actual time=153.032..153.032 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_49_acp_lng  (cost=0.00..1680.08 rows=79965 width=0) (actual time=46.931..46.931 rows=81263 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_49_acp_lat  (cost=0.00..4625.57 rows=220514 width=0) (actual time=87.646..87.646 rows=215233 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_50  (cost=4.17..9.52 rows=1 width=32) (actual time=0.017..0.017 rows=0 loops=1)
         Recheck Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_5_2017_50_acp_lat  (cost=0.00..4.17 rows=2 width=0) (actual time=0.015..0.015 rows=0 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_51  (cost=4.17..9.52 rows=1 width=32) (actual time=0.017..0.017 rows=0 loops=1)
         Recheck Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_5_2017_51_acp_lat  (cost=0.00..4.17 rows=2 width=0) (actual time=0.016..0.016 rows=0 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2017_52  (cost=4.17..9.52 rows=1 width=32) (actual time=0.007..0.007 rows=0 loops=1)
         Recheck Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_5_2017_52_acp_lat  (cost=0.00..4.17 rows=2 width=0) (actual time=0.007..0.007 rows=0 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2018_01  (cost=4.17..9.52 rows=1 width=32) (actual time=0.010..0.010 rows=0 loops=1)
         Recheck Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_5_2018_01_acp_lat  (cost=0.00..4.17 rows=2 width=0) (actual time=0.009..0.009 rows=0 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2018_02  (cost=4.17..9.52 rows=1 width=32) (actual time=0.009..0.009 rows=0 loops=1)
         Recheck Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_5_2018_02_acp_lat  (cost=0.00..4.17 rows=2 width=0) (actual time=0.007..0.007 rows=0 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2018_03  (cost=4.17..9.52 rows=1 width=32) (actual time=0.007..0.007 rows=0 loops=1)
         Recheck Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_5_2018_03_acp_lat  (cost=0.00..4.17 rows=2 width=0) (actual time=0.007..0.007 rows=0 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2018_04  (cost=4.17..9.52 rows=1 width=32) (actual time=0.014..0.014 rows=0 loops=1)
         Recheck Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_5_2018_04_acp_lat  (cost=0.00..4.17 rows=2 width=0) (actual time=0.009..0.009 rows=0 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
   ->  Bitmap Heap Scan on siri_vm_5_2018_05  (cost=4.17..9.52 rows=1 width=32) (actual time=0.007..0.007 rows=0 loops=1)
         Recheck Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
         ->  Bitmap Index Scan on siri_vm_5_2018_05_acp_lat  (cost=0.00..4.17 rows=2 width=0) (actual time=0.007..0.007 rows=0 loops=1)
               Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
 Planning time: 444.772 ms
 Execution time: 269058.642 ms
(117 rows)


latency average: 94.262 ms
latency stddev: 38.882 ms

```

```
Testing "select info from siri_vm_5 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry)" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry)
                                                                                                                             QUERY PLAN                                                                                                                              
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..144348.45 rows=38462 width=739) (actual time=965.418..281090.591 rows=367466 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=102.01..10456.37 rows=2787 width=740) (actual time=965.416..20564.108 rows=26998 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Heap Blocks: exact=26119
         ->  Bitmap Index Scan on siri_vm_5_2017_41_location2d_geom  (cost=0.00..101.31 rows=2787 width=0) (actual time=937.418..937.418 rows=26998 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Bitmap Heap Scan on siri_vm_5_2017_42  (cost=177.81..18102.88 rows=4825 width=740) (actual time=1747.194..35863.554 rows=47777 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Heap Blocks: exact=45952
         ->  Bitmap Index Scan on siri_vm_5_2017_42_location2d_geom  (cost=0.00..176.60 rows=4825 width=0) (actual time=1714.153..1714.153 rows=47777 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Bitmap Heap Scan on siri_vm_5_2017_43  (cost=173.02..17717.08 rows=4723 width=738) (actual time=1867.197..34335.843 rows=45733 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Heap Blocks: exact=44176
         ->  Bitmap Index Scan on siri_vm_5_2017_43_location2d_geom  (cost=0.00..171.84 rows=4723 width=0) (actual time=1831.116..1831.116 rows=45733 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Bitmap Heap Scan on siri_vm_5_2017_44  (cost=173.39..17896.31 rows=4771 width=738) (actual time=1545.662..34299.327 rows=46313 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Heap Blocks: exact=44609
         ->  Bitmap Index Scan on siri_vm_5_2017_44_location2d_geom  (cost=0.00..172.20 rows=4771 width=0) (actual time=1509.113..1509.113 rows=46313 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Bitmap Heap Scan on siri_vm_5_2017_45  (cost=173.03..17720.46 rows=4724 width=739) (actual time=1531.145..33631.762 rows=46980 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Heap Blocks: exact=45020
         ->  Bitmap Index Scan on siri_vm_5_2017_45_location2d_geom  (cost=0.00..171.84 rows=4724 width=0) (actual time=1493.328..1493.328 rows=46980 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Bitmap Heap Scan on siri_vm_5_2017_46  (cost=173.20..17806.36 rows=4747 width=739) (actual time=1844.473..34495.947 rows=46602 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Heap Blocks: exact=44782
         ->  Bitmap Index Scan on siri_vm_5_2017_46_location2d_geom  (cost=0.00..172.02 rows=4747 width=0) (actual time=1805.187..1805.187 rows=46602 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Bitmap Heap Scan on siri_vm_5_2017_47  (cost=162.63..16564.66 rows=4415 width=735) (actual time=1815.248..32001.805 rows=39707 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Heap Blocks: exact=38148
         ->  Bitmap Index Scan on siri_vm_5_2017_47_location2d_geom  (cost=0.00..161.53 rows=4415 width=0) (actual time=1757.235..1757.235 rows=39707 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Bitmap Heap Scan on siri_vm_5_2017_48  (cost=173.15..17809.97 rows=4740 width=745) (actual time=1613.123..35825.151 rows=40632 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Heap Blocks: exact=39307
         ->  Bitmap Index Scan on siri_vm_5_2017_48_location2d_geom  (cost=0.00..171.97 rows=4740 width=0) (actual time=1575.867..1575.867 rows=40632 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Bitmap Heap Scan on siri_vm_5_2017_49  (cost=101.50..10209.09 rows=2721 width=738) (actual time=1106.950..19895.572 rows=26724 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Heap Blocks: exact=25695
         ->  Bitmap Index Scan on siri_vm_5_2017_49_location2d_geom  (cost=0.00..100.82 rows=2721 width=0) (actual time=1071.739..1071.739 rows=26724 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Index Scan using siri_vm_5_2017_50_location2d_geom on siri_vm_5_2017_50  (cost=0.14..8.16 rows=1 width=32) (actual time=20.570..20.570 rows=0 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Index Scan using siri_vm_5_2017_51_location2d_geom on siri_vm_5_2017_51  (cost=0.14..8.16 rows=1 width=32) (actual time=0.220..0.220 rows=0 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Index Scan using siri_vm_5_2017_52_location2d_geom on siri_vm_5_2017_52  (cost=0.14..8.16 rows=1 width=32) (actual time=2.058..2.058 rows=0 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Index Scan using siri_vm_5_2018_01_location2d_geom on siri_vm_5_2018_01  (cost=0.14..8.16 rows=1 width=32) (actual time=0.193..0.193 rows=0 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Index Scan using siri_vm_5_2018_02_location2d_geom on siri_vm_5_2018_02  (cost=0.14..8.16 rows=1 width=32) (actual time=0.131..0.131 rows=0 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Index Scan using siri_vm_5_2018_03_location2d_geom on siri_vm_5_2018_03  (cost=0.14..8.16 rows=1 width=32) (actual time=0.113..0.113 rows=0 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Index Scan using siri_vm_5_2018_04_location2d_geom on siri_vm_5_2018_04  (cost=0.14..8.16 rows=1 width=32) (actual time=0.131..0.131 rows=0 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
   ->  Index Scan using siri_vm_5_2018_05_location2d_geom on siri_vm_5_2018_05  (cost=0.14..8.16 rows=1 width=32) (actual time=0.137..0.137 rows=0 loops=1)
         Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
 Planning time: 1181.967 ms
 Execution time: 281196.565 ms
(66 rows)


latency average: 18.933 ms
latency stddev: 14.974 ms

```

One day
-------

Try just retrieving a full day's data:

```
Testing "select info from siri_vm_5 where acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                       QUERY PLAN                                                                        
---------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..339369.21 rows=806329 width=740) (actual time=190.753..5590.723 rows=792867 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=17113.29..339369.21 rows=806328 width=740) (actual time=190.752..5514.755 rows=792867 loops=1)
         Recheck Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Heap Blocks: exact=88118
         ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_ts  (cost=0.00..16911.71 rows=806328 width=0) (actual time=149.895..149.895 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
 Planning time: 409.230 ms
 Execution time: 5633.453 ms
(10 rows)


latency average: 116.074 ms
latency stddev: 25.581 ms

```

Small box and one day
---------------------

Add in a 24 hour time constraint:

```
Testing "select info from siri_vm_5 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548 and acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where acp_lng >= 0.08008 and acp_lat >= 52.205029 and acp_lng <= 0.108576 and acp_lat <= 52.215548 and acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                                                                         QUERY PLAN                                                                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..27889.09 rows=1753 width=740) (actual time=14556.363..20069.214 rows=7968 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_lng >= '0.08008'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat <= '52.215548'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=6244.58..27889.09 rows=1752 width=740) (actual time=14556.362..20065.979 rows=7968 loops=1)
         Recheck Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision) AND (acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 19030
         Heap Blocks: exact=26119
         ->  BitmapAnd  (cost=6244.58..6244.58 rows=6057 width=0) (actual time=143.106..143.106 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_lng  (cost=0.00..1604.04 rows=76361 width=0) (actual time=48.366..48.366 rows=84339 loops=1)
                     Index Cond: ((acp_lng >= '0.08008'::double precision) AND (acp_lng <= '0.108576'::double precision))
               ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_lat  (cost=0.00..4639.41 rows=221098 width=0) (actual time=76.092..76.092 rows=225438 loops=1)
                     Index Cond: ((acp_lat >= '52.205029'::double precision) AND (acp_lat <= '52.215548'::double precision))
 Planning time: 342.859 ms
 Execution time: 20072.134 ms
(15 rows)


latency average: 143.385 ms
latency stddev: 31.326 ms

```

```
Testing "select info from siri_vm_5 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where (ST_MakeEnvelope (0.08008, 52.205029, 0.108576, 52.215548, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                                                                                                    QUERY PLAN                                                                                                                                                    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..10469.81 rows=807 width=739) (actual time=15775.190..21246.723 rows=7968 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=101.52..10469.81 rows=806 width=740) (actual time=15775.188..21243.730 rows=7968 loops=1)
         Recheck Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 19030
         Heap Blocks: exact=26119
         ->  Bitmap Index Scan on siri_vm_5_2017_41_location2d_geom  (cost=0.00..101.31 rows=2787 width=0) (actual time=937.982..937.982 rows=26998 loops=1)
               Index Cond: ('0103000020E61000000100000005000000554D10751F80B43FA5DDE8633E1A4A40554D10751F80B43FEE5BAD13971B4A4030682101A3CBBB3FEE5BAD13971B4A4030682101A3CBBB3FA5DDE8633E1A4A40554D10751F80B43FA5DDE8633E1A4A40'::geometry ~ (location2d)::geometry)
 Planning time: 942.038 ms
 Execution time: 21255.319 ms
(12 rows)


latency average: 82.541 ms
latency stddev: 43.380 ms

```

Big box and one day
-------------------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000
http://bboxfinder.com/#52.110000,-0.100000,52.300000,0.250000

```
Testing "select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                                                                 QUERY PLAN                                                                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..347271.79 rows=163536 width=740) (actual time=184.478..5754.541 rows=269210 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=16952.59..347271.79 rows=163535 width=740) (actual time=184.475..5716.880 rows=269210 loops=1)
         Recheck Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision))
         Rows Removed by Filter: 523657
         Heap Blocks: exact=88118
         ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_ts  (cost=0.00..16911.71 rows=806328 width=0) (actual time=149.360..149.360 rows=792867 loops=1)
               Index Cond: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
 Planning time: 342.871 ms
 Execution time: 5774.579 ms
(12 rows)


latency average: 113.047 ms
latency stddev: 19.756 ms

```

```
Testing "select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200;
                                                                                                                                                    QUERY PLAN                                                                                                                                                    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..10469.81 rows=807 width=739) (actual time=35422.332..44698.876 rows=269210 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=101.52..10469.81 rows=806 width=740) (actual time=35422.330..44660.781 rows=269210 loops=1)
         Recheck Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry)
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 675633
         Heap Blocks: exact=298350
         ->  Bitmap Index Scan on siri_vm_5_2017_41_location2d_geom  (cost=0.00..101.31 rows=2787 width=0) (actual time=24876.502..24876.502 rows=944843 loops=1)
               Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry)
 Planning time: 966.997 ms
 Execution time: 44727.684 ms
(12 rows)


latency average: 1031.334 ms
latency stddev: 57.632 ms

```

Big box, one day and acp\_id
---------------------------

acp\_id has it's own column and index. This is the IJL 'indicitave' query

```
Testing "select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';
                                                                                                                                 QUERY PLAN                                                                                                                                  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..15197.17 rows=243 width=737) (actual time=11561.692..16804.564 rows=2453 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (acp_id = 'WP-106'::bpchar))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=115.41..15197.17 rows=242 width=740) (actual time=11561.689..16803.083 rows=2453 loops=1)
         Recheck Cond: (acp_id = 'WP-106'::bpchar)
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 3825
         Heap Blocks: exact=6272
         ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_id  (cost=0.00..115.34 rows=4122 width=0) (actual time=11.376..11.376 rows=6278 loops=1)
               Index Cond: (acp_id = 'WP-106'::bpchar)
 Planning time: 342.775 ms
 Execution time: 16805.747 ms
(12 rows)


latency average: 13.061 ms
latency stddev: 16.395 ms

```

```
Testing "select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and acp_id = 'WP-106';
                                                                                                                                                                    QUERY PLAN                                                                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..232.96 rows=2 width=386) (actual time=36393.001..41669.232 rows=2453 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (acp_id = 'WP-106'::bpchar) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=216.91..232.96 rows=1 width=740) (actual time=36393.000..41667.751 rows=2453 loops=1)
         Recheck Cond: (('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry) AND (acp_id = 'WP-106'::bpchar))
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 3825
         Heap Blocks: exact=6272
         ->  BitmapAnd  (cost=216.91..216.91 rows=4 width=0) (actual time=25019.313..25019.313 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_41_location2d_geom  (cost=0.00..101.31 rows=2787 width=0) (actual time=24951.482..24951.482 rows=944843 loops=1)
                     Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry)
               ->  Bitmap Index Scan on siri_vm_5_2017_41_acp_id  (cost=0.00..115.34 rows=4122 width=0) (actual time=7.773..7.773 rows=6278 loops=1)
                     Index Cond: (acp_id = 'WP-106'::bpchar)
 Planning time: 949.889 ms
 Execution time: 41678.338 ms
(15 rows)


latency average: 240.603 ms
latency stddev: 29.605 ms

```

Big box, one day and "VehicleRef" in place of acp\_id
----------------------------------------------------

Try using info @> '{"VehicleRef": "WP-107"} instead

```
Testing "select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';
                                                                                                                                         QUERY PLAN                                                                                                                                          
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..10458.14 rows=165 width=736) (actual time=11317.501..16568.692 rows=2453 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (info @> '{"VehicleRef": "WP-106"}'::jsonb))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=68.95..10458.14 rows=164 width=740) (actual time=11317.499..16567.087 rows=2453 loops=1)
         Recheck Cond: (info @> '{"VehicleRef": "WP-106"}'::jsonb)
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 3825
         Heap Blocks: exact=6272
         ->  Bitmap Index Scan on siri_vm_5_2017_41_info  (cost=0.00..68.91 rows=2787 width=0) (actual time=83.937..83.937 rows=6278 loops=1)
               Index Cond: (info @> '{"VehicleRef": "WP-106"}'::jsonb)
 Planning time: 373.217 ms
 Execution time: 16569.915 ms
(12 rows)


latency average: 23.413 ms
latency stddev: 8.936 ms

```


```
Testing "select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}';
                                                                                                                                                                            QUERY PLAN                                                                                                                                                                            
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..182.51 rows=2 width=386) (actual time=36726.330..42085.900 rows=2453 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (info @> '{"VehicleRef": "WP-106"}'::jsonb) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=170.47..182.51 rows=1 width=740) (actual time=36726.329..42084.434 rows=2453 loops=1)
         Recheck Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 3825
         Heap Blocks: exact=6272
         ->  BitmapAnd  (cost=170.47..170.47 rows=3 width=0) (actual time=25054.896..25054.896 rows=0 loops=1)
               ->  Bitmap Index Scan on siri_vm_5_2017_41_info  (cost=0.00..68.91 rows=2787 width=0) (actual time=89.175..89.175 rows=6278 loops=1)
                     Index Cond: (info @> '{"VehicleRef": "WP-106"}'::jsonb)
               ->  Bitmap Index Scan on siri_vm_5_2017_41_location2d_geom  (cost=0.00..101.31 rows=2787 width=0) (actual time=24962.358..24962.358 rows=944843 loops=1)
                     Index Cond: ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry)
 Planning time: 1104.955 ms
 Execution time: 42099.198 ms
(15 rows)


latency average: 214.780 ms
latency stddev: 25.183 ms

```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

```
Testing "select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where acp_lng >= -0.100000 and acp_lat >= 52.110000 and acp_lng <= 0.250000 and acp_lat <= 52.300000 and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
                                                                                                                                                             QUERY PLAN                                                                                                                                                              
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..96.09 rows=2 width=386) (actual time=11517.443..16768.779 rows=2453 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=84.03..96.09 rows=1 width=740) (actual time=11517.442..16767.475 rows=2453 loops=1)
         Recheck Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
         Filter: ((acp_lng >= '-0.1'::double precision) AND (acp_lat >= '52.11'::double precision) AND (acp_lng <= '0.25'::double precision) AND (acp_lat <= '52.3'::double precision) AND (acp_ts >= 1507762800) AND (acp_ts < 1507849200))
         Rows Removed by Filter: 3825
         Heap Blocks: exact=6272
         ->  Bitmap Index Scan on siri_vm_5_2017_41_info  (cost=0.00..84.03 rows=3 width=0) (actual time=147.718..147.718 rows=6278 loops=1)
               Index Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
 Planning time: 373.058 ms
 Execution time: 16769.845 ms
(12 rows)


latency average: 37.048 ms
latency stddev: 12.136 ms

```

```
Testing "select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';" with 10 iterations and work_mem 2GB

Flushing buffers

Restarting Postgres

Timing is on.
Timing is off.
Pager usage is off.
set work_mem to '2GB';
SET
explain analyse select info from siri_vm_5 where (ST_MakeEnvelope(-0.100000,52.110000,0.250000,52.300000, 4326) ~ location2d::geometry) and acp_ts >= 1507762800 and acp_ts < 1507849200 and info @> '{"VehicleRef" : "WP-106"}' and info @> '{"LineRef": "U"}';
                                                                                                                                                                                                QUERY PLAN                                                                                                                                                                                                
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..96.08 rows=2 width=386) (actual time=11342.414..16601.838 rows=2453 loops=1)
   ->  Seq Scan on siri_vm_5  (cost=0.00..0.00 rows=1 width=32) (actual time=0.001..0.001 rows=0 loops=1)
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND (info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
   ->  Bitmap Heap Scan on siri_vm_5_2017_41  (cost=84.03..96.08 rows=1 width=740) (actual time=11342.411..16600.320 rows=2453 loops=1)
         Recheck Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
         Filter: ((acp_ts >= 1507762800) AND (acp_ts < 1507849200) AND ('0103000020E610000001000000050000009A9999999999B9BFAE47E17A140E4A409A9999999999B9BF6666666666264A40000000000000D03F6666666666264A40000000000000D03FAE47E17A140E4A409A9999999999B9BFAE47E17A140E4A40'::geometry ~ (location2d)::geometry))
         Rows Removed by Filter: 3825
         Heap Blocks: exact=6272
         ->  Bitmap Index Scan on siri_vm_5_2017_41_info  (cost=0.00..84.03 rows=3 width=0) (actual time=138.265..138.265 rows=6278 loops=1)
               Index Cond: ((info @> '{"VehicleRef": "WP-106"}'::jsonb) AND (info @> '{"LineRef": "U"}'::jsonb))
 Planning time: 1120.120 ms
 Execution time: 16603.097 ms
(12 rows)


latency average: 37.531 ms
latency stddev: 18.231 ms

```
