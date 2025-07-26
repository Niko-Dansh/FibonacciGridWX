import os # Библиотека для работы с операционной системйо
from dotenv import load_dotenv  # Библиотека для работы с файлом .env
load_dotenv()  # Загружает переменные из .env
from fetch_test import fetch_grid_points, send_payload_to_db
from get_weather_test import get_point_weather
import time


# Установите рабочую директорию в директорию скрипта
os.chdir(os.path.dirname(os.path.abspath(__file__)))
conn_params = {
    'host': os.getenv('DB_HOST'),
    'port': int(os.getenv('DB_PORT')),
    'dbname': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
}
api_key = os.getenv('OWM_API_KEY')

fetch_600 = fetch_grid_points(conn_params=conn_params, limit=1000)


for unique_row in fetch_600:
    point_id = unique_row['point_id']
    lat = unique_row['lat']
    lon = unique_row['lon']
    get_test_response = get_point_weather(lat, lon, api_key)
    print(get_test_response)
    #send_payload_to_db(point_id=point_id, get_test_response=get_test_response, conn_params=conn_params)
    time.sleep(1)