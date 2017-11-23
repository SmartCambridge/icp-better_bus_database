
CREATE EXTENSION postgis;


-- Plain table, just containing the JSON (suitably indexed)
DROP TABLE IF EXISTS siri_vm_simple_test;
CREATE TABLE siri_vm_simple_test (
    id                       SERIAL PRIMARY KEY,
    info                     JSONB
    );

CREATE INDEX siri_vm_simple_test_info ON siri_vm_simple_test USING GIN (info);
CREATE INDEX siri_vm_simple_test_acp_id ON siri_vm_simple_test ((info->>'acp_id'));
CREATE INDEX siri_vm_simple_test_acp_lat ON siri_vm_simple_test ((info->>'acp_lng'));
CREATE INDEX siri_vm_simple_test_acp_lng ON siri_vm_simple_test ((info->>'acp_lat'));
CREATE INDEX siri_vm_simple_test_acp_ts ON siri_vm_simple_test (to_timestamp((info->>'acp_ts')::double precision));


-- Multi-column table with interesting data broken out
DROP TABLE IF EXISTS siri_vm_complex_test;
CREATE TABLE siri_vm_complex_test (
    id                       SERIAL PRIMARY KEY,
    acp_id                   TEXT,
    location4d               GEOGRAPHY(POINTZM,4326),
    acp_ts                   TIMESTAMP WITH TIME ZONE,
    info                     JSONB
    );

CREATE INDEX siri_vm_complex_test_acp_id ON siri_vm_complex_test (acp_id);
CREATE INDEX siri_vm_complex_test_location4d ON siri_vm_complex_test USING GIST (location4d);
CREATE INDEX siri_vm_complex_test_acp_ts ON siri_vm_complex_test (acp_ts);
CREATE INDEX siri_vm_complex_test_info ON siri_vm_complex_test USING GIN (info);

--CREATE TABLE siri_vm (
--    id                       SERIAL PRIMARY KEY,
--    filename                 TEXT,
--    acp_id                   TEXT,
--    location4d               GEOGRAPHY(POINTZM,4326),
--    acp_ts                   TIMESTAMP WITH TIME ZONE,
--    info                     JSONB
--   );


--CREATE INDEX siri_vm_acp_id ON siri_vm (acp_id);
--CREATE INDEX siri_vm_location4d ON siri_vm3 USING GIST (location4d);
--CREATE INDEX siri_vm_acp_ts ON siri_vm (acp_ts);
--CREATE INDEX siri_vm_info ON siri_vm USING GIN (info);