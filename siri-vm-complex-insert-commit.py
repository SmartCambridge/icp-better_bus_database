#!/usr/bin/env python3

'''
Given one or more directories containing SIRI-VM data in 
Json on the command line, insert drrived fields and the request_data 
records into siri_vm_complex_test
'''

import json
import sys
import os
import psycopg2

'''
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
'''

conn = psycopg2.connect("dbname='acp' host='localhost'")
cur = conn.cursor()

insert = ('INSERT INTO siri_vm_complex_test (acp_id, location4d, acp_ts, info) '
         'values (%s, %s, to_timestamp(%s), %s)')

for dir in sys.argv[1:]:
    for root, dirs, files in os.walk(dir):
        for filename in files:
            #print('.', end='', flush=True)
            # Skip any non-json files
            if not filename.endswith(".json"):
                continue
            pathname = os.path.join(root, filename)

            with open(pathname) as data_file:
                data = json.load(data_file)

            for record in data["request_data"]:

                point = "SRID=4326;POINT({} {} 0 {})".format(
                    record["acp_lng"],
                    record["acp_lat"],
                    record["acp_ts"]
                    )

                cur.execute(insert, (
                    record["acp_id"],
                    point,
                    record["acp_ts"],
                    json.dumps(record),
                ))

            conn.commit()
