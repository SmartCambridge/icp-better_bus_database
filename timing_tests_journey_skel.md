
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

```execute
select * from journey where enclosing_cube(pos) && cube(array[0.08008,52.205029,'-Infinity'::double precision], array[0.108576,52.215548,'Infinity'::double precision]);
```

One day
-------

Try just retrieving a full day's data:

```execute
select * from journey where enclosing_cube(pos) && cube(array['-Infinity'::double precision,'-Infinity'::double precision,1507762800], array['Infinity'::double precision,'Infinity'::double precision,1507849200]);
```

Small box and one day
---------------------

Add in a 24 hour time constraint:

```execute
select * from journey where enclosing_cube(pos) && cube(array[0.08008,52.205029,1507762800],array[0.108576,52.215548,1507849200]);
```

Big box and one day
-------------------

A bigger box (Sawston <-> Cotenham, Camborne <-> Fulbourn) -0.100000,52.110000,0.250000,52.300000
http://bboxfinder.com/#52.110000,-0.100000,52.300000,0.250000

```execute
select * from journey where enclosing_cube(pos) && cube(array[-0.100000,52.110000,1507762800],array[0.250000,52.300000,1507849200]);
```

Big box, one day and vehicle\_ref
---------------------------

This is the IJL 'indicitave' query


```execute
select * from journey where enclosing_cube(pos) && cube(array[-0.100000,52.110000,1507762800],array[0.250000,52.300000,1507849200]) and vehicle_ref = 'WP-106';
```

Big box, one day, "VehicleRef" and "LineRef"
--------------------------------------------

```execute
select * from journey where enclosing_cube(pos) && cube(array[-0.100000,52.110000,1507762800],array[0.250000,52.300000,1507849200]) and vehicle_ref = 'WP-106' and line_ref = 'U';
```

