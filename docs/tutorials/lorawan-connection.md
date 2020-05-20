# Connexion LoRaWAN avec LMIC

La pile LMIC permet à un objet de se connecter à un réseau LoRaWAN. Ce tutoriel détaille comment programmer un objet dans l'environnement Arduino pour se connecter à un réseau LoRaWAN avec la pile LMIC.

## Modes ABP ou OTAA ?

### Over-the-Air Activation (OTAA)

_Over-the-Air Activation_ (OTAA) est la façon attendue de se connecter à un réseau LoRaWAN. Le _device_ procède à une procédure de `join` durant laquelle une `DevAddr` est fixée et où les clés de chiffrement (AES-128) sont négociées.

Afin d'établir la jonction au réseau et d'identifier l'objet, il est nécessaire de connaître plusieurs informations :

* `AppEUI` : c’est un identifiant unique d’application qui permet de regrouper les objets. Cette adresse, sur 64 bits, permet de classer les périphériques par application. Ce paramètre est modifiable,
* `DevEUI` : c’est un identifiant qui rend unique chaque objet usuellement programmé en usine. Ce paramètre n’est théoriquement pas modifiable,
* `AppKey` : il s’agit d’un secret partagé entre le périphérique et le réseau, utilisé pour dériver les clefs de session. Ce paramètre peut être modifié.

### Activation by Personalization (ABP)

En _Activation by Personalization_ (ABP), il n'y a pas de demande à rejoindre un réseau (pas de `join`). Toutes les clés (`DevAddr` et les clés de chiffrement) sont directement écrites en dur dans le code source du noeud.

En plus des informations `AppEUI`, `DevEUI` et `AppKey`, il faudra coder en dur les clés de chiffrement :

* `DevAddr` (_Device Address_) : une adresse logique 32 bits pour identifier l’objet dans le réseau présente dans chaque trame,
* `NetSKey` (_Network Session Key_) : clé de chiffrement AES-128 partagée entre l’objet et le serveur de l'opérateur,
* `AppSKey` (_Application Session Key_) : clé de chiffrement AES-128 partagée entre l’objet et l'utilisateur (via l'application).

Nous choisirons ici le mode OTAA.

### Loraserver

Sur les serveurs de réseaux, les gestionnaires ont créées des regroupements d'objets dans des applications regroupées elle même dans des organisations.

On a donc la structure : organisation/application/objet.

Une organisation peut être un bâtiment et une application peut regrouper toutes les mesure de température dans les diverses pièces. Une autre application peut être la mesure de la luminosité.

En fonction du `DEVEUI` fixé à l'objet, il va se classer automatiquement dans la bonne application.

Préalablement, les gestionnaires du serveur ont créé cet objet dans la bonne application.

!!! tip
    Dans loraserver et dans la bonne application, on créée un nouveau _device_ avec les paramètres :

    * Device Name
    * Device Descritpion
    * Device EUI (en hexadécimal)
    * Device Profile (ici Devices-IUT par exemple)

    Dans un écran suivant, il sera demandé la _Network Key_ qui s'appelle _APPKEY_ dans le code d'exemple de LMIC...

## Mise en œuvre de LMIC

LMIC est l'implémentation de la pile LoRaWAN en Langage C : _LoraMAC In C_.

### Installation de la librairie

- Depuis l'IDE Arduino, dans le menu _Croquis > Inclure une bibliothèque_, rechercher et ajouter LMIC. Début février 2019, la version-2 ne fonctionne pas ; choisir la version marquée `-1`.

!!! tip
    Dans le répertoire sketchbook/libraries/ d'Arduino, télécharger LMIC avec l'adaptation pour Arduino :

    ```
    git clone https://github.com/matthijskooijman/arduino-lmic.git
    ```

### Lien avec le matériel

En fonction du matériel utilisé (Yah!, FeatherM0, ESP32...), des câblages particuliers peuvent être nécessaires. Se référer aux tutoriels correspondants sur ce site.

Il faut systématiquement ajuster la `pinmap` pour indiquer à LMIC quelles sont les GPIO à utiliser pour se connecter à la radio LoRa. Par exemple, pour le FeatherM0 :

``` c
const lmic_pinmap lmic_pins = {
    .nss = 8,
    .rxtx = LMIC_UNUSED_PIN,
    .rst = LMIC_UNUSED_PIN,
    .dio = {3, 6, LMIC_UNUSED_PIN},
};
```

!!! note ""
    The LMIC library needs only access to DIO0, DIO1 and DIO2, the other DIOx pins can be left disconnected.

    On the Arduino side, they can connect to any I/O pin, since the current implementation does not use interrupts or other special hardware features (though this might be added in the feature, see also the "Timing" section).

    In LoRa mode the DIO pins are used as follows:

        DIO0: TxDone and RxDone
        DIO1: RxTimeout

    The names refer to the pins on the transceiver side, the numbers refer to the Arduino pin numbers (to use the analog pins, use constants like A0). For the DIO pins, the three numbers refer to DIO0, DIO1 and DIO2 respectively.

    Any pins that are not needed should be specified as LMIC_UNUSED_PIN. The nss and dio0 pin is required, the others can potentially left out (depending on the environments and requirements.

### Sketch d'exemple : Hello world !

Dans loraserver, si besoin, créer une nouvelle _Application_ et y créer un nouvel objet (_device_).

Choisir un `Device EUI`. Ici, nous avons pris :

```
 010203040506070b
```

Choix par défaut pour le device-profile.

Pour l'application key, mettre n'importe quel nombre sur 128 bits.

Un sketch d'exemple fonctionnel, tiré des exemples de la librairie [arduino-lmic](https://github.com/matthijskooijman/arduino-lmic), est :

``` c
/*******************************************************************************
 * Copyright (c) 2015 Thomas Telkamp and Matthijs Kooijman
 * https://github.com/matthijskooijman/arduino-lmic/blob/master/examples/ttn-otaa/ttn-otaa.ino
 * Modifié par NG et RB (IUT de Blagnac)
 *
 * This uses OTAA (Over-the-air activation), where where a DevEUI and
 * application key is configured, which are used in an over-the-air
 * activation procedure where a DevAddr and session keys are
 * assigned/generated for use with all further communication.
 * 
 * To use this sketch, first register your application and device with
 * the tloraserver, to set or generate an AppEUI, DevEUI and AppKey.
 * Multiple devices can use the same AppEUI, but each device has its own
 * DevEUI and AppKey.
 *
 * Do not forget to define the radio type correctly in config.h.
 *
 *******************************************************************************/

#include <lmic.h>
#include <hal/hal.h>
#include <SPI.h>

/******************************************************************************/
/* LoRaWAN                                                                    */
/******************************************************************************/

// This EUI must be in *little-endian format* (least-significant-byte first)
// Necessaire pour le protocole mais inutile pour l'implémentation dans loraserver
// On peut donc mettre de l'aléatoire ou :

static const u1_t APPEUI[8]={ 0xF5, 0xD4, 0x54, 0x4B, 0x1C, 0xAB, 0x54, 0x1C };
 
// DEVEUI should also be in *LITTLE endian format*
 
//1a81070000000201 soit le YahIUT0201
 
static const u1_t DEVEUI[8]={ 0x01, 0x02, 0x00, 0x00, 0x00, 0x07, 0x81, 0x1a };
 
// This key should be in BIG endian format
// 00 00 00 00 00 00 00 00 1a 81 07 00 00 00 02 00
 
static const u1_t APPKEY[16] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1a, 0x81, 0x07, 0x00, 0x00, 0x00, 0x02, 0x00 };

// Copie en mémoire des EUI et APPKEY
void os_getArtEui (u1_t* buf) { memcpy_P(buf, APPEUI, 8);}
void os_getDevEui (u1_t* buf) { memcpy_P(buf, DEVEUI, 8);}
void os_getDevKey (u1_t* buf) { memcpy_P(buf, APPKEY, 16);}

// Schedule TX every this many seconds (might become longer due to duty
// cycle limitations).
const unsigned TX_INTERVAL = 60;

/******************************************************************************/
/* pin mapping                                                                */
/******************************************************************************/

const lmic_pinmap lmic_pins = {
    .nss = 8,
    .rxtx = LMIC_UNUSED_PIN,
    .rst = LMIC_UNUSED_PIN,
    .dio = {3, 6, LMIC_UNUSED_PIN},//io1 pin is connected to pin 6, io2 vers pin 11
};

/******************************************************************************/
/* payload                                                                    */
/******************************************************************************/

static uint8_t mydata[] = "RB";

/******************************************************************************/
/* Automate LMIC                                                              */
/******************************************************************************/

// return the current session keys returned from join.
void LMIC_getSessionKeys (u4_t *netid, devaddr_t *devaddr, xref2u1_t nwkKey, xref2u1_t artKey) {
    *netid = LMIC.netid;
    *devaddr = LMIC.devaddr;
    memcpy(artKey, LMIC.artKey, sizeof(LMIC.artKey));
    memcpy(nwkKey, LMIC.nwkKey, sizeof(LMIC.nwkKey));
}
static osjob_t sendjob;

void onEvent (ev_t ev) {
    Serial.print(os_getTime());
    Serial.print(": ");
    switch(ev) {
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
            {
              u4_t netid = 0;
              devaddr_t devaddr = 0;
              u1_t nwkKey[16];
              u1_t artKey[16];
              LMIC_getSessionKeys(&netid, &devaddr, nwkKey, artKey);
              Serial.print("netid: ");
              Serial.println(netid, DEC);
              Serial.print("devaddr: ");
              Serial.println(devaddr, HEX);
              Serial.print("artKey: ");
              for (int i=0; i<sizeof(artKey); ++i) {
                if (i != 0)
                  Serial.print("-");
                Serial.print(artKey[i], HEX);
              }
              Serial.println("");
              Serial.print("nwkKey: ");
              for (int i=0; i<sizeof(nwkKey); ++i) {
                      if (i != 0)
                              Serial.print("-");
                      Serial.print(nwkKey[i], HEX);
              }
              Serial.println("");
}

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
            if (LMIC.dataLen) {
              Serial.println(F("Received "));
              Serial.println(LMIC.dataLen);
              Serial.println(F(" bytes of payload"));
            }
            // Schedule next transmission
            os_setTimedCallback(&sendjob, os_getTime()+sec2osticks(TX_INTERVAL), do_send);
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

// send fonction

void do_send(osjob_t* j){
    // Check if there is not a current TX/RX job running
    if (LMIC.opmode & OP_TXRXPEND) {
        Serial.println(F("OP_TXRXPEND, not sending"));
    } else {
        // Prepare upstream data transmission at the next possible time.
        LMIC_setTxData2(1, mydata, sizeof(mydata)-1, 0);
        Serial.println(F("Packet queued"));
    }
    // Next TX is scheduled after TX_COMPLETE event.
}

void setup() {
    Serial.begin(9600);
    while (millis() < 5000) {
    Serial.print("millis() = "); Serial.println(millis());
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

void loop() {
    os_runloop_once();
}
```

## MQTT

L'execution du packet forwarder renvoie :

```
  INFO: Received pkt from mote: 060C375D (fcnt=3)

  JSON up: {"rxpk":[{"tmst":222809339,"chan":0,"rfch":1,"freq":868.100000,"stat":1,"modu":"LORA","datr":"SF7BW125","codr":"4/5","lsnr":9.5,"rssi":-103,"size":17,"data":"QF03DAbCAwADBwFpriQsnJg="}]}
  INFO: [up] PUSH_ACK received in 32 ms
  INFO: [down] PULL_RESP received  - token[53:35] :)

  JSON down: {"txpk":{"imme":false,"tmst":223809339,"freq":868.1,"rfch":0,"powe":14,"modu":"LORA","datr":"SF7BW125","codr":"4/5","ipol":true,"size":17,"data":"YF03DAaFAwADVwcAAZCWkmo=","brd":0,"ant":0}}
  INFO: [down] PULL_ACK received in 30 ms
```

On peut s'abonner au flux MQTT de tous les objets de l'application où il a été positionné :

```
 mosquitto_sub -h loraserver.tetaneutral.net -v -t "application/1/#"
```

ou uniquement au flux MQTT de l'objet en question :

```
 mosquitto_sub -h loraserver.tetaneutral.net -v -t application/1/node/010203040506070b/#
```

On devrait arriver à ce type de message (en OTAA) sur le flux MQTT :

```
 application/1/node/010203040506070b/rx {"applicationID":"1","applicationName":"snootlab-testing","deviceName":"Feather-M0-RB-home","devEUI":"010203040506070b","txInfo":{"frequency":868300000,"dataRate":{"modulation":"LORA","bandwidth":125,"spreadFactor":7},"adr":true,"codeRate":"4/5"},"fCnt":10,"fPort":1,"data":"UkI="}
```

Comme on peut le voir sur le sketch, le message transmis était "RB". On a reçu "UkI=" qui est l'écriture en base64 déchiffrée de notre message. La commande suivante renvoie bien RB.

```
  echo "UkI=" | base64 -d
```

Voir les documents suivants pour des exemples d'application !

## Divers

### API loraserver

[https://loraserver.tetaneutral.net/api](https://loraserver.tetaneutral.net/api)

Aller dans /api/internal/login
saisir username/password=admin/XXXXXX (loraserver)
Try it out !

Récupérer un token à copier/coller dans le champ JWT token en haut à droite (sans appuyer sur Entrée !)

Jouer avec l'API...

## Problèmes

* Start from the origin (the packet-forwarder & LoRa Gateway Bridge): [https://docs.loraserver.io/lora-gateway-bridge/install/debug/](https://docs.loraserver.io/lora-gateway-bridge/install/debug/) when you see data there, one step up to LoRa Server and see what happens there in the logs.

* OTAA ?

* SerialPortException: Port name - /dev/ttyACM0; Method name - openPort(); Exception type - Permission denied.

    ```
    sudo usermod -a -G dialout $USER (puis logout/login)
    ```

* cdc_acm 1-1:1.0: failed to set dtr/rts. Voir [https://bugs.launchpad.net/ubuntu/+source/modemmanager/+bug/1473246](https://bugs.launchpad.net/ubuntu/+source/modemmanager/+bug/1473246)

    ```
    sudo systemctl mask ModemManager.service
    reboot
    ```

    ou :

    ```
    sudo apt-get purge modemmanager
    ```

## Références

[https://wolfgangklenk.wordpress.com/2017/04/15/adafruit-feather-as-lorawan-node/](https://wolfgangklenk.wordpress.com/2017/04/15/adafruit-feather-as-lorawan-node/)

[http://www.linuxembedded.fr/2017/12/introduction-a-lora/](http://www.linuxembedded.fr/2017/12/introduction-a-lora/)

[https://thingspeak.com/pages/learn_more](https://thingspeak.com/pages/learn_more)
