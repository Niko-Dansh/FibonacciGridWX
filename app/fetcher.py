import psycopg2
from psycopg2.extras import RealDictCursor
import json



def fetch_grid_points(conn_params, limit=None):

    with psycopg2.connect(**conn_params) as conn, \
        conn.cursor(cursor_factory=RealDictCursor) as cur:

        #Делаем коннект с помощью SQL
        sql = 'SELECT point_id, lat, lon FROM grid_points'
        if limit:
            sql += f' LIMIT %s'
            cur.execute(sql, (limit,))
        else:
            cur.execute(sql)
        return cur.fetchall()

def send_payload_to_db(point_id, fetched_at, get_test_response, conn_params):
    insert_sql = '''
    INSERT INTO weather_raw (point_id, fetched_at, payload)
    VALUES (%s, %s, %s)
    '''
    with psycopg2.connect(**conn_params) as conn, conn.cursor() as cur:
        cur.execute(insert_sql, (point_id, fetched_at, json.dumps(get_test_response)))
        conn.commit()


