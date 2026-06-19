import logging
import os

logger = logging.getLogger("led_controller")
logging.basicConfig(level=logging.INFO)

MQTT_BROKER = os.environ.get("MQTT_BROKER", "127.0.0.1")
MQTT_PORT = int(os.environ.get("MQTT_PORT", 1883))
TOPIC_FACE_STATE = "robot/face/state"

_client = None

def _get_client():
    global _client
    if _client is None:
        try:
            import paho.mqtt.client as mqtt
            _client = mqtt.Client()
            _client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
            _client.loop_start()
        except ImportError:
            logger.warning("paho-mqtt not installed. LED controller running in mock mode.")
            _client = "MOCK"
        except Exception as e:
            logger.error(f"MQTT connect failed: {e}")
            _client = "MOCK"
    return _client

# Valid states matching the design spec
STATES = {
    "IDLE",
    "LISTENING",
    "THINKING",
    "SPEAKING",
    "SUCCESS",
    "ERROR",
    "ALERT_HIGH",
    "ALERT_MEDIUM",
    "MEASURING"
}

current_state = "IDLE"

def set_led_state(state: str) -> bool:
    global current_state
    if state not in STATES:
        logger.warning(f"Invalid LED state requested: {state}")
        return False
    
    current_state = state
    logger.info(f"[LED MATRIX] State transition -> {state}")
    
    client = _get_client()
    if client == "MOCK" or client is None:
        return True

    try:
        client.publish(TOPIC_FACE_STATE, state, qos=0)
        return True
    except Exception as e:
        logger.error(f"MQTT publish failed: {e}")
        return False

def get_current_led_state() -> str:
    return current_state
