# Foire Aux Questions

## LoRa et LoRaWAN, ce n’est pas la même chose?

LoRa pour _Long Range_, est une modulation radio permettant à des équipements de transmettre des informations sans fil. C’est un réseau étendu à faible consommation (_Low Power Wide-Area Network_ (LPWAN)). Elle utilise la bande [ISM](https://fr.wikipedia.org/wiki/Bande_industrielle,_scientifique_et_m%C3%A9dicale) (868 Mhz en Europe, d'utilisation libre dans certaines mesures). Cette modulation radio correspond à la couche liaison.

LoRaWAN est un protocole Low Power Wide Area Network (LPWAN) basé sur LoRa pour les objets connectés sans fils sur batterie dans un réseau régional, national ou mondial. LoRaWAN permet de la communication bi-directionnelle sécurisée (chiffrement AES128) ainsi que de la localisation. Le protocole correspond à la couche réseau.

## Quel est le débit ?

Selon la norma LoRaWAN, le débit est compris entre 0,3 et 50 kbps. Soit entre 40 octets et 6Ko par seconde.

## Qu’est ce que MQTT ?

MQTT, pour _Message Query Telemetry Transport_ est un protocole de communication.

Les passerelles, le serveur de réseau et le serveur application de LoRa utilisent le protocole MQTT.

Contrairement au principe du client/serveur utilisé dans le domaine du Web, MQTT utilise celui de la publication/souscription : plusieurs clients se connectent à un serveur unique, un _broker_, où ils publient ou reçoivent des informations. On peut comparer le fonctionnement du protocole au fonctionnement de Twitter, ou bien Instagram. 

MQTT est conçu pour utiliser le moins de ressources possibles, ouvert (c’est un standard OASIS) et simple à implémenter. Il est surtout conçu pour consommer le moins de ressources possibles. À l'origine, il a été conçu par IBM pour faire de la télémesure par satellitte.

Il fonctionne sur TCP/IP mais aussi sur tout protocole réseau permettant des connections bidirectionnelles, sans perte et ordonnées.
Il est particulièrement adapté aux communications "machine to machine" (M2M). 

## Comment fonctionne le protocole MQTT ?

L’ensemble des clients communiquent via un _broker_.

Les clients s’enregistrent auprès du broker sur des topics, que l’on peut voir comme des chemins pour accéder à une ressource. Cela leur permet d’être avertis, notifiés lorsque quelqu'un publie sur ces topics.

Cela peut être un topic de température par exemple : /sensor/1/temperature.

On peut souscrire à un ensemble de topics en utilisant des wildcards # ou +.

Par exemple, si un client publie sur les topics /sensor/1/temperature et /sensor/1/humidity, un autre client peut écouter ces deux topics à la fois : /sensor/1/#.
Si plusieurs clients publient leurs températures et humidités en intercalant leur numéro de client sur leur topic, un autre client peut écouter toutes les températures ainsi : /sensor/+/temperature. Il recevra alors les températures du client 1 (/sensor/1/temperature), du client 2 (/sensor/2/temperature), etc.

## Qu’est ce que Node-RED?

Node-RED est un logiciel libre de programmation graphique par blocs (un peu comme Scratch !). Il permet de traiter des flux de données en les faisant passer par différentes boites qui appliquent divers traitements.

Plus précisemment, il fournit une interface web graphique permettant de représenter les flux de données par des noeuds et des liens. L’outil a été développé par une équipe de [IBM’s Emerging Technology Services](https://emerging-technology.co.uk/) et est maintenant un projet de la [JS Foundation](https://js.foundation/). L’application repose sur Node.js et les flux créés avec l’application sont stockés en utilisant des fichiers JSON.
Vous pouvez trouver plus d'informations sur le [site officiel](https://nodered.org/about/).

## À quoi sert LoRaWAN ?

Plusieurs produits peuvent être connectés grâce à LoRaWan.

Dans le cadre professionnel, LoRaWAN va nous permettre de connaître, par exemple : 

 - l’état de fermeture des portes des baraques de chantier (pour prévenir d’un éventuel cambriolage)
 - la géolocalisation des engins de chantiers
 - les places libres dans les parkings
 - faire des relevés à distance de compteurs d'électricité, d'eau, de gaz.

LoRaWan va également permettre à un agriculteur de mettre en réseau tout son système de capteurs météo pour automatiser l’arrosage de ses champs. 

Un maire va pouvoir faire de la télémesure, vérifier si les éclairages d'équipements publics sont bien éteints, optimiser les éclairages de sa ville en fonction du trafic et ainsi réduire les coûts et l'impact sur l'environnement sans toucher au confort de ses concitoyens. 

Certaines entreprises peuvent déployer un réseau LoRaWAN privé pour localiser des objets ou des machines à l'intériur de leurs locaux (là où le GPS ne fonctione pas).

Dans les zones de montagne à risque qui sont en plus en zone blanche, une passerelle LoRaWAN peut couvrir un large domaine : localisation de randonneurs, mesures de température, de présence dans un refuge éloigné...

Certains opérateurs de grandes courses (trail, ultra...) déploient aussi un réseau privé pour géolocaliser les participantes et participants en temps réel. Surtout sur les portions du parcours non couvertes par le réseau GSM.

Pour les particuliers, il leur permettra de créer leur propre réseau en connectant les objets de sa maison avec de petites balises pour qu’il localise ses objets n’importe quand. On note aussi des utilisations dans la surveillance des habitations pour lutter contre les cambriolages. 
En effet, certains cambrioleurs peuvent essayer de parasiter les procoles usuels de communication des systèmes d'alarme de façon à ce que leur présence ne soit pas signalée aux autorités de police. 
Une redondance du système classique par un système sous LoRaWAN ou SigFox permet de ne pas être sensible au brouillage radio car la technologie radio est très robuste et justement conçue pour passer au travers du bruit radio.

Un tel réseau permet le développement d’un écosystème d’objets connectés, d’applications et de services dans de nombreux secteurs dans le cadre de projets menés aussi bien par des entreprises privées que par des acteurs publics.

Dans tous les cas, il faudra bien réflechir à utiliser un réseau LoRaWAN existant ou à déployer votre propre réseau privé. Cette dernière solution n'étant pas nécessairement très complexe et permet d'avoir une maîtrise totale.

## Quels sont les opérateurs de réseaux LoRaWAN ?

Nous ! Mais citons aussi Bouygues avec Objenious, Orange et d'autres.

À noter, la société fleetspace qui est en train de déployer un ensemble de satellittes pour assurer une couverture mondiale LoRaWAN : [https://twitter.com/buildrootorg/status/1118066443759890432](https://twitter.com/buildrootorg/status/1118066443759890432) et [https://www.fleet.space/](https://www.fleet.space/)

## Et Sigfox ? 

LoRaWAN est un protocole qui peut utilisé librement. En pratique, il faut soit déployer son propre réseau, soit utiliser celui d'un opérateur.

SigFox est à la fois un protocole et un opérateur.

En tant qu'utilisateurs et contributeurs du libre, notre choix s'est porté naturellement sur LoRaWAN. De plus, nous avons les moyens de déployer notre propre infrastructure "opérateur" sur Toulouse (6 passerelles actives pour le moment) et Albi (2 actives).

## Est-ce que c’est sécurisé ? 

Toutes les communications en LoRaWAN sont chiffrées selon une méthode proche d'AES-128. Le protocole implémente plusieurs clefs, propres à chaque équipement terminal, afin d'assurer la sécurité des échanges au niveau réseau et applicatif.

Une clef AES d'une longueur de 128 bits appelée Appkey est utilisée pour générer les clefs _NetworkSessionKey_ (NwkSkey) et _Application Session key_ (AppSKey). 

- La NwkSkey assure l’identification, ce qui empêche des attaques du type "homme du milieu" ou une modification des messages à la volée. Elle utilise un clé AES 128 pour générer un code MIC (Message Integrity Code) pour chaque message.

- La AppSKey est utilisée par le serveur et l'équipement d'extrémité pour générer le champ d'intégrité MIC présent dans les paquets. Ce champ permet d'assurer que le paquet n'a pas été modifié en cours de transfert par un équipement malveillant. Cette clef est également utilisée pour chiffrer le contenu des messages contenant uniquement des commandes MAC3. Elle utilise aussi une clé AES 128.

La clef AppSKey est utilisée pour chiffrer les données applicatives présentes dans le paquet. Cette clef assure seulement la confidentialité du contenu du message mais pas son intégrité, ce qui signifie que si les serveurs réseau et applicatifs sont distincts, le serveur réseau est capable de modifier le contenu du message. De ce fait, la spécification LoRaWAN recommande d'utiliser des méthodes de protections de bout en bout supplémentaires pour les applications qui nécessiteraient un degré de sécurité supérieur.

Deux procédures d'activation sont possibles :

- Activation By Personalization (ABP), Les clefs de chiffrement sont stockées dans les équipements.
- Over The Air (OTAA) : Les clefs de chiffrement sont obtenues par un échange avec le réseau (un peu comme en HTTPS ou ssh).

Voir la page "cryptographie" pour plus d'informations.

## Combien ça coûte ?

Si vous voulez essayez le réseau LoRaWAN et que vous avez des connaissances en développement, il vous faudra de nombreux équipements, voici une solution. Sachez qu’elle n’est pas unique, et qu’il est tout à fait possible d’utiliser d’autres équipements. Ainsi il va vous falloir : 

| Objet | Utilité | Prix Min
| ----- | ------- | --------
| RAK831 : passerelle | Relie le réseau LoRa au serveur  | 140 €
| Raspberry Pi | Objet sur lequel vous allez pouvoir agir, développer et concevoir votre installation | 30 €
| GPS Antenna  | Antenne GPS permettant de localiser | 15 €
| Converter Board |  | 30 €
| Raspberry Pi Casing | Protection du Rapsberry  | 5 €
| LoRa Antenna  | Antenne de diffusion et de réception des données | 15 €
| Micro USB  | Cable USB pour relier votre raspberry à votre ordinateur | 13 €
| 16G TF Card  | Carte micro-SD, permettant de disposer d’une mémoire externe  | 7 €

Ici, les prix sélectionnés sont ceux les moins chers proposés sur Internet. Donc si vous achetez chacun de ces objets individuellement, cela vous coutera minimum 255 euros. 
Des packs sont disponibles à environ 200 euros sur Internet comprenant le matériel nécessaire pour commencer. 
Il faut savoir que les fourchettes de prix données ici sont celles utilisées pour un petit réseau et non pas pour une entreprise. Par exemple, une antenne LoRa peut coûter jusqu'à 3000 euros (cela dépendra de la distance à laquelle vous voulez envoyer ou recevoir les informations).

Les passerelles LoRaWAN que nous déployons coûtent autour de 150€.

## Je ne suis pas développeur, comment puis-je m’en servir ?

La technologie peut être appliquée dans de nombreux domaines qui ne concernant pas seulement les nouvelles technologies. Cependant, pour l'installation, le paramétrage et la maintenance, il faudrait faire appel à un développeur ou un autre expert. Ce dernier pourra construire une interface intuitive et ergonomique pour rendre l'utilisation et l'exploitation des données simples, quelque que soit le domaine appliqué et l'expertise de l'utilisateur.

## À quoi sert une passerelle ? 

De manière générale, une passerelle (ou _gateway_) est le nom générique d'un dispositif permettant de relier deux réseaux informatiques de types différents. Dans notre cas, il s'agit de relier les antennes des objets au reste du réseau (Internet) en relayant les informations.

- Objet -> Passerelle : une communication avec la technologie LoRa permet de connecter les objets aux passerelles. Avec LoRa, cette communication s’effectue en un seul saut capteur-passerelle.
- Passerelle -> Réseau : différents types de communications peuvent connecter la passerelle LoRa au serveur-IoT/Cloud. On retrouve généralement une connexion filaire Ethernet, ou sans fil avec WiFi ou 3G/4G; ces liens hétérogènes représentent la connexion Internet. 

Ainsi, la passerelle LoRa doit disposer d’au moins 2 interfaces de communication; une radio LoRa et une interface Ethernet, WiFi ou 3G/4G.

## Quelles sont les étapes-clés pour mettre en place un réseau LoRa ? 

Il faut, pour cela, se munir d’une antenne reliée à internet (par Wi-Fi, câble Ethernet, connexion 3G…) avec une station de base émettant en France sur la bande 868 MHz. Le réseau peut-être privé ou public suivant le domaine d’application. Une entreprise préférera protéger les données transmises. A noter que la bande de fréquence disponible change par pays. Aux Etats-Unis, par exemple, la bande de fréquence utilisée pour le réseau LoRa est 915 MHz.

Les objets connectés doivent, quant à eux, être équipés d’une puce LoRa qui leur permet de recevoir le signal de l’antenne. Un émetteur récepteur de ce type coûte environ 7 euros à l’unité, beaucoup moins si la commande est importante. Mais sans passerelle et sans antenne compatible, le fonctionnement du réseau est impossible. Les opérateurs agissent principalement à ce niveau.

## Et la consommation énergétique dans tout ça ? 

LoRaWAN est un protocole spécialement développé pour limiter au maximum la consommation d'énergie. Un objet LoRaWAN devrait être capable de fonctionner sur pile plus d'un an en fonction de son programme. On distingue trois modes de fonctionnements :

- Le premier permet à un objet d’envoyer des informations vers une antenne puis d’en recevoir immédiatement après l’envoi. Si le serveur veut envoyer des informations à l’objet, il devra attendre le prochain cycle d’envoi. On pense par exemple aux compteurs d’eau qui envoient les données de manière régulière et espacée dans le temps. C’est le mode le moins gourmand en énergie.

- Le second permet à l’objet connecté de recevoir des données à des intervalles réguliers et paramétrés à l’avance.

- Enfin le dernier permet au récepteur de recevoir des données en continu. Ce dernier s’avère le plus énergivore. 

Cependant, les possibilités de combinaisons sont nombreuses et une technologie de réseau n’en efface pas une autre. La plupart des solutions combinent réseau LoRa, fonctionnalités Bluetooth et Wifi avec transmission de données par le biais de réseau cellulaire. Ainsi la consommation énergétique peut varier en fonction des solutions choisies.

## Et l'écologie dans tout ça ? 

C'est tout simplement catastrophique. Comme tous composants informatiques, cela nécessite des terres rares, des métaux lourds le plus souvent extraits dans des conditions environnementales et sociales affreuses. 

Le tout n'est pas recyclable et risque fort de finir dans des décharges à ciel ouvert en Afrique de l'Ouest ou en Asie. Les matériels sont souvent brûlés pour récupérer un peu de métal afin de le revendre sur des marchés. C'est le cas déjà pour vos smartphones, portables et équipements informatiques. Voir le travail du photographe Kai Loeffelbein : [http://kailoeffelbein.com/ctrl-x-a-topography-of-e-waste/ctrl_x_china_011-jpg](http://kailoeffelbein.com/ctrl-x-a-topography-of-e-waste/ctrl_x_china_011-jpg)


Nos sources : 

* [https://www.objetconnecte.com/tout-savoir-reseau-lora-bouygues/](https://www.objetconnecte.com/tout-savoir-reseau-lora-bouygues/)
* [https://www.youtube.com/watch?v=Et2cgJ1_Aec](https://www.youtube.com/watch?v=Et2cgJ1_Aec)
* [https://www.usine-digitale.fr/article/la-metropole-de-dijon-va-investir-53-millions-d-euros-pour-devenir-une-smart-city.N584398](https://www.usine-digitale.fr/article/la-metropole-de-dijon-va-investir-53-millions-d-euros-pour-devenir-une-smart-city.N584398)
* [https://hellofuture.orange.com/fr/dans-les-pays-en-developpement-le-reseau-lora-est-porteur-de-progres/](https://hellofuture.orange.com/fr/dans-les-pays-en-developpement-le-reseau-lora-est-porteur-de-progres/)
* [https://www.objetconnecte.com/tout-savoir-reseau-lora-bouygues/](https://www.objetconnecte.com/tout-savoir-reseau-lora-bouygues/)
* [https://www.frandroid.com/telecom/313396_lora-futur-reseau-objets-connectes](https://www.frandroid.com/telecom/313396_lora-futur-reseau-objets-connectes)
* [https://nodered.org/about/](https://nodered.org/about/)
