
CREATE EXTENSION postgis;

/*
   "request_data": [
        {
            "Bearing": "300",
            "DataFrameRef": "1",
            "DatedVehicleJourneyRef": "119",
            "Delay": "-PT33S",
            "DestinationName": "Emmanuel St Stop E1",
            "DestinationRef": "0500CCITY487",
            "DirectionRef": "OUTBOUND",
            "InPanic": "0",
            "Latitude": "52.2051239",
            "LineRef": "7",
            "Longitude": "0.1242290",
            "Monitored": "true",
            "OperatorRef": "SCCM",
            "OriginAimedDepartureTime": "2017-10-25T23:14:00+01:00",
            "OriginName": "Park Road",
            "OriginRef": "0500SSAWS023",
            "PublishedLineName": "7",
            "RecordedAtTime": "2017-10-25T23:59:48+01:00",
            "ValidUntilTime": "2017-10-25T23:59:48+01:00",
            "VehicleMonitoringRef": "SCCM-19597",
            "VehicleRef": "SCCM-19597",
            "acp_id": "SCCM-19597",
            "acp_lat": 52.2051239,
            "acp_lng": 0.124229,
            "acp_ts": 1508972388
        },
*/

/* SRID 27700 is OSGB */

CREATE TABLE siri_vm2 (
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

// And then
// update siri_vm2 set location4d = ST_Transform(temp_geom, 27700);

