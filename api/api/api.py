# A flask API server for thr Adaptive Cities Project

from flask import Flask, g, render_template, jsonify, request, json, abort
import psycopg2
from psycopg2 import sql
import re

# The SIRI-VM fields that can be searched
expected_fields = ['OriginRef', 'DestinationRef','DirectionRef',
                   'LineRef', 'OperatorRef', 'VehicleRef']

app= Flask(__name__)
app.config.from_object(__name__)
app.config.update(dict(
    DATABASE="dbname='acp' host='localhost'",
))
app.config.from_envvar('FLASKR_SETTINGS', silent=True)


def get_db():
    """
    Opens a new database connection if there is none yet for the
    current application context.
    """
    if not hasattr(g, 'db'):
        app.logger.info("Opening database connection")
        g.db = psycopg2.connect(app.config['DATABASE'])
    return g.db


@app.teardown_appcontext
def close_db(error):
    """
    Closes the database again at the end of the request.
    """
    if hasattr(g, 'db'):
        app.logger.info("Closing database connection")
        g.db.close()


@app.route('/')
def hello_world():
    return 'Hello, World'


def build_vm_query():
    '''
    Build a SQL query for VM records
    '''

    filters = []

    # Loop through query args
    for key, values in request.args.items():
        app.logger.info("Processing arg: %s -> %s", key, values)

        # Process 'field:*'
        if key.startswith('field:'):
            match = re.match(r'^field:(.*)$',key)
            field = match.group(1)
            if field not in expected_fields:
                abort(400)
            app.logger.info('  Processing field: %s %s' % (field, values))
            bits = []
            for value in re.split(r'\s*,\s*',values):
                bits.append(sql.SQL('info @> {}')
                       .format(sql.Literal(json.dumps({ field: value }))))
            filters.append(sql.SQL('(') + sql.SQL(' or ').join(bits) + sql.SQL(')'))

    # bbox=w,s,e,n;

    elif key == 'bbox':
        (w, s, e, n) = re.split(r'\s*,\s*',values)
        filters.append(sql.SQL('(ST_MakeEnvelope ({} {} {} {}) ~ location4d')
            .format(sql.Literal(w),sql.Literal(s),sql.Literal(e),sql.Literal(n)))

    #ts_range=t1t2;

    elif key = 'ts-range':
        (start, end) = re.split(r'\s*:\s*',values)
        if start:
            

    #DepartureTime_range=t1t2;

    if filters:
        return (sql.SQL('select info from siri_vm where ') +
            sql.SQL(' and ').join(filters) +
            sql.SQL(' order by acp_ts asc limit 30'))
    else:
        return (sql.SQL('select info from siri_vm order by acp_ts asc limit 30'))


@app.route('/vm-records', methods=['GET'])
def vm_records():
    '''
    Search for and return SIRI-VM records
    '''

    cur = get_db().cursor()
    query = build_vm_query()
    app.logger.info(query.as_string(cur))
    cur.execute(query)
    records = cur.fetchall()
    return jsonify([record[0] for record in records])
