import paho.mqtt.publish as publish
import time
import board
import adafruit_dht
import json

# Sensor data pin is connected to GPIO 2
sensor = adafruit_dht.DHT22(board.D2)

broker="localhost"
port=1883

def output_data(temperature, humidity):
    # debug
    # print("Temperature: {:g}\u00b0C, Humidity: {:g}%".format(temperature, humidity))
    
    publish.single("temperature", temperature, hostname=broker)
    publish.single("humidity", humidity, hostname=broker)

tries = 5
while tries:
    try:
        temperature_c = sensor.temperature
        humidity = sensor.humidity
        output_data(temperature_c, humidity)
        exit()      # Exit after successful read
    except RuntimeError as error:
        print(error.args[0])
        time.sleep(2.0)
        tries -=1
        continue
    except Exception as error:
        sensor.exit()
