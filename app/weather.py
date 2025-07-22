import requests  # библиотека для работы с запросами для API
import os  # Библиотека для работы с Операционной Системой


api_key = os.getenv("WEATHER_API_KEY")  # Получаем спрятанный ключ API
base_url = "https://api.weatherapi.com/v1/current.json"


def get_city_weather(city_input):
    """
    Функция для получение данные о пооде для города с сайта weatherapi.com
    :param city_input: str: Международное название города на английском
    :return: кортеж('дата', {'Параметр': 'Значение'})
    """
    try:
        params = {"key": api_key, "q": city_input, "aqi": "no"}
        resp = requests.get(url=base_url, params=params, timeout=5)
        resp.raise_for_status()
        data_city_current = resp.json().get("current", {})  # "current" Данные по APi
        last_updated = (
            data_city_current.get("last_updated") or "нет данных"
        )  # строка "YYYY-MM-DD HH:MM"
        temp_c = data_city_current.get("temp_c")
        feelslike_c = data_city_current.get("feelslike_c")
        condition_text = data_city_current.get("condition", {}).get("text")
        pressure_mb = data_city_current.get("pressure_mb")
        uv = data_city_current.get("uv")

        data = {
            "city": city_input,
            "condition": condition_text or "нет данных",
            "temperature_c": temp_c if temp_c is not None else "нет данных",
            "feels_like_c": feelslike_c if feelslike_c is not None else "нет данных",
            "pressure_mmHg": (
                round(pressure_mb * 0.75006)
                if pressure_mb is not None
                else "нет данных"
            ),
            "uv_index": uv if uv is not None else "нет данных",
        }

        return last_updated, data

    except requests.RequestException as e:
        print(f"[weather] Произошла ошибка запроса: {e}")
    except Exception as e:
        print(f"[weather] Произошла неожиданная ошибка: {e}")
