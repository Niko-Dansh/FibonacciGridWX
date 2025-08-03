import requests

base_url = "https://api.openweathermap.org/data/2.5/weather"

def get_point_weather(lat: float, lon: float, api_key: str):
    response = requests.get(base_url, params={'lat': lat, 'lon': lon, 'appid': api_key})
    response.raise_for_status()
    resp = response.json()
    return resp

