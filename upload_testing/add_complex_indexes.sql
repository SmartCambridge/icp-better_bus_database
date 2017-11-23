-- Add the indexes to a 'complex' table

CREATE INDEX siri_vm_complex_test_acp_id ON siri_vm_complex_test (acp_id);
CREATE INDEX siri_vm_complex_test_location4d ON siri_vm_complex_test USING GIST (location4d);
CREATE INDEX siri_vm_complex_test_acp_ts ON siri_vm_complex_test (acp_ts);
CREATE INDEX siri_vm_complex_test_info ON siri_vm_complex_test USING GIN (info);
CREATE UNIQUE INDEX siri_vm_complex_test_pkey ON siri_vm_complex_test (id);
ALTER TABLE siri_vm_complex_test ADD PRIMARY KEY USING INDEX siri_vm_complex_test_pkey;