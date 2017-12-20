-- Print size stats for the various siri_vm databases

\pset pager off
\timing off

\d siri_vm
\d siri_vm2
\d siri_vm_3
\d siri_vm_4
\d siri_vm_5
\d siri_vm_5_2017_41
\d journey

SELECT
    relname as tablename,
    to_char(reltuples::bigint, '999,999,999') AS records
FROM pg_class
where relname in (
    select tablename
    from pg_tables
    where tablename like 'siri_v%' or tablename = 'journey'
)
order by tablename;

select
    tablename,
    pg_size_pretty(pg_relation_size(tablename::text,'main')) as Main,
    pg_size_pretty(pg_relation_size(tablename::text,'fsm')) as Free_space_map,
    pg_size_pretty(pg_relation_size(tablename::text,'vm')) as Visability_map,
    pg_size_pretty(pg_relation_size(tablename::text,'init')) as initialisation,
    pg_size_pretty(
        pg_relation_size(tablename::text,'main') +
        pg_relation_size(tablename::text,'fsm') +
        pg_relation_size(tablename::text,'vm') +
        pg_relation_size(tablename::text,'init')
    ) as total
from (
    select tablename
    from pg_tables
    where tablename like 'siri_v%' or tablename = 'journey'
) as t(tablename)
order by tablename;


select
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::text,'main')) as size
from (
    select tablename, indexname
    from pg_indexes
    where tablename in (
        select tablename
        from pg_tables
        where tablename like 'siri_v%' or tablename = 'journey'
    )
) as i
order by tablename, indexname;
