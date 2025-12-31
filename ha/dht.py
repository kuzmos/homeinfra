import time
import json
import board
import adafruit_dht
import paho.mqtt.client as mqtt

# --- Configuration ---
BROKER = "localhost"
PORT = 1883
DEVICE_ID = "dht22_terrace"  # Unique ID for this device
DEVICE_NAME = "Terrace DHT22" # Nice name for Home Assistant

# Topics
TOPIC_TEMP = "temperature"
TOPIC_HUM = "humidity"
# Discovery Topics (Home Assistant convention)
DISC_TOPIC_TEMP = f"homeassistant/sensor/{DEVICE_ID}_temp/config"
DISC_TOPIC_HUM = f"homeassistant/sensor/{DEVICE_ID}_hum/config"
# ---------------------

def send_discovery_config(client):
    """
    Tells Home Assistant: "I exist, I am a thermostat, and I listen to these topics."
    """
    # Temperature Config
    temp_config = {
        "name": "Temperature",
        "unique_id": f"{DEVICE_ID}_temp",
        "state_topic": TOPIC_TEMP,  # <--- MUST match where we publish data
        "unit_of_measurement": "°C",
        "device_class": "temperature",
        "device": {
            "identifiers": [DEVICE_ID],
            "name": DEVICE_NAME,
            "model": "DHT22",
            "manufacturer": "Adafruit"
        }
    }
    
    # Humidity Config
    hum_config = {
        "name": "Humidity",
        "unique_id": f"{DEVICE_ID}_hum",
        "state_topic": TOPIC_HUM,   # <--- MUST match where we publish data
        "unit_of_measurement": "%",
        "device_class": "humidity",
        "device": {
            "identifiers": [DEVICE_ID],
            "name": DEVICE_NAME,
            "model": "DHT22",
            "manufacturer": "Adafruit"
        }
    }

    client.publish(DISC_TOPIC_TEMP, json.dumps(temp_config), retain=True)
    client.publish(DISC_TOPIC_HUM, json.dumps(hum_config), retain=True)
    print("  ✓ Sent Discovery Config")

def publish_data(temperature, humidity):
    print(f"Reading: Temp={temperature}°C, Hum={humidity}%")
    
    # Use VERSION2 to fix the deprecation warning
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=DEVICE_ID)
    
    try:
        client.connect(BROKER, PORT, 60)
        client.loop_start() # Start background thread for network handling
        
        # 1. Send Discovery Config (Ensures HA knows how to read the data)
        send_discovery_config(client)
        
        # 2. Publish Data
        client.publish(TOPIC_TEMP, temperature, retain=True)
        print(f"  ✓ Published to {TOPIC_TEMP}")

        client.publish(TOPIC_HUM, humidity, retain=True)
        print(f"  ✓ Published to {TOPIC_HUM}")
        
        # Wait a moment for messages to actually leave the buffer
        time.sleep(1.0) 
        
        client.loop_stop()
        client.disconnect()
        return True

    except Exception as e:
        print(f"  ✗ MQTT Error: {e}")
        return False

# --- Main Sensor Loop ---
sensor = adafruit_dht.DHT22(board.D2)
max_retries = 10

for attempt in range(max_retries):
    try:
        # Read sensor
        t = sensor.temperature
        h = sensor.humidity
        
        if t is not None and h is not None:
            if publish_data(t, h):
                print("Success. Exiting.")
                sensor.exit()
                exit(0)
        else:
            print("Sensor returned None, retrying...")
            
    except RuntimeError as error:
        # Standard DHT22 error, just retry
        print(f"Sensor read retry: {error.args[0]}")
        time.sleep(2.0)
    except Exception as error:
        print(f"Critical Error: {error}")
        sensor.exit()
        exit(1)
        
    time.sleep(1.0)

print("Failed to get reading after retries.")
sensor.exit()
