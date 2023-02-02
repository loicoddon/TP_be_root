# Rapport Be Root

## Synthèse managériale

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed non risus. Suspendisse lectus tortor, dignissim sit amet, adipiscing nec, ultricies sed, dolor. Cras elementum ultrices diam. Maecenas ligula massa, varius a, semper congue, euismod non, mi. Proin porttitor, orci nec nonummy molestie, enim est eleifend mi, non fermentum diam nisl sit amet erat. Duis semper. Duis arcu massa, scelerisque vitae, consequat in, pretium a, enim. Pellentesque congue. Ut in risus volutpat libero pharetra tempor. Cras vestibulum bibendum augue. Praesent egestas leo in pede. Praesent blandit odio eu enim. Pellentesque sed dui ut augue blandit sodales. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aliquam nibh. Mauris ac mauris sed pede pellentesque fermentum. Maecenas adipiscing ante non diam sodales hendrerit.

### Attaque 1 : Erreur de capabilities

#### **Introduction :**
Les capabilities sous Linux sont un mécanisme de contrôle d'accès qui permet de limiter les privilèges d'un processus. Au lieu de donner à un processus un ensemble complet de privilèges, les capabilities permettent de décomposer les privilèges en différentes capacités indépendantes.

Chaque capacité représente un privilège spécifique, comme la capacité de lire ou d'écrire dans un fichier protégé, de changer l'ID utilisateur d'un processus, etc. Les programmes peuvent être conçus pour n'avoir accès qu'à un sous-ensemble restreint de capacités, ce qui les empêche d'exécuter des actions malveillantes ou dangereuses.

Les capabilities peuvent être définies au niveau du système ou au niveau du processus en utilisant des outils tels que setcap ou pcapset. Les capabilities peuvent également être définies en utilisant les options de lancement de programmes pour spécifier les capacités nécessaires à un processus pour fonctionner.

En utilisant les capabilities, les administrateurs système peuvent mieux contrôler les privilèges des processus sur le système, ce qui peut aider à réduire les risques de sécurité en limitant les actions que les processus peuvent effectuer.

Voici une liste de capabilites non-exhaustive : 

| Nom          | Utilisation                                       |
|--------------|---------------------------------------------------|
| CAP_SETGID   | Permet le changement du GID                       |
| CAP_SETUID   | Permet le changement du UID                       |
| CAP_SETPCAP  | Permet le transfert de capabilites à d’autres PID |
| CAP_IPC_LOCK | Permet de verrouiller la mémoire                  |
| ...          | ...                                               |

#### **Prérequis pour l'attaque :**
Pour pouvoir exploiter une vulnérabilité basée sur les capabilites de Linux il va nous falloir vérifier si des exécutables binaires ont été modifiés afin de savoir s'ils sont vulnérables à l'exécution d'un code arbitraire.

Il faut donc que l'administrateur du serveur ait fait une erreur de configuration sur un des binaires pour pouvoir nous en servir.


#### **Exploitation de la vulnérabilité :** 

Premièrement dans l'exemple ci-dessous l'utilisation du compte utilisateur linux **www-data** sera faite. Cette utilisateur a donc des droits restreints sur la majorité du serveur hormis la partie Web.

> sudo -u www-data bash | Permet de se connecter sur cet utilisateur

Au préalable de l'exploitation nous allons faire de la reconnaisance. C'est-à-dire chercher des binaires qui ont été modifiés sur le serveur.

Des utilitaires comme [*linpeas*](https://github.com/carlospolop/PEASS-ng/tree/master/linPEAS) peuvent permettre de faire une reconnaisance globale d'un serveur en recherchant des erreurs de configuration sur des services, problème de droits etc...

Dans notre cas l'utilisation d'une commande sera suffisante : 

```bash
getcap -r / 2>/dev/null
```

Cette commande retourne en résultat les fichiers binaires qui ont été modifiés par un utilisateur à haut privilège.

La commande retourne cette ligne : 
> /usr/bin/php5 = cap_setuid+ep
> 

Comme vu auparavant ***cap_setuid*** nous permet de dire que la manipulation des UID est possible avec le binaire ***php5***.

Maintenant que nous avons cette information, l'exploitation de la vulnérabilité est possible en lancant la commande suivante : 

```bash
CMD="/bin/bash" && /usr/bin/php5 -r "posix_setuid(0); system('$CMD');"
```
Cette commande utilise l'interpréteur de commandes PHP pour exécuter une commande shell. Elle accomplit les actions suivantes :

- /usr/bin/php5 : Ce chemin d'accès indique à l'interpréteur de commandes du système d'exécuter l'interpréteur PHP5.

- -r : Ce drapeau indique à PHP d'exécuter le code suivant en mode ligne de commande, sans lire de fichier PHP.

- posix_setuid(0) : Cette fonction PHP appelle la fonction setuid de la bibliothèque POSIX pour définir l'identificateur d'utilisateur (UID) sur 0, ce qui signifie que le processus exécutant ce code aura les privilèges du superutilisateur (root).

- system('$CMD') : Cette instruction PHP appelle la fonction system pour exécuter une commande shell en utilisant la variable $CMD. La variable $CMD contient la commande shell à exécuter.

A partir de là, intépreteur de commande est donc lancé en tant **qu'administrateur du serveur**.


### Défense 1 : Erreur de capabilities

#### Mise en place de la défense

La manière la plus simple est d'enlever le droit d'exécution de changement des UID sur le binaire en question PHP5 : 

```bash
setcap -r /usr/bin/php5
```
L'exploitation de cette vulnérabilité ne sera plus envisageable.

Pour anticiper ce type de modification il y a des outils comme AIDE qui s'agit d'une solution de détection des intrusions basée sur les modifications apportées au système surveillé.

Ce type de solution est également appelée solution de contrôle d'intégrité ou de scellement, elle vise à s'assurer qu'un ensemble d'éléments de notre système n'ont pas été modifiée.

On peut donc faire en sorte de le configurer pour vérifier lorsqu'il a des manipulations sur le serveur.

### Attaque 2 : Erreur de droit via sudo ou setuid

### Défense 2 : Erreur de droit via sudo ou setuid

### Attaque 3 : Erreur de mise à jours

### Défense 3 : Erreur de mise à jours

### Attaque 4 : Erreur de fichier contenant des mots de passes accessibles à tous

### Défense 4 : Erreur de fichier contenant des mots de passes accessibles à tous
