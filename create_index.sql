CREATE UNIQUE INDEX siri_vm2_pkey ON siri_vm2 (id);
ALTER TABLE siri_vm2 ADD PRIMARY KEY USING INDEX siri_vm2_pkey;
CREATE INDEX siri_vm2_acp_id ON siri_vm2 (acp_id);
CREATE INDEX siri_vm2_acp_ts ON siri_vm2 (acp_ts);
CREATE INDEX siri_vm2_location4d ON siri_vm2 USING GIST (location4d);
CREATE INDEX siri_vm2_line_ref ON siri_vm2 (line_ref);
CREATE INDEX siri_vm2_origin_ref ON siri_vm2 (origin_ref);
CREATE INDEX siri_vm2_origin_departure_ts ON siri_vm2 (origin_departure_ts);
