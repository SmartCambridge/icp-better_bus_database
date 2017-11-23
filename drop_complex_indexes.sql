-- Drop indexes from a type 2 table

ALTER TABLE siri_vm_complex_test DROP CONSTRAINT IF EXISTS siri_vm_complex_test_pkey;
DROP INDEX IF EXISTS siri_vm_complex_test_acp_id;
DROP INDEX IF EXISTS siri_vm_complex_test_location4d;
DROP INDEX IF EXISTS siri_vm_complex_test_acp_ts;
DROP INDEX IF EXISTS siri_vm_complex_test_info;