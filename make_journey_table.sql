
--J "VehicleRef":
--J "DestinationName":
--J "DestinationRef":
--J "DirectionRef":
--J "LineRef":
--J "OperatorRef":
--J "OriginAimedDepartureTime":
--J "OriginName":
--J "OriginRef":
--P "Latitude":
--P "Longitude":
--P "RecordedAtTime":
--P "Bearing"
--P "Delay":
--P "InPanic":
--x "DataFrameRef":
--x "DatedVehicleJourneyRef":
--x "Latitude":
--x "Longitude":
--x "Monitored":
--x "PublishedLineName":
--x "RecordedAtTime":
--x "ValidUntilTime":
--x "VehicleMonitoringRef":
--x "VehicleRef":

SET work_mem TO '2GB';
SET maintenance_work_mem TO '2GB';

CREATE EXTENSION IF NOT EXISTS cube;

DROP TABLE IF EXISTS journey;

DROP FUNCTION IF EXISTS enclosing_cube(pos_report[]);

DROP TYPE IF EXISTS pos_report;

CREATE TYPE pos_report AS (
    lng       double precision,
    lat       double precision,
    ts        double precision,
    bearing   smallint,
    delay     interval,
    in_panic  smallint
);

CREATE FUNCTION enclosing_cube(pos pos_report[])
RETURNS cube AS $$
DECLARE 
    lx double precision DEFAULT MIN(p.lng) FROM UNNEST(pos) AS p;
    ly double precision DEFAULT MIN(p.lat) FROM UNNEST(pos) AS p;
    lt double precision DEFAULT MIN(p.ts) FROM UNNEST(pos) AS p;
    hx double precision DEFAULT MAX(p.lng) FROM UNNEST(pos) AS p;
    hy double precision DEFAULT MAX(p.lat) FROM UNNEST(pos) AS p;
    ht double precision DEFAULT MAX(p.ts) FROM UNNEST(pos) AS p;

BEGIN
    RETURN cube(array[lx,ly,lt],array[hx,hy,ht]);
END;
$$
LANGUAGE plpgsql IMMUTABLE;

CREATE TABLE journey (
    acp_journey_id   BIGSERIAL NOT NULL PRIMARY KEY,
    vehicle_ref      TEXT NOT NULL,
    destination_ref  TEXT NOT NULL,
    destination_name TEXT NOT NULL,
    direction_ref    TEXT NOT NULL,
    line_ref         TEXT NOT NULL,
    operator_ref     TEXT NOT NULL,
    departure_time   TIMESTAMP WITH TIME ZONE NOT NULL,
    origin_ref       TEXT NOT NULL,
    origin_name      TEXT NOT NULL,
    pos              pos_report[]
);

INSERT INTO journey (
      vehicle_ref,
      destination_ref,
      destination_name,
      direction_ref,
      line_ref,
      operator_ref,
      departure_time,
      origin_ref,
      origin_name,
      pos
) SELECT
      info->>'VehicleRef',
      info->>'DestinationRef',
      info->>'DestinationName',
      info->>'DirectionRef',
      info->>'LineRef',
      info->>'OperatorRef',
      (info->>'OriginAimedDepartureTime')::timestamp with time zone,
      info->>'OriginRef',
      info->>'OriginName',
      ARRAY_AGG(
        ROW(
          (info->>'Longitude')::double precision,
          (info->>'Latitude')::double precision,
          acp_ts,
          (info->>'Bearing')::smallint,
          CASE 
            WHEN LEFT(info->>'Delay', 1) = '-' 
            THEN TRIM(LEADING '-' FROM info->>'Delay')::interval * -1
            ELSE TRIM(LEADING '-' FROM info->>'Delay')::interval
          END,
          (info->>'InPanic')::smallint
        )::pos_report order by acp_ts asc
      )
FROM
      siri_vm_5
GROUP BY
      info->>'VehicleRef',
      info->>'DestinationRef',
      info->>'DestinationName',
      info->>'DirectionRef',
      info->>'LineRef',
      info->>'OperatorRef',
      info->>'OriginAimedDepartureTime',
      info->>'OriginRef',
      info->>'OriginName';

CREATE INDEX journey_line_ref ON journey (line_ref);
CREATE INDEX journey_departure_time ON journey (departure_time);
CREATE INDEX journry_origin_ref ON journey (origin_ref);

CREATE INDEX journey_lng_lat_ts ON journey 
   USING gist(enclosing_cube(pos)) 
   WITH (BUFFERING=ON);
