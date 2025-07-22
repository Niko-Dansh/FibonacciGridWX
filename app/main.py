from dotenv import load_dotenv  # Библиотека для работы с файлом .env
load_dotenv()  # Загружает переменные из .env
from weather import get_city_weather
from csv_utils import save_to_csv
import os

# Установите рабочую директорию в директорию скрипта
os.chdir(os.path.dirname(os.path.abspath(__file__)))


city = "Zelenograd"  # Мой город <3

# Получаем timestamp и словарь с данными
last_updated, city_weather = get_city_weather(city)
city_weather = [city_weather]

# Конвертируем last_updated в безопасное имя файла
# last_updated приходит в формате "YYYY-MM-DD HH:MM"
# заменяем двоеточие на точку или дефис, чтобы было валидно для файловой системы
safe_name = last_updated.replace(" ", "_").replace(":", "-")
filename = f"../data/{safe_name}.csv"  # относительный путь до папки data


save_to_csv(city_weather, filename)
