# Un client MQTT en python

## Source complet

``` python
# ajouter la lib paho : pip install paho
# python2.7
import paho.mqtt.client as mqtt
import json
import base64
import logging

# config
mqttServer = "loraserver.tetaneutral.net"
appID = "5"
deviceID = "010203040506070b"

# du log pour debug
logging.basicConfig(level=logging.DEBUG)


# callback appele lors de la reception d un message
def on_message(mqttc, obj, msg):
    jsonMsg = json.loads(msg.payload)
    device = jsonMsg["devEUI"]
    gw = jsonMsg["rxInfo"][0]["gatewayID"]
    rssi = jsonMsg["rxInfo"][0]["rssi"]
    data = base64.b64decode(jsonMsg["data"])
    print("dev id : " + device + ", gw id : " + gw + ", data : " + data +
          ", rssi : "+str(rssi))


# creation du client
mqttc = mqtt.Client()

mqttc.on_message = on_message

logger = logging.getLogger(__name__)

mqttc.enable_logger(logger)

mqttc.connect(mqttServer, 1883, 60)

# soucription au device
mqttc.subscribe("application/"+appID+"/device/"+deviceID+"/rx", 0)

mqttc.loop_forever()

```
