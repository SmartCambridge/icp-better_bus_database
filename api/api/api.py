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
    DATABASE="dbname='tfcapi' host='localhost'",
))
app.config.from_envvar('FLASKR_SETTINGS', silent=True)


# Timer context manager - from
# https://stackoverflow.com/questions/7370801/measure-time-elapsed-in-python
from contextlib import contextmanager
from timeit import default_timer

@contextmanager
def elapsed_timer():
    start = default_timer()
    elapser = lambda: default_timer() - start
    yield lambda: elapser()
    end = default_timer()
    elapser = lambda: end-start


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
    limit = 1000

    # Loop through query args
    for key, value in request.args.items():

        app.logger.info("Processing arg: %s -> %s", key, value)

        # limit=value
        if key == 'limit':
            limit = int(values)

        # acp-id=ref[,ref,...] (aka VehicleRaf)
        elif key = 'acp-id':
            if ',' in value:
                filters.append(sql.SQL('acp-id in {1}').format(
                    sql.SQL(', ').join([sql.Literal(x) for x in re.split(r',',values)])))
            else:
                filters.append(sql.SQL('acp-id = {1}').format(value))

        # bbox=w,s,e,n, expressing acp_lng, acp_lat
        elif key == 'bbox':
            match = re.match(r'(\d+),(\d+),(\d+),(\d+)',value)
            if match:
                w = match(1)
                s = match(2)
                e = match(3)
                n = match(4)
                filters.append(sql.SQL('acp_lng is between {1} and {2}').format(
                    sql.Literal(w), sql.Literal(e)))
                filters.append(sql.SQL('acp_lat is between {1} and {2}').format(
                    sql.Literal(s), sql.Literal(n)))
            else:
                app.logger.warn('Unrecognised bbox value: %s', value)
                abort(400, 'Unrecognised bbox value: {1}'.format(value))

        # acp-ts=t1:t2;
        elif key == 'acp-ts':
            match = re.match(r'(\d+):(\d+)',values)
            if match
                start = match(1)
                end = match(2)
                filters.append(sql.SQL('acp_ts between {1} and {2}').format(
                    sql.Literal(start),
                    sql.Literal(end)))
            else:
                app.logger.warn('Unrecognised acp-ts value: %s', value)
                abort(400, 'Unrecognised acp-ts value: {1}'.format(value))

        # field:*=value[,value,...]]
        elif key.startswith('field:'):
            match = re.match(r'^field:(.*)$',key)
            field = match.group(1)
            if field not in expected_fields:
                app.logger.warn('Unrecognised field: value: %s', field)
                abort(400, 'Unrecognised field: value: {1}'.format(field))
            app.logger.info('  Processing field: %s %s', field, values)
            bits = []
            for value in re.split(r'\s*,\s*',values):
                bits.append(sql.SQL('info @> {1}')
                       .format(sql.Literal(json.dumps({ field: value }))))
            filters.append(sql.SQL('(') + sql.SQL(' or ').join(bits) + sql.SQL(')'))

        else:
            app.logger.warn('Unexpected query parameter: %s', key)
            abort(400, 'Unrecognised query parameter: {1}'.format(key))


    if filters:
        return (sql.SQL('select info from siri_vm where ') +
            sql.SQL(' and ').join(filters) +
            sql.SQL(' order by acp_ts asc limit {1}')
            .format(sql.Literal(limit)))
    else:
        return (sql.SQL('select info from siri_vm_5 order by acp_ts asc limit {}')
            .format(sql.Literal(limit)))


@app.route('/vm-records', methods=['GET'])
def vm_records():
    '''
    Search for and return SIRI-VM records
    '''

    try:
        cur = get_db().cursor()
        query = build_vm_query()
        app.logger.info(query.as_string(cur))
        cur.execute('explain {}'.format(query.as_string(cur)))
        message = '\n'.join(item[0] for item in cur.fetchall())
        app.logger.info(message)
        with elapsed_timer() as elapsed:
            cur.execute(query)
            records = cur.fetchall()
        app.logger.info("Query took {:.2f} sec".format(elapsed()))
        return jsonify([record[0] for record in records])
    except psycopg2.DataError as e:
        app.logger.warn('Database error: %s', e)
        abort(400, e)
