
CREATE EXTENSION postgis;

CREATE TABLE siri_vm (
    id                       SERIAL PRIMARY KEY,
    acp_id                   TEXT,
    location4d               GEOGRAPHY(POINTZM,4326),
    acp_ts                   TIMESTAMP WITH TIME ZONE,
    info                     JSONB
    );

CREATE INDEX siri_vm_acp_id ON siri_vm (acp_id);
CREATE INDEX siri_vm_location ON siri_vm USING GIST (location4d);
CREATE INDEX siri_vm_tstamp ON siri_vm (acp_ts);
CREATE INDEX siri_vm_jsonb ON siri_vm USING GIN (info);
