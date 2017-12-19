
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

CREATE EXTENSION IF NOT EXISTS cube;

CREATE OR REPLACE FUNCTION journey_enclosing_cube(
      lng double precision[],
      lat double precision[],
      ts double precision[]
)
RETURNS cube AS $$
BEGIN
    RETURN cube(array[least(lng),least(lat),least(ts)],array[greatest(lng),greatest(lat),greatest(ts)]);
END;
$$
LANGUAGE plpgsql;

DROP TABLE IF EXISTS journey;

CREATE TABLE journey (
    journey_id      BIGSERIAL NOT NULL PRIMARY KEY,
    vehicle_ref     TEXT NOT NULL,
    destination_ref TEXT NOT NULL,
    direction_ref   TEXT NOT NULL,
    line_ref        TEXT NOT NULL,
    operator_ref    TEXT NOT NULL,
    departure_time  TIMESTAMP WITH TIME ZONE NOT NULL,
    origin_ref      TEXT NOT NULL,
    longitude       DOUBLE PRECISION[],
    latitude        DOUBLE PRECISION[],
    recorded_at     DOUBLE PRECISION[]
);

INSERT INTO journey (
      vehicle_ref,
      destination_ref,
      direction_ref,
      line_ref,
      operator_ref,
      departure_time,
      origin_ref,
      longitude,
      latitude,
      recorded_at
) SELECT
      info->>'VehicleRef',
      info->>'DestinationRef',
      info->>'DirectionRef',
      info->>'LineRef',
      info->>'OperatorRef',
      info->>'OriginAimedDepartureTime',
      info->>'OriginRef',
      array_agg(info->>'Longitude' order by acp_ts asc)
      array_agg(info->>'Latitude' order by acp_ts asc)
      array_agg(acp_ts order by acp_ts ASC)
FROM
      siri_vm_5_2017_41
GROUP BY
      info->>'VehicleRef',
      info->>'DestinationRef',
      info->>'DirectionRef',
      info->>'LineRef',
      info->>'OperatorRef',
      info->>'OriginAimedDepartureTime',
      info->>'OriginRef';

CREATE INDEX journey_line_ref ON journey (line_ref);
CREATE INDEX journey_departure_time ON journey (departure_time);
CREATE INDEX journry_origin_ref ON journey (origin_ref);

CREATE INDEX journey_lng_lat_ts ON journey 
   USING gist(enclosing_cube(longitude, latitude, recorded_at)) 
   WITH(buffering=on);