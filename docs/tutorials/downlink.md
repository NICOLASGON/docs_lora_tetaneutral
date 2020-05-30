# Envoyer des données au device

!!! tip "Objectif"
    Envoyer des données au noeud LoRaWAN (ici un Feather M0) et les traiter (allumer une LED qui peut symboliser un relais ou tout autre composant)

Comme pour l'émission (_uplink_) et le traitement de données depuis l'objet, l'envoi de données vers l'objet (_downlink_) est défini par le protocole LoRaWAN.

Lorsque l'objet envoie des données, toutes les passerelles à proximité reçoivent le paquet et le transmettent au serveur de réseau (loraserver). Celui-ci choisit alors le paquet de la passerelle la mieux placée notamment sur la base de la qualité de la liaison radio avec l'objet.

Une fois que l'objet a reçu un accusé de réception de la passerelle la mieux placée, il attend durant deux fenêtres temporelles (_RX Windows_) l’éventuelle réception d'un message (_downlink message_).

!!! tip
    Le première fenêtre dure 1s et la seconde 2s. Durant ces (_RX Windows_), l'objet attend une info indiquant que des données sont dans la file d'attente pour être transmises. Si c'est la cas, la fenêtre sera prolongé le temps nécessaire (maximum 3s). Tout cela est défini dans le protocole. Pour info, il y a deux fenêtres de _join_ une de 5s et l'autre de 6s.


De son côté, le serveur de réseau, une fois l'accusé de réception envoyé via la passerelle, regarde s'il n'y a pas des messages à envoyer dans le file d'attente de l'objet. Si oui, il les transmet à la passerelle qui va utiliser une des fenêtres temporelles durant lesquelles l'objet écoute.

La réception effective des données par l'objet n'est donc pas immédiate. Ce n'est pas une limitation mais une fonctionnalité du protocole. Rappelons qu'il est destiné à des réseaux longue portée, bas débit et surtout basse consommation. Si cela ne correspond pas à vos besoins, voir du côté du Wifi, Bluetooth, zigbee...

!!! warning "Pour les utilisateurs avec un compte sur les serveurs"

    ``` shell
        ssh root@loraserver.tetaneutral.net -p2222
    ```

    Comme loraserver est dans un container docker, il n'y rien dans `/etc/var/log`. Pour voir en temps réel les 30 derniers messages de log du loraserver :

    ``` shell
        docker logs --tail 30 -f loraserverdocker_loraserver_1
    ```

    Plus d'infos ici : https://docs.docker.com/engine/reference/commandline/logs/

    ``` shell
        docker logs --tail 40 -f loraserverdocker_appserver_1
    ```

## Envoyer des données via MQTT

Selon la [documentation](https://www.loraserver.io/lora-app-server/integrate/data/), il suffit de publier sur le topic : `application/[applicationID]/device/[devEUI]/tx`

avec une payload du type suivant :

``` json
{
    "reference": "abcd1234",                  // reference which will be used on ack or error (this can be a random string)
    "confirmed": true,                        // whether the payload must be sent as confirmed data down or not
    "fPort": 10,                              // FPort to use (must be > 0)
    "data": "...."                            // base64 encoded data (plaintext, will be encrypted by LoRa Server)
    "object": {                               // decoded object (when application coded has been configured)
        "temperatureSensor": {"1": 25},       // when providing the 'object', you can omit 'data'
        "humiditySensor": {"1": 32}
    }
}
```

Voici un exemple de payload. Ici nous envoyons 1 codé en base 64 :


Fichier testpayload
``` json
{
    "reference": "abcd1234",
    "confirmed": true,
    "fPort": 10,
    "data": "MQo="
}
```

et pour l'envoyer à l'objet :

``` shell
 mosquitto_pub -h loraserver.tetaneutral.net -t "application/5/device/010203040506070b/tx" -f testpayload
```

pour encoder un texte en base 64 faire :

``` shell
 echo "texte" | base64
```

!!! tip
    On peut aussi utiliser l'API de loraserver : https://www.loraserver.io/lora-app-server/integrate/api/
    TODO...

## Traiter les données reçues

Dans l'automate LMIC, on peut rajouter l'appel à une fonction que l'on nommera, par exemple, `do_if_data_received()`.

``` c
case EV_TXCOMPLETE:
    Serial.println(F("EV_TXCOMPLETE (includes waiting for RX windows)"));
    if (LMIC.txrxFlags & TXRX_ACK)
        Serial.println(F("Received ack"));
    if (LMIC.dataLen)
    {
        Serial.println(F("Received "));
        Serial.println(LMIC.dataLen);
        Serial.println(F(" bytes of payload"));
        do_if_data_received();
    }
```

Les données reçues sont stockées dans un tableau d'entiers non signés de type `u1_t` (en fait de type `uint8_t`) d'une longueur maximum de 64 bits nommé `LMIC.frame` (voir ligne 250 du fichier `lmic.h`).

Le source de `do_if_data_received()` peut être :

``` c
void do_if_data_received()
{
    for (int i = 0; i < LMIC.dataLen; i++)
    {
        if (LMIC.frame[LMIC.dataBeg + i] < 0x10)
        {
            Serial.print(F("0"));
        }
        Serial.write(LMIC.frame[LMIC.dataBeg + i]);
    }
    Serial.println("");
    if (LMIC.frame[LMIC.dataBeg] == 49) // FIXME: pas très heureux...
    {
        digitalWrite(13, HIGH);
    }
    else
    {
        digitalWrite(13, LOW);
    }
}
```

## Source complet

``` c
/*******************************************************************************
 * Copyright (c) 2015 Thomas Telkamp and Matthijs Kooijman
 * Modified by NG and RB (IUT de Blagnac) and plenty of nice folks 
 * from linux-tarn and linuxédu.
 * This uses OTAA (Over-the-air activation), where a DevEUI and
 * application key is configured, which are used in an over-the-air
 * activation procedure where a DevAddr and session keys are
 * assigned/generated for use with all further communication.
 * 
 * This uses a LM36 for temperature measurement and a PIR motion sensor
 * 
 * To use this sketch, first register your application and device with
 * the loraserver, to set or generate an AppEUI, DevEUI and AppKey.
 * Multiple devices can use the same AppEUI, but each device has its own
 * DevEUI and AppKey.
 *
 * Do not forget to define the radio type correctly in config.h.
 *
 *******************************************************************************/

#include <Arduino.h>
#include <lmic.h>
#include <hal/hal.h>
#include <SPI.h>
#include <OneWire.h>
#include <DallasTemperature.h>

/******************************************************************************/
/* OneWire                                                                    */
/******************************************************************************/
// DS18B20 on Feather M0

#define ONE_WIRE_BUS 12      // capteur de temperature
#define PIR_MOTION_SENSOR 11 //Use pin 2 to receive the signal from the module
#define LED_DOWNLINK 13      // Led allumée/éteinte suivant message envoyé au device

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature.
DallasTemperature sensors(&oneWire);

// Compteur de mouvements détectés par le PIR MOtion Sensor
uint32_t nbreMvt = 0;

/******************************************************************************/
/* LoRaWAN                                                                    */
/******************************************************************************/

// This EUI must be in *little-endian format* (least-significant-byte first)
// Necessaire pour le protocole mais inutile pour l'implémentation dans loraserver
// On peut donc mettre de l'aléatoire ou :

static const u1_t APPEUI[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

// DEVEUI should also be in *little endian format*

static const u1_t DEVEUI[8] = {0x0b, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01};

// This key should be in big endian format

static const u1_t APPKEY[16] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

// Copie en mémoire des EUI et APPKEY
void os_getArtEui(u1_t *buf) { memcpy_P(buf, APPEUI, 8); }  // copy in flash memory
void os_getDevEui(u1_t *buf) { memcpy_P(buf, DEVEUI, 8); }  // copy in flash memory
void os_getDevKey(u1_t *buf) { memcpy_P(buf, APPKEY, 16); } // copy in flash memory

// Schedule TX every this many seconds (might become longer due to duty
// cycle limitations). 60 au début
const unsigned TX_INTERVAL = 10;

/******************************************************************************/
/* pin mapping                                                                */
/******************************************************************************/

const lmic_pinmap lmic_pins = {
    .nss = 8,
    .rxtx = LMIC_UNUSED_PIN,
    .rst = LMIC_UNUSED_PIN,
    .dio = {3, 6, LMIC_UNUSED_PIN}, //io1 pin is connected to pin 6, io2 vers pin 11
};

/******************************************************************************/
/* Traitement données reçues                                                  */
/******************************************************************************/

void do_if_data_received()
{
    for (int i = 0; i < LMIC.dataLen; i++)
    {
        if (LMIC.frame[LMIC.dataBeg + i] < 0x10)
        {
            Serial.print(F("0"));
        }
        Serial.write(LMIC.frame[LMIC.dataBeg + i]);
    }
    if (LMIC.frame[LMIC.dataBeg] == 49) // pas très heureux...
    {
        digitalWrite(LED_DOWNLINK, HIGH);
        Serial.print("reçu 1");
    }
    else
    {
        digitalWrite(LED_DOWNLINK, LOW);
        Serial.print("PAS reçu 1");

    }
}

/******************************************************************************/
/* Automate LMIC                                                              */
/******************************************************************************/

static osjob_t sendjob;

void do_send(osjob_t *j)
{
    // Check if there is not a current TX/RX job running
    if (LMIC.opmode & OP_TXRXPEND)
    {
        Serial.println(F("OP_TXRXPEND, not sending"));
    }
    else
    {
        Serial.print("Requesting temperatures...");

        sensors.requestTemperatures(); // Send the command to get temperatures

        Serial.println(nbreMvt);
        // After we got the temperatures, we can prepare the payload.
        // We use the function ByIndex, and as an example get the temperature from the first sensor only.
        //Serial.print("Temperature for the device 1 (index 0) is: ");

        float temperature = sensors.getTempCByIndex(0);

        // We have to convert the float into an ASCII representation
        // and load the paylod

        // we build the packet and concatenate text with float to string + 3 décimales

        //String packet = "Temp chez RB: " + String(temperature, 3) + "*C\n";
        String packet = String(temperature, 3) + ":" + String(nbreMvt);
        uint8_t lmic_packet[packet.length() + 1];

        packet.getBytes(lmic_packet, packet.length() + 1);
        nbreMvt = 0;
        // Prepare upstream data transmission at the next possible time.
        LMIC_setTxData2(1, lmic_packet, sizeof(lmic_packet) - 1, 0);

        Serial.println(F("Packet queued"));
    }
    // Next TX is scheduled after TX_COMPLETE event.
}

void onEvent(ev_t ev)
{
    Serial.print(os_getTime());
    Serial.print(": ");
    switch (ev)
    {
    case EV_SCAN_TIMEOUT:
        Serial.println(F("EV_SCAN_TIMEOUT"));
        break;
    case EV_BEACON_FOUND:
        Serial.println(F("EV_BEACON_FOUND"));
        break;
    case EV_BEACON_MISSED:
        Serial.println(F("EV_BEACON_MISSED"));
        break;
    case EV_BEACON_TRACKED:
        Serial.println(F("EV_BEACON_TRACKED"));
        break;
    case EV_JOINING:
        Serial.println(F("EV_JOINING"));
        break;
    case EV_JOINED:
        Serial.println(F("EV_JOINED"));

        // Disable link check validation (automatically enabled
        // during join, but not supported by TTN at this time).
        LMIC_setLinkCheckMode(0);
        break;
    case EV_RFU1:
        Serial.println(F("EV_RFU1"));
        break;
    case EV_JOIN_FAILED:
        Serial.println(F("EV_JOIN_FAILED"));
        break;
    case EV_REJOIN_FAILED:
        Serial.println(F("EV_REJOIN_FAILED"));
        break;
        break;
    case EV_TXCOMPLETE:
        Serial.println(F("EV_TXCOMPLETE (includes waiting for RX windows)"));
        if (LMIC.txrxFlags & TXRX_ACK)
            Serial.println(F("Received ack"));
        if (LMIC.dataLen)
        {
            Serial.println(F("Received "));
            Serial.println(LMIC.dataLen);
            Serial.println(F(" bytes of payload"));
            // fonction éxécutée en cas de downlink
            do_if_data_received();
        }
        // Schedule next transmission
        os_setTimedCallback(&sendjob, os_getTime() + sec2osticks(TX_INTERVAL), do_send);
        break;
    case EV_LOST_TSYNC:
        Serial.println(F("EV_LOST_TSYNC"));
        break;
    case EV_RESET:
        Serial.println(F("EV_RESET"));
        break;
    case EV_RXCOMPLETE:
        // data received in ping slot
        Serial.println(F("EV_RXCOMPLETE"));
        break;
    case EV_LINK_DEAD:
        Serial.println(F("EV_LINK_DEAD"));
        break;
    case EV_LINK_ALIVE:
        Serial.println(F("EV_LINK_ALIVE"));
        break;
    default:
        Serial.println(F("Unknown event"));
        break;
    }
}

void setup()
{

    pinMode(PIR_MOTION_SENSOR, INPUT);
    Serial.begin(9600);

    //**** OneWire ****
    Serial.println("Dallas Temperature IC Control Library Demo");
    // Start up the library
    sensors.begin();

    while (millis() < 5000)
    {
        Serial.print("millis() = ");
        Serial.println(millis());
        delay(500);
    }

    Serial.println(F("Starting"));

#ifdef VCC_ENABLE
    // For Pinoccio Scout boards
    pinMode(VCC_ENABLE, OUTPUT);
    digitalWrite(VCC_ENABLE, HIGH);
    delay(1000);
#endif

    // LMIC init
    os_init();
    // Reset the MAC state. Session and pending data transfers will be discarded.
    LMIC_reset();
    LMIC_setClockError(MAX_CLOCK_ERROR * 10 / 100);
    // Start job (sending automatically starts OTAA too)
    do_send(&sendjob);
}

void loop()
{
    if (digitalRead(PIR_MOTION_SENSOR)) //if it detects the moving people?
    {
        //Increment mvt-nbre durant TX_INTERVAL
        nbreMvt = nbreMvt + 1;
        digitalWrite(10, HIGH);
    }
    else
    {
        digitalWrite(10, LOW);
        //Serial.println("Watching");
    }

    os_runloop_once();
}
```