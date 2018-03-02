#!/usr/bin/env python3

# Construct the loading code for the 'partitioned' 
# table layout in the siri_vm_5 layout

import datetime

table_base = '${table}'

first=datetime.datetime(2017,10,9,0,0,0,tzinfo=datetime.timezone.utc)
last =datetime.datetime(2018,6,30,0,0,0,tzinfo=datetime.timezone.utc)

start = first
while start < last:

    end = start + datetime.timedelta(weeks=1)
    # Year and IOS week number
    week = start.strftime("%Y_%V")
    print()
    print("-- {:.0f} - {:.0f} ({} to {}) {}".format(start.timestamp(), end.timestamp(), start.isoformat(), end.isoformat(), week))

    print("CREATE TABLE {}_{} (".format(table_base,week))
    print("    CHECK ( acp_ts >= {:.0f} and acp_ts < {:.0f} )".format(start.timestamp(), end.timestamp()))
    print(") INHERITS ({});".format(table_base))

    start = end

print()
print()

print("CREATE OR REPLACE FUNCTION {}_insert_trigger()".format(table_base))
print("RETURNS TRIGGER AS \$\$")
print("BEGIN")
predicate='IF'
start = first
while start < last:

    end = start + datetime.timedelta(weeks=1)
    # Year and IOS week number
    week = start.strftime("%Y_%V")
    print("    {} ( NEW.acp_ts >= {:.0f} AND".format(predicate,start.timestamp()))
    print("            NEW.acp_ts < {:.0f} ) THEN".format(end.timestamp()))
    print("       INSERT INTO {}_{} VALUES (NEW.*);".format(table_base,week))
    predicate = 'ELSIF'

    start = end
print("    ELSE")
print("        RAISE EXCEPTION 'Date out of range.  Fix the {}_insert_trigger() function!';".format(table_base))
print("    END IF;")
print("    RETURN NULL;")
print("END;")
print("\$\$")
print("LANGUAGE plpgsql;")    

print()

print("CREATE TRIGGER insert_{}_trigger".format(table_base))
print("    BEFORE INSERT ON {}".format(table_base))
print("    FOR EACH ROW EXECUTE PROCEDURE {}_insert_trigger();".format(table_base))

print()
print('\copy ${table} (acp_id, acp_lng, acp_lat, acp_ts, location2d, location4d, info) ' +
      'FROM PROGRAM \'./"${loader}" "${load_path}"\' (FORMAT CSV, FREEZE TRUE)')
print()

start = first
while start < last:

    end = start + datetime.timedelta(weeks=1)
    # Year and IOS week number
    week = start.strftime("%Y_%V")

    print("CREATE INDEX {0}_{1}_acp_id ON {0}_{1} (acp_id);".format(table_base,week))
    print("CREATE INDEX {0}_{1}_acp_lng ON {0}_{1} (acp_lng);".format(table_base,week))
    print("CREATE INDEX {0}_{1}_acp_lat ON {0}_{1} (acp_lat);".format(table_base,week))
    print("CREATE INDEX {0}_{1}_acp_ts ON {0}_{1} (acp_ts);".format(table_base,week))
    print("CREATE INDEX {0}_{1}_location2d on {0}_{1} USING GIST (location2d);".format(table_base,week))
    print("CREATE INDEX {0}_{1}_location2d_geom on {0}_{1} USING GIST (cast(location2d as geometry));".format(table_base,week))
    print("CREATE INDEX {0}_{1}_location4d on {0}_{1} USING GIST (location4d);".format(table_base,week))
    print("CREATE INDEX {0}_{1}_location4d_geom_nd on {0}_{1} USING GIST (cast(location4d as geometry) gist_geometry_ops_nd);".format(table_base,week))
    print("CREATE INDEX {0}_{1}_info ON {0}_{1} USING GIN (info);".format(table_base,week))
    print()

    start = end

