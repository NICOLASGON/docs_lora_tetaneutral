# ESP32

## Présentation

Il n'y a pas d'antenne mais il suffit d'un fil pour faire une "quarter wave whip antenna" en le coupant à la bonne longueur :

* 433 MHz - 16.5 cm
* 868 MHz - 8.2 cm (Europe)
* 915 MHz - 7.8 cm

Il est recommandé de brancher effectivement une antenne car, sans, cela peut à terme endommager de matériel (retour d'énergie).

## Modes ABP ou OTAA ?

### Over-the-Air Activation (OTAA)

Over-the-Air Activation (OTAA) est la façon attendue de se connecter à un réseau LoRaWAN. Le device procède à une procédure de +join+ durant laquelle une +DevAddr+ est fixée et où les clés de chiffrements (AES-128) sont négociées.

Afin d'établir la jonction au réseau et d'identifier l'objet, il est nécessaire de connaître plusieurs informations :

* *AppEUI* : C’est un identifiant unique d’application qui permet de regrouper les objets. Cette adresse, sur 64 bits, permet de classer les périphériques par application. Ce paramètre est modifiable.
* *DevEUI* : c’est un identifiant qui rend unique chaque objet, programmé en usine. Ce paramètre n’est théoriquement pas modifiable.
* *AppKey* : Il s’agit d’un secret partagé entre le périphérique et le réseau, utilisé pour dériver les clefs de session. Ce paramètre peut être modifié.

### Activation by Personalization (ABP)

En ABP, il n'y a pas de demande à rejoindre un réseau (pas de +join+). Toutes clés (+DevAddr+ et les clés de chiffrement sont directement écrites en dur dans le skecth du noeud.

En plus des informations AppEUI, DevEUI et AppKey, il faudra coder en dur les clés de chiffrement :

* *DevAddr* : une adresse logique en 32 bits pour identifier l’objet dans le réseau présente dans chaque frame.
* *NetSKey* (Network Session Key) : Clé de chiffrement AES-128 partagée entre l’objet et le serveur de l'opérateur.
* *AppSKey* (Application Session Key) : Clé de chiffrement AES-128 partagée entre l’objet et l'utilisateur (via l'application).

Nous choisirons ici le mode OTAA...

## En C : librairies nécessaires et câblage

### LMIC

LMIC est l'implémentation en C de la pile LoRaWAN : LoraMac In C.

Dans Croquis/Bibliothèques/Inclure un bibliothèque, ajouter LMIC. Choisir la version marquée `-1`.

!!! tip
    Dans le répertoire sketchbook/libraries/ d'Arduino, télécharger LMIC avec l'adaptation pour Arduino :

    ```
    git clone https://github.com/matthijskooijman/arduino-lmic.git
    ```

### Adafruit SAMD Boards

Dans Fichier/préférences, ajouter comme gestionnaire de cartes additionnelles l'adresse : [https://adafruit.github.io/arduino-board-index/package_adafruit_index.json](https://adafruit.github.io/arduino-board-index/package_adafruit_index.json)

Puis, Outils/Type de Cartes/gestionnaire de cartes, recherchez Feather et installer les librairies (Adafruit SAMD Boards).

Plus d'infos ici : [https://learn.adafruit.com/adafruit-feather-m0-radio-with-lora-radio-module/setup](https://learn.adafruit.com/adafruit-feather-m0-radio-with-lora-radio-module/setup)

### Cablage

Pour que le code exemple fonctionne, il faut ajouter une connexion physique entre deux broches. Pour le type de carte que nous avons (ESP32 de HelTec), la définition du pinmap est la suivante :

``` c
const lmic_pinmap lmic_pins = {
    .nss = 18,
    .rxtx = LMIC_UNUSED_PIN,
    .rst = 14,
    .dio = {26,33,32},//la pin dio0 est sur 26, dio1 sur 33, dio2 sur 32
};
```

Si vous utilisez un cablage différent, adaptez-bien le pinmap !

[Mettre photo avec cablage]

### Sketch d'exemple : Hello world !

Dans loraserver, si besoin, créer une nouvelle "application" et y créer un nouvel objet (device).

Choisir un Device EUI. Ici, nous avons pris :

 0000000000000000

Choix par défaut pour le device-profile.

Pour l'application key, mettre n'importe quel nombre sur 128 bits.

Un sketch d'exemple fonctionnel, tiré des exemples de la librairie [arduino-lmic](https://github.com/matthijskooijman/arduino-lmic), est :

```c

/*******************************************************************************
 * Copyright (c) 2015 Thomas Telkamp and Matthijs Kooijman
 * Modifié par NG et RB (IUT de Blagnac)
 * Modifié par yves (LinuxTarn)
 * Modifié par Brice (AlbiLab)
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

//oled display heltec
#define OLED

#include <lmic.h>
#include <hal/hal.h>
#include <SPI.h>



#if defined OLED
  #include <U8x8lib.h>
  U8X8_SSD1306_128X64_NONAME_SW_I2C u8x8(/* clock=*/ 15, /* data=*/ 4, /* reset=*/ 16);
  void dispOled(int x, int y, char *text, boolean cls=true)
  {
    if (cls)
      u8x8.clear();
    u8x8.drawString(x, y, text);
  }
#endif


#if defined(ARDUINO_SAMD_ZERO) && defined(SERIAL_PORT_USBVIRTUAL)
  // Required for Serial on Zero based boards
  #define Serial SERIAL_PORT_USBVIRTUAL
#endif
/******************************************************************************/
/* LoRaWAN                                                                    */
/******************************************************************************/

// This EUI must be in *little-endian format* (least-significant-byte first)
// Necessaire pour le protocole mais inutile pour l'implémentation dans loraserver
// On peut donc mettre de l'aléatoire ou :

static const u1_t APPEUI[8]={ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  };

// DEVEUI should also be in *little endian format*

static const u1_t DEVEUI[8]={ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

// This key should be in big endian format

static const u1_t APPKEY[16] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

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
    .nss = 18,
    .rxtx = LMIC_UNUSED_PIN,
    .rst = 14,
    .dio = {26,33,32},//io1 pin is connected to pin 6, io2 vers pin 11
};

/******************************************************************************/
/* payload                                                                    */
/******************************************************************************/

static uint8_t mydata[] = "loraData";

/******************************************************************************/
/* Automate LMIC                                                              */
/******************************************************************************/


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
            #if defined OLED
              dispOled(0, 0, "Joining..");
            #endif
            break;
        case EV_JOINED:
            Serial.println(F("EV_JOINED"));
            #if defined OLED
              dispOled(0, 0, "Joined :).");
            #endif
            // Disable link check validation (automatically enabled
            // during join, but not supported by TTN at this time).
            LMIC_setLinkCheckMode(1);
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
            #if defined OLED
              dispOled(0, 0, "TX Complete !");
            #endif
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

#if defined OLED
  u8x8.begin();
  u8x8.setFont(u8x8_font_chroma48medium8_r);
  dispOled(0, 0, "Starting");
  dispOled(0, 2, "ESP32 Lora",false);
#endif
  
 while (! Serial);
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

## En python : librairies nécessaires et câblage

TODO : vous savez faire ou avez des idées ? Aidez-nous ! :)

voir micropython.

## MQTT

On peut s'abonner au flux MQTT de tous les objets de l'application où il a été positionné :

 mosquitto_sub -h loraserver.tetaneutral.net -v -t "application/1/#"

ou uniquement au flux MQTT de l'objet en question :

 mosquitto_sub -h loraserver.tetaneutral.net -v -t application/1/device/0000000000000000/#

On devrait arriver à ce type de message (en OTAA) sur le flux MQTT :

  [mettre exemple de trame ?]
