-- Drop indexes from a simple table

ALTER TABLE siri_vm_simple_test DROP CONSTRAINT IF EXISTS siri_vm_simple_test_pkey;

DROP INDEX siri_vm_simple_test_info;
DROP INDEX siri_vm_simple_test_acp_id;
DROP INDEX siri_vm_simple_test_acp_lat;
DROP INDEX siri_vm_simple_test_acp_lng;
DROP INDEX siri_vm_simple_test_acp_ts;
