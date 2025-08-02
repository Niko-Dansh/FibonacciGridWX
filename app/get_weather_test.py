import requests

base_url = "https://api.weatherapi.com/v1/current.json"

def get_point_weather(lat: float, lon: float, api_key: str):
    response = requests.get(f'https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}')
    response.raise_for_status()
    resp = response.json()
    return resp

