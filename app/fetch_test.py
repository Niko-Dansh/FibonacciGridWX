import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime, timezone
import json



def fetch_grid_points(conn_params, limit=None):

    #Коннектимся к постгрессу
    conn = psycopg2.connect(**conn_params) # ** - распаковка словарика {'port': 5432} -> port=5432
    cur = conn.cursor(cursor_factory=RealDictCursor) # Use RealDictCursor to get rows as dicts

    #Делаем коннект с помощью SQL
    sql = 'SELECT point_id, lat, lon FROM grid_points'
    if limit:
        sql += f' LIMIT {limit}'

    cur.execute(sql)
    rows = cur.fetchall()

    cur.close()
    conn.close()
    return rows


def send_payload_to_db(point_id, get_test_response, conn_params):
    fetched_at = datetime.now(timezone.utc)

    insert_sql = '''
    INSERT INTO weather_raw (point_id, fetched_at, payload)
    VALUES (%s, %s, %s)
    '''
    connection_to_send = psycopg2.connect(**conn_params)
    cur_2_send_to_table = connection_to_send.cursor(cursor_factory=RealDictCursor)

    real_JSON_get_test_response = json.dumps(get_test_response)
    cur_2_send_to_table.execute(insert_sql, (point_id, fetched_at, real_JSON_get_test_response))

    connection_to_send.commit()

    connection_to_send.close()
    cur_2_send_to_table.close()

