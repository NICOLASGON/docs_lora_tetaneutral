# Connexion LoRaWAN avec LMIC

LMIC (pour LoRa MAC In C) est une bibliothèque en C permettant à un objet de se connecter à un réseau LoRaWAN. 

Ce tutoriel détaille comment programmer un objet dans l'environnement Arduino pour se connecter à un réseau LoRaWAN avec LMIC.

## Modes ABP ou OTAA ?

Il y a deux méthodes pour se connecter à un réseau LoRaWAN.

### Over-the-Air Activation (OTAA)

_Over-the-Air Activation_ (OTAA) est la façon attendue de se connecter à un réseau LoRaWAN. Le _device_ procède à une procédure de `join` durant laquelle une `DevAddr` est fixée et où les clés de chiffrement (`NetSKey` et `AppSKey`) sont négociées... _over the air_ justement. Un peu comme une navigation en HTTPS.

Afin d'établir la jonction au réseau et d'identifier l'objet, il est nécessaire de connaître plusieurs informations :

* `DevEUI` : c’est un identifiant qui rend unique chaque objet usuellement programmé en usine. Ce paramètre n’est théoriquement pas modifiable,
* `AppKey` : il s’agit d’un secret partagé entre le périphérique et le réseau, utilisé pour dériver les clefs de session. Ce paramètre peut être modifié.

### Activation by Personalization (ABP)

En _Activation by Personalization_ (ABP), il n'y a pas de demande à rejoindre un réseau (pas de procédure de `join`). Toutes les clés (`DevAddr` et les clés de chiffrement) sont directement écrites en dur dans le code source du noeud.

En plus des informations `AppEUI`, `DevEUI` et `AppKey`, il faudra coder en dur les clés de chiffrement :

* `DevAddr` (_Device Address_) : une adresse logique 32 bits pour identifier l’objet dans le réseau présente dans chaque trame,
* `NetSKey` (_Network Session Key_) : clé de chiffrement AES-128 partagée entre l’objet et le serveur de l'opérateur,
* `AppSKey` (_Application Session Key_) : clé de chiffrement AES-128 partagée entre l’objet et l'utilisateur (via l'application).

Nous choisirons ici le mode OTAA.

### ChirpStack

Nous utilisons <https://www.chirpstack.io/> comme serveur de réseau.

Sur ce serveur de réseaux, les gestionnaires ont créées des regroupements d'objets dans des applications regroupées elle même dans des organisations.

Les gestionnaires du serveur ont préalablement créés les objets dans la bonne application.

On a donc la structure : `organisation/application/objet`.

Une organisation peut être un bâtiment et une application peut regrouper toutes les mesure de température dans les diverses pièces. Une autre application peut être la mesure de la luminosité.

En fonction du `DEVEUI` fixé à l'objet, il va se classer automatiquement dans la bonne application.


!!! tip
    Dans chirpstack et dans la bonne application, on créée un nouveau _device_ avec les paramètres :

    * Device Name
    * Device Descritpion
    * Device EUI (en hexadécimal)
    * Device Profile (ici Devices-IUT par exemple)

    Dans un autre onglet, il sera demandé la Application Key_ qui s'appelle _APPKEY_ dans le code d'exemple de LMIC.

## Mise en œuvre de LMIC

LMIC est l'implémentation de la pile LoRaWAN en Langage C : _LoraMAC In C_. C'est un bibliothèque qu'il va falloir ajouter à votre chaîne de compilation.

### Installation de la librairie

- Depuis l'IDE Arduino, dans le menu _Croquis > Inclure une bibliothèque_, rechercher et ajouter `MCCI LoRaWAN LMIC Library`.

!!! tip

    Vous pouvez aussi récupérer les sources et les décompresser dans le répertoire `Arduino/libraries/` : <https://github.com/mcci-catena/arduino-lmic>

!!! tip
    Plus simplement, dns le répertoire sketchbook/libraries/ d'Arduino, télécharger `MCCI LoRaWAN LMIC Library` avec :

    ```
    git clone https://github.com/mcci-catena/arduino-lmic.git
    ```

 - Une fois la librairie installée, il faut spécifier quelle bande de fréquence nous utilisons ! En Europe, c'est 868Mhz. Éditer le fichier `arduino-lmic/project_config/lmic_project_config.h` qui est dans le répertoire `librairies` et modifiez comme suit :

``` h
// project-specific definitions
#define CFG_eu868 1
#define CFG_sx1276_radio 1
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

Pour le Yah! ce sera :

``` c
const lmic_pinmap lmic_pins = {
    .nss = 31,
    .rxtx = LMIC_UNUSED_PIN,
    .rst = 19,
    .dio = {7, 5, 26},
};
```


### Sketch d'exemple : Hello world !

Dans chirpStack, si besoin, créer une nouvelle _Application_ et y créer un nouvel objet (_device_).

Choisir un `Device EUI`. Ici, nous avons pris :

```
 1a81070000000201
```

Choix par défaut pour le device-profile.

Un sketch d'exemple fonctionnel, tiré des exemples de la librairie [arduino-lmic](https://github.com/mcci-catena/arduino-lmic), est :

``` c
/*******************************************************************************
 * Copyright (c) 2015 Thomas Telkamp and Matthijs Kooijman
 * Copyright (c) 2018 Terry Moore, MCCI
 *
 * Permission is hereby granted, free of charge, to anyone
 * obtaining a copy of this document and accompanying files,
 * to do whatever they want with them without any restriction,
 * including, but not limited to, copying, modification and redistribution.
 * NO WARRANTY OF ANY KIND IS PROVIDED.
 *
 * This example sends a valid LoRaWAN packet with payload "Hello,
 * world!", using frequency and encryption settings matching those of
 * the The Things Network.
 *
 * This uses OTAA (Over-the-air activation), where where a DevEUI and
 * application key is configured, which are used in an over-the-air
 * activation procedure where a DevAddr and session keys are
 * assigned/generated for use with all further communication.
 *
 * Note: LoRaWAN per sub-band duty-cycle limitation is enforced (1% in
 * g1, 0.1% in g2), but not the TTN fair usage policy (which is probably
 * violated by this sketch when left running for longer)!

 * To use this sketch, first register your application and device with
 * the things network, to set or generate an AppEUI, DevEUI and AppKey.
 * Multiple devices can use the same AppEUI, but each device has its own
 * DevEUI and AppKey.
 *
 * Do not forget to define the radio type correctly in
 * arduino-lmic/project_config/lmic_project_config.h or from your BOARDS.txt.
 *
 *******************************************************************************/

#include <lmic.h>
#include <hal/hal.h>
#include <SPI.h>

//
// For normal use, we require that you edit the sketch to replace FILLMEIN
// with values assigned by the TTN console. However, for regression tests,
// we want to be able to compile these scripts. The regression tests define
// COMPILE_REGRESSION_TEST, and in that case we define FILLMEIN to a non-
// working but innocuous value.
//

// This EUI must be in little-endian format, so least-significant-byte
// first. When copying an EUI from ttnctl output, this means to reverse
// the bytes. For TTN issued EUIs the last bytes should be 0xD5, 0xB3,
// 0x70.

static const u1_t PROGMEM APPEUI[8]={ 0 };
void os_getArtEui (u1_t* buf) { memcpy_P(buf, APPEUI, 8);}

// This should also be in little endian format, see above.
static const u1_t PROGMEM DEVEUI[8]={  0x01, 0x02, 0x00, 0x00, 0x00, 0x07, 0x81, 0x1a  };
void os_getDevEui (u1_t* buf) { memcpy_P(buf, DEVEUI, 8);}

// This key should be in big endian format (or, since it is not really a
// number but a block of memory, endianness does not really apply). 
static const u1_t PROGMEM APPKEY[16] = { 0xXX, ..... À DEMANDER AUX ADMINS DU SERVEUR........, 0x0XX };
void os_getDevKey (u1_t* buf) {  memcpy_P(buf, APPKEY, 16);}

static uint8_t mydata[] = "RB";
static osjob_t sendjob;

// Schedule TX every this many seconds (might become longer due to duty
// cycle limitations).
const unsigned TX_INTERVAL = 60;

// Pin mapping
const lmic_pinmap lmic_pins = {
    .nss = 31,
    .rxtx = LMIC_UNUSED_PIN,
    .rst = 19,
    .dio = {7, 5, 26},
};

void printHex2(unsigned v) {
    v &= 0xff;
    if (v < 16)
        SerialUSB.print('0');
    SerialUSB.print(v, HEX);
}

void onEvent (ev_t ev) {
    SerialUSB.print(os_getTime());
    SerialUSB.print(": ");
    switch(ev) {
        case EV_SCAN_TIMEOUT:
            SerialUSB.println(F("EV_SCAN_TIMEOUT"));
            break;
        case EV_BEACON_FOUND:
            SerialUSB.println(F("EV_BEACON_FOUND"));
            break;
        case EV_BEACON_MISSED:
            SerialUSB.println(F("EV_BEACON_MISSED"));
            break;
        case EV_BEACON_TRACKED:
            SerialUSB.println(F("EV_BEACON_TRACKED"));
            break;
        case EV_JOINING:
            SerialUSB.println(F("EV_JOINING"));
            break;
        case EV_JOINED:
            SerialUSB.println(F("EV_JOINED"));
            {
              u4_t netid = 0;
              devaddr_t devaddr = 0;
              u1_t nwkKey[16];
              u1_t artKey[16];
              LMIC_getSessionKeys(&netid, &devaddr, nwkKey, artKey);
              SerialUSB.print("netid: ");
              SerialUSB.println(netid, DEC);
              SerialUSB.print("devaddr: ");
              SerialUSB.println(devaddr, HEX);
              SerialUSB.print("AppSKey: ");
              for (size_t i=0; i<sizeof(artKey); ++i) {
                if (i != 0)
                  SerialUSB.print("-");
                printHex2(artKey[i]);
              }
              SerialUSB.println("");
              SerialUSB.print("NwkSKey: ");
              for (size_t i=0; i<sizeof(nwkKey); ++i) {
                      if (i != 0)
                              SerialUSB.print("-");
                      printHex2(nwkKey[i]);
              }
              SerialUSB.println();
            }
            // Disable link check validation (automatically enabled
            // during join, but because slow data rates change max TX
	    // size, we don't use it in this example.
            LMIC_setLinkCheckMode(0);
            break;
        /*
        || This event is defined but not used in the code. No
        || point in wasting codespace on it.
        ||
        || case EV_RFU1:
        ||     SerialUSB.println(F("EV_RFU1"));
        ||     break;
        */
        case EV_JOIN_FAILED:
            SerialUSB.println(F("EV_JOIN_FAILED"));
            break;
        case EV_REJOIN_FAILED:
            SerialUSB.println(F("EV_REJOIN_FAILED"));
            break;
        case EV_TXCOMPLETE:
            SerialUSB.println(F("EV_TXCOMPLETE (includes waiting for RX windows)"));
            if (LMIC.txrxFlags & TXRX_ACK)
              SerialUSB.println(F("Received ack"));
            if (LMIC.dataLen) {
              SerialUSB.print(F("Received "));
              SerialUSB.print(LMIC.dataLen);
              SerialUSB.println(F(" bytes of payload"));
            }
            // Schedule next transmission
            os_setTimedCallback(&sendjob, os_getTime()+sec2osticks(TX_INTERVAL), do_send);
            break;
        case EV_LOST_TSYNC:
            SerialUSB.println(F("EV_LOST_TSYNC"));
            break;
        case EV_RESET:
            SerialUSB.println(F("EV_RESET"));
            break;
        case EV_RXCOMPLETE:
            // data received in ping slot
            SerialUSB.println(F("EV_RXCOMPLETE"));
            break;
        case EV_LINK_DEAD:
            SerialUSB.println(F("EV_LINK_DEAD"));
            break;
        case EV_LINK_ALIVE:
            SerialUSB.println(F("EV_LINK_ALIVE"));
            break;
        /*
        || This event is defined but not used in the code. No
        || point in wasting codespace on it.
        ||
        || case EV_SCAN_FOUND:
        ||    SerialUSB.println(F("EV_SCAN_FOUND"));
        ||    break;
        */
        case EV_TXSTART:
            SerialUSB.println(F("EV_TXSTART"));
            break;
        case EV_TXCANCELED:
            SerialUSB.println(F("EV_TXCANCELED"));
            break;
        case EV_RXSTART:
            /* do not print anything -- it wrecks timing */
            break;
        case EV_JOIN_TXCOMPLETE:
            SerialUSB.println(F("EV_JOIN_TXCOMPLETE: no JoinAccept"));
            break;

        default:
            SerialUSB.print(F("Unknown event: "));
            SerialUSB.println((unsigned) ev);
            break;
    }
}

void do_send(osjob_t* j){
    // Check if there is not a current TX/RX job running
    if (LMIC.opmode & OP_TXRXPEND) {
        SerialUSB.println(F("OP_TXRXPEND, not sending"));
    } else {
        // Prepare upstream data transmission at the next possible time.
        LMIC_setTxData2(1, mydata, sizeof(mydata)-1, 0);
        SerialUSB.println(F("Packet queued"));
    }
    // Next TX is scheduled after TX_COMPLETE event.
}

void setup() {
    Serial.begin(9600);
    SerialUSB.println(F("Starting"));

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

    // Start job (sending automatically starts OTAA too)
    do_send(&sendjob);
}

void loop() {
    os_runloop_once();
}

```

## MQTT

On peut s'abonner au flux MQTT de tous les objets de l'application où il a été positionné :

```
 mosquitto_sub -h loraserver.tetaneutral.net -v -t "application/#"
```

en affinant la commande, on devrait arriver à ce type de message sur le flux MQTT :

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