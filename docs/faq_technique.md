# FAQ technique

## Un objet est programmé pour envoyer de la donnée toutes les minutes mais on ne les voit que toutes les 3 voire 4 minutes. Pourquoi ?

Ce n'est pas anormal. C'est juste les conséquences de l'implémentation des lois régissant l'utilisation de la fréquence "libre" 866Mhz

Si le device émet un message par une certaine durée, il va donc occuper la bande. Il devra donc attendre entre 100 fois ce temps là et 1000 fois. Cela dépend du canal utilisé et du _Spreading Factor_

Voir ce calculateur en ligne : https://www.loratools.nl/#/airtime

Par exemple, en SF12, pour une payload de 30 octets, on peut envoyer un message toutes les 2 minutes 45 secondes.

## SF7, SF12 qu'est ce que ça veut dire ?

Il y a 6 niveaux de _Spreading Factor_ de SF7 à SF12. En première approche, plus le SF est grand, plus il faut envoyer d'informations pour transmettre un seul bit. Cela prendra donc plus de temps (et donc d'énergie) mais permet de porter plus loin ou dans un environnement plus bruité.

## Quelles sont les contraintes légales sur la bande 868Mhz ?

La bande 868Mhz fait partie des bandes dites ISM (industriel, scientifique et médical). Elle peut être utilisée sans licence. C'est une bande libre.

Cette ressource hertzienne doit donc pouvoir être partagé entre de nombreux acteurs. Pour cela, la loi impose certaines limitations: 

* limitation de la puissance d'émission utilisable. La PAR (puissanca apparente rayonnée) ne doit pas dépasser 25mW pour du 868 Mhz.
* limitation du taux d'utilisation temporel de la ressource. C'est le rapport de temps sur une heure durant lequel l’équipement émet effectivemen. Plus connu par le terme de _duty cycle_ il être inférieur à 1% (868,0-868,6 MHz) voire 0,1% (868,7-869,2 MHz) suivant les canaux utilisés. Par exemple avec un _duty cylce_ de 1%, si pour émettre votre message, votre émetteur utilise la bande pendant 36 secondes, il devra attendre 1h (3600 secondes) avant de pouvoir émettre à nouveau. Au exemple, s'il nécessite 5 secondes pour envoyer un message, alors il pourra en envoyer environ 172 par jour. Cela correspond à 86400/(5*100).

Voir : https://www.anfr.fr/fileadmin/mediatheque/documents/tnrbf/Annexe_7_Mod8.pdf

À noter que la bande ISM 868Mhz est libre d'usage en Europe mais interdite aux USA où c'est celle en 915Mhz qui est sans licence.


## Bon, OK, quel est vraiment le débit en LoRaWAN ?

Selon la norme LoRaWAN, le débit est compris entre 0,3 et 50 kbps. Soit entre 40 octets et 6Ko par seconde.

## Pourquoi les données sont-elles codées en base64 et qu'est ce que cette base64 ?

Base64 est un codage de l'information utilisant 64 caractères. Ce n'est pas du tout un chiffrement. 

On découpe l'information en groupes de 24 bits (donc 3 octets). Chaque groupe de 24 bits est séparé en quatre nombres de six bits (soit 2^6=64 possibilités). Chaque valeur est ensuite représentée par un caractère de l'alphabet base64. Si on n'a pas un multiple de 24 bits, on remplit avec des zéros de façon à former un caractère de l'alphabet puis on remplit avec le caractère "=" pour arriver à un multiple de 24 bits. On le voit frequemment dans les payload en MQTT.

Pour des données purement textuelles, ce codage augmente un peu la taille. Son intérêt réside dans le codage de données binaires (images, son) ce qui est le cas le plus fréquent en LoRaWAN.

En effet, la plupart des canaux de communication arrivent à transmettre des données textuelles de façon fiable sans les corrompre. Ce qui est moins le cas de données binaires...

Ainsi en convertissant en base64, on rentre dans le monde du textuel qui peut passer par divers canaux sans alterations.