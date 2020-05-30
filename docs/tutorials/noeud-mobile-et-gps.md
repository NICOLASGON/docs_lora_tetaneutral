# Nœud mobile et GPS

Dans cet article, nous allons voir comment mettre en place un nœud mobile qui, à l'aide d'un module récepteur GPS, pourra envoyer régulièrement sa position au réseau. Côté application, la position de l'objet mobile sera représentée en temps réel sur une carte.

L'article est découpé en plusieurs parties : d'abord le côté nœud embarqué, puis ensuite le côté infrastructure/serveur.

## Nœud embarqué

Dans cette partie, nous allons réaliser pas-à-pas le nœud mobile : partie matérielle puis logicielle.

### Partie matérielle

Nous partons d'un nœud Arduino compatible LoRaWAN tel qu'un Feather ou un Yah!. Nous ajoutons à ce nœud un module récepteur GPS, qui va permettre de connaître à tout instant la position du nœud mobile. A priori, n'importe quel module récepteur GPS fera l'affaire ; il suffit que celui-ci soit dôté d'une interface UART en 0-3V pour être connecté sur l'un des ports série de l'Arduino (un récepteur GPS USB ne convient pas).

Une photo du prototype réalisé est visible ci-après. Celui-ci est réalisé à partir :

  - d'un Arduino Yah! en version béta (bientôt disponible chez https://snootlab.com[Snootlab.com])
  - d'un récepteur GPS https://snootlab.com/lang-en/sparkfun/1048-gp-20u7-gps-receiver-56-channel-en.html[Sparkfun GP-20U7].

Ajouter ici une photo du prototype

Un récepteur GPS envoie régulièrement des informations en suivant le protocole [NMEA](https://fr.wikipedia.org/wiki/NMEA_0183). Les messages NMEA sont générés par le récepteur GPS et envoyés sur sa liaison série via sa sortie `TX`. Matériellement, il suffit donc de connecter la sortie `TX` du GPS à l'entrée `RX` de l'Arduino comme indiqué sur le schéma ci-après. Comme le récepteur GPS ne recevra pas de consigne venant de l'Arduino, il n'est pas nécessaire de câbler le `TX` de l'Arduino au `RX` du GPS. D'ailleurs, certains récepteurs GPS ne sont même pas dôtés d'une entrée `RX` (c'est le cas de celui utilisé ici).

Ajouter ici le schéma de câblage.

### Partie logicielle

Nous partons de l'exemple de sketch Arduino LoRaWAN utilisé jusqu'ici dans les autres articles. Nous y ajoutons la librairie `TinyGPS` permettant d'interpréter les messages NMEA venant du récepteur GPS.

!!! tip "Petit détour : prise en main du récepteur GPS avec la librairie Arduino TinyGPS"
    L'exemple `simple_test` de la librairie Arduino `TinyGPS` peut être mis en œuvre rapidement pour bien comprendre l'interaction entre le GPS et l'Arduino via le protocole NMEA.

    L'Arduino utilisé ici (Yah! ou Feather) disposant de plusieurs ports série matériels, il n'est pas nécessaire d'utiliser la librairie `SoftwareSerial` comme dans l'exemple d'origine. On pourra utiliser la version ci-dessous.

``` c
#include <TinyGPS.h>
TinyGPS gps;

void setup()
{
  SerialUSB.begin(115200); // Console is on SerialUSB
  Serial1.begin(9600); // GPS is on Serial1
}

void loop()
{
  bool newData = false;

  while (Serial1.available())
  {
    // Feed TinyGPS with NMEA messages
    char c = Serial1.read();
    //SerialUSB.write(c); // uncomment this line if you want to see the GPS data flowing
    if (gps.encode(c)) newData = true; // Set newData flag if a new GPS data is available
  }

  if (newData)
  {
    // If a new GPS data is available, print latitude, longitude, number of satellites and HDOP
    float flat, flon;
    unsigned long age;
    gps.f_get_position(&flat, &flon, &age);
    SerialUSB.print("LAT=");
    SerialUSB.print(flat == TinyGPS::GPS_INVALID_F_ANGLE ? 0.0 : flat, 6);
    SerialUSB.print(" LON=");
    SerialUSB.print(flon == TinyGPS::GPS_INVALID_F_ANGLE ? 0.0 : flon, 6);
    SerialUSB.print(" SAT=");
    SerialUSB.print(gps.satellites() == TinyGPS::GPS_INVALID_SATELLITES ? 0 : gps.satellites());
    SerialUSB.print(" PREC=");
    SerialUSB.print(gps.hdop() == TinyGPS::GPS_INVALID_HDOP ? 0 : gps.hdop());
    newData = false;
  }
}
```

Le récepteur GPS peut mettre plusieurs dizaines de secondes à _fixer_, c'est à dire être capable de calculer et renvoyer des coordonnées. Il vaut mieux placer le récepteur GPS à l'extérieur ou près d'une fenêtre pour accélérer le fix.

Pour voir les messages NMEA, il suffit de décommenter la ligne

``` c
  //SerialUSB.write(c); // uncomment this line if you want to see the GPS data flowing
```

Une fois le câblage réalisé et le récepteur testé et validé, on peut intégrer la position GPS aux messages envoyés sur le réseau LoRaWAN.

Le sketch d'exemple présenté dans les autres articles est utilisé comme base. On y ajoute :

* la déclaration de l'objet GPS de TinyGPS et une position par défaut (Place du Capitole à Toulouse)

``` c
#include <TinyGPS.h>

#define DEFAULT_LAT 43.604381
#define DEFAULT_LON 1.443366

TinyGPS gps;
float flat = DEFAULT_LAT;
float flon = DEFAULT_LON;
unsigned long age;
```

* les pins du Yah! : bouton poussoir et LED RGB

``` c
#define LED_RED   8
#define LED_GREEN 6
#define LED_BLUE  9
#define BUTTON_PIN 38
```

* le délai de 30 secondes pour l'envoi de la position GPS sur le réseau LoRaWAN

``` c
const unsigned TX_INTERVAL = 30;
```

* en fonction du nœud utilisé (Feather ou Yah!) la mise à jour des numéros de pins pour LMIC. Pour la version beta du Yah! utilisée ici, ça donne :

``` c
// Yah! "Yet Another Hardware for !oT"
const lmic_pinmap lmic_pins = {
    .nss = 7,
    .rxtx = LMIC_UNUSED_PIN,
    .rst = 19,
    .dio = {31, 27, 26},
};
```

* dans la fonction `do_send`, nous convertissons les latitudes et longitudes codées en `float` en chaîne de caractères que nous utilisons ensuite pour formater le message envoyé à l'aide de la fonction `sprintf`. Le message est une chaîne de caractères contenant une structure JSON telle que `{ "sqn": 480, "lat": 43.604381, "lon": 1.443366 }`, qui sera très simple à interpréter avec Node-RED. On notera également que les messages sont numérotés (`sqn`), ce qui permettra de détecter d'enventuels messages manquants.

``` c
void do_send(osjob_t* j)
{
    static uint32_t sqn = 0;
    String flat_s;
    String flon_s;
    flat_s = String(flat,7);
    flon_s = String(flon,7);

    if (LMIC.opmode & OP_TXRXPEND)
    {
        SerialUSB.println("OP_TXRXPEND, not sending");
    }
    else
    {
        digitalWrite(LED_BLUE, LOW);
        sprintf((char*)mydata,"{\"sqn\":%d,\"lat\":%s,\"lon\":%s}", sqn, flat_s.c_str(), flon_s.c_str() );
        SerialUSB.print("I will send: ");
        SerialUSB.println((char*)mydata);
        LMIC_setTxData2(1, mydata, strlen((char*)mydata), 1);
        sqn++;
    }
}
```

Finalement, le sketch entier est donné ci-dessous.

``` c
#include <lmic.h>
#include <hal/hal.h>
#include <SPI.h>
#include <Wire.h>
#include <TinyGPS.h>

#define DEFAULT_LAT 43.604381
#define DEFAULT_LON 1.443366

TinyGPS gps;
float flat = DEFAULT_LAT;
float flon = DEFAULT_LON;
unsigned long age;

#define LED_RED   8
#define LED_GREEN 6
#define LED_BLUE  9
#define BUTTON_PIN 38

// keys for iot.tetaneutral.net
// static const u1_t PROGMEM M_DEVEUI[8] = { 0x80, 0x56, 0x68, 0x9c, 0xb4, 0x2b, 0x78, 0x8a };
// static const u1_t PROGMEM M_APPEUI[8] = { 0x79, 0xc4, 0xe2, 0xcc, 0xc5, 0xf3, 0xe2, 0xe9 };
// static const u1_t PROGMEM M_APPKEY[16] = { 0xa4, 0x6a, 0x07, 0xe9, 0xb0, 0x28, 0xb4, 0x8c, 0x63, 0xe0, 0x4c, 0xf4, 0xa8, 0x72, 0x51, 0x4a};

// keys for loraserver.tetaneutral.net
static const u1_t PROGMEM M_APPEUI[8] =  { 0xF5, 0xD4, 0x54, 0x4B, 0x1C, 0xAB, 0x54, 0x1C };
static const u1_t PROGMEM M_DEVEUI[8] =  { 0x4a, 0x89, 0xbc, 0x77, 0x05, 0xe2, 0x1c, 0x67 };
static const u1_t PROGMEM M_APPKEY[16] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

void os_getArtEui (u1_t* buf)
{
    memcpy_P(buf, M_APPEUI, 8);
}

void os_getDevEui (u1_t* buf)
{
    memcpy_P(buf, M_DEVEUI, 8);
}

void os_getDevKey (u1_t* buf)
{
    memcpy_P(buf, M_APPKEY, 16);    
}

static uint8_t mydata[20];
static osjob_t sendjob;

const unsigned TX_INTERVAL = 30;

// Yah! "Yet Another Hardware for !oT"
const lmic_pinmap lmic_pins = {
    .nss = 7,
    .rxtx = LMIC_UNUSED_PIN,
    .rst = 19,
    .dio = {31, 27, 26},
};

// Adafruit Feather
/*
const lmic_pinmap lmic_pins = {
        .nss = 8,
        .rxtx = LMIC_UNUSED_PIN,
        .rst = 4,
        .dio = {3, 6, LMIC_UNUSED_PIN},
};*/

void onEvent (ev_t ev)
{
    SerialUSB.print(os_getTime());
    SerialUSB.print(": ");
    switch(ev) {
        case EV_SCAN_TIMEOUT:
            SerialUSB.println("EV_SCAN_TIMEOUT");
            break;
        case EV_BEACON_FOUND:
            SerialUSB.println("EV_BEACON_FOUND");
            break;
        case EV_BEACON_MISSED:
            SerialUSB.println("EV_BEACON_MISSED");
            break;
        case EV_BEACON_TRACKED:
            SerialUSB.println("EV_BEACON_TRACKED");
            break;
        case EV_JOINING:
            digitalWrite(LED_RED, LOW);
            SerialUSB.println("EV_JOINING");
            break;
        case EV_JOINED:
            digitalWrite(LED_RED, HIGH);
            SerialUSB.println("EV_JOINED");
            LMIC_setLinkCheckMode(0);
            os_setTimedCallback(&sendjob, os_getTime()+sec2osticks(TX_INTERVAL), do_send);
            break;
        case EV_RFU1:
            SerialUSB.println("EV_RFU1");
            break;
        case EV_JOIN_FAILED:
            SerialUSB.println("EV_JOIN_FAILED");
            break;
        case EV_REJOIN_FAILED:
            SerialUSB.println("EV_REJOIN_FAILED");
            break;
            break;
        case EV_TXCOMPLETE:
            digitalWrite(LED_BLUE, HIGH);
            SerialUSB.println("EV_TXCOMPLETE (includes waiting for RX windows)");
            if (LMIC.txrxFlags & TXRX_ACK)
                SerialUSB.println("Received ack");
            if (LMIC.dataLen) {
                SerialUSB.print("Received ");
                SerialUSB.print(LMIC.dataLen);
                SerialUSB.println(" bytes of payload");
            }
            os_setTimedCallback(&sendjob, os_getTime()+sec2osticks(TX_INTERVAL), do_send);
            break;
        case EV_LOST_TSYNC:
            SerialUSB.println("EV_LOST_TSYNC");
            break;
        case EV_RESET:
            SerialUSB.println("EV_RESET");
            break;
        case EV_RXCOMPLETE:
            // data received in ping slot
            SerialUSB.println("EV_RXCOMPLETE");
            break;
        case EV_LINK_DEAD:
            SerialUSB.println("EV_LINK_DEAD");
            break;
        case EV_LINK_ALIVE:
            SerialUSB.println("EV_LINK_ALIVE");
            break;
         default:
            SerialUSB.println("Unknown event");
            break;
    }
}

void do_send(osjob_t* j)
{
    static uint32_t sqn = 0;
    String flat_s;
    String flon_s;
    flat_s = String(flat,7);
    flon_s = String(flon,7);
    
    if (LMIC.opmode & OP_TXRXPEND)
    {
        SerialUSB.println("OP_TXRXPEND, not sending");
    }
    else
    {
        digitalWrite(LED_BLUE, LOW);
        sprintf((char*)mydata,"{\"sqn\":%d,\"lat\":%s,\"lon\":%s}", sqn, flat_s.c_str(), flon_s.c_str() );
        SerialUSB.print("I will send: ");
        SerialUSB.println((char*)mydata);
        LMIC_setTxData2(1, mydata, strlen((char*)mydata), 1);
        sqn++;
    }
}

void setup()
{
    SerialUSB.begin(115200);
    Serial1.begin(9600);
    //while(!SerialUSB);
    SerialUSB.println("Starting");

    pinMode(LED_RED, OUTPUT);
    pinMode(LED_GREEN, OUTPUT);
    pinMode(LED_BLUE, OUTPUT);
    
    pinMode(BUTTON_PIN, INPUT_PULLUP);
    
    digitalWrite(LED_RED, HIGH);
    digitalWrite(LED_GREEN, HIGH);
    digitalWrite(LED_BLUE, HIGH);

    os_init();

    LMIC_reset();
    LMIC_setClockError(MAX_CLOCK_ERROR * 1 / 100);
    LMIC_startJoining();
}

void loop()
{
    static int flag = false;
    bool newData = false;
    unsigned long age;
    os_runloop_once();

    while (Serial1.available())
    {
      // Feed TinyGPS with NMEA messages
      char c = Serial1.read();
      if (gps.encode(c)) newData = true;  // Set newData flag if a new GPS data is available
    }

    if (newData)
    {
      // If a new GPS data is available, update GPS position vars (flat, flon and age)
      gps.f_get_position(&flat, &flon, &age);
      if ( flat == TinyGPS::GPS_INVALID_F_ANGLE ) flat = DEFAULT_LAT;
      if ( flon == TinyGPS::GPS_INVALID_F_ANGLE ) flon = DEFAULT_LON;
      if ( (flat != 0) && (flon != 0) ) digitalWrite(LED_GREEN, LOW);
      newData = false;
    }
  
    if ( digitalRead(BUTTON_PIN) )
    {
      if ( flag ) {
        // If the Yah! push button is released (once)
        flag = false;
        digitalWrite(LED_GREEN, HIGH);
      }
    }
    else
    {
      if ( !flag ) {
        // If the Yah! push button is pressed (once)
        flag = true;
        digitalWrite(LED_GREEN, LOW);   
        do_send(NULL);
      }
    }
}
```

La postion du GPS est envoyée au moins toutes les 30 secondes, ou plus tôt dès que le bouton poussoir est enfoncé.

La LED RGB permet d'avoir un feedback sur la connexion au réseau, le fix du GPS et l'envoi des messages :

- rouge = attente d'association au réseau (JOIN en cours),
- vert = GPS fixé, position GPS disponible
- bleu = message en cours d'envoi (attente de l'acquittement)
