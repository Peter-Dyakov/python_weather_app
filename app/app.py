from flask import Flask, render_template, request, jsonify
import requests
import time
import os


app = Flask(__name__)

# OpenWeatherMap API key (you need to sign up to get a key)
API_KEY = os.getenv('WEATHER_API_TOKEN')
API_URL = "http://api.openweathermap.org/data/2.5/weather?q={}&appid={}&units=metric"

# Cache dictionary to store the temperature for cities
cache = {}

def get_temperature(city):
    """Fetch temperature data for the city, utilizing cache."""
    current_time = time.time()
    
    # Check if the city is in the cache and the data is less than 10 minutes old
    if city in cache and current_time - cache[city]['timestamp'] < 600:  # 10 minutes
        return cache[city]['temperature']
    
    # Make the API request to get the temperature
    response = requests.get(API_URL.format(city, API_KEY))
    
    if response.status_code == 200:
        data = response.json()
        temperature = data['main']['temp']
        # Store in cache with timestamp
        cache[city] = {'temperature': temperature, 'timestamp': current_time}
        return temperature
    else:
        return None

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/get_temperature', methods=['POST'])
def get_temperature_route():
    city = request.form.get('city')
    temperature = get_temperature(city)
    if temperature is not None:
        return jsonify({'city': city, 'temperature': temperature})
    else:
        return jsonify({'error': 'City not found or API error'})

@app.route('/health')
def health_check():
    # Liveness probe: simple check to confirm the app is running
    return jsonify(status="healthy"), 200

@app.route('/ready')
def readiness_check():
    # Readiness probe: check if the app is ready to serve traffic (e.g., DB connection)
    # You can extend this to include more comprehensive checks
    return jsonify(status="ready"), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
