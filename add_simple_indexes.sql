-- Add the indexes to a 'simple' table

CREATE INDEX siri_vm_simple_test_info ON siri_vm_simple_test USING GIN (info);
CREATE INDEX siri_vm_simple_test_acp_id ON siri_vm_simple_test ((info->>'acp_id'));
CREATE INDEX siri_vm_simple_test_acp_lat ON siri_vm_simple_test ((info->>'acp_lng'));
CREATE INDEX siri_vm_simple_test_acp_lng ON siri_vm_simple_test ((info->>'acp_lat'));
CREATE INDEX siri_vm_simple_test_acp_ts ON siri_vm_simple_test (to_timestamp((info->>'acp_ts')::double precision));

CREATE UNIQUE INDEX siri_vm_simple_test_pkey ON siri_vm_simple_test (id);
ALTER TABLE siri_vm_simple_test ADD PRIMARY KEY USING INDEX siri_vm_simple_test_pkey;