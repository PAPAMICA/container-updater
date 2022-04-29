# container-updater
A little bash script for alert and autoupdate container with Portainer.

# Supervision
Pour superviser les mises à jours d'un conteneurs, il faut ajouter ce labe:
```yaml
labels:
    - "autoupdate=monitor"
```
Dans ce cas, le script essayera de pull l'image, s'il y arrive, il se contentera de d'envoyer une notification à Discord.
Il ne vous restera plus qu'à recréer le conteneur.

# Auto-update
Pour activer la mise à jour automatique du conteneur, il faut ajouter ces labels :

## docker-compose
```yaml
labels:
    - "autoupdate=true"
    - "autoupdate.type=docker-compose"
    - "autoupdate.docker-compose=/lien/vers/le/fichier/docker-compose.yml"
```

## docker-run
```yaml
labels:
    - "autoupdate=true"
    - "autoupdate.type=docker-run"
    - "autoupdate.docker-run=<docker_run_command>"
```

## Portainer
Vous avez besoin d'avoir Portainer en version entreprise (licence gratuite jusqu'à 5 nodes)
Vous trouverez le webhook dans les paamètres de la stack ou du container.
```yaml
labels:
    - "autoupdate=true"
    - "autoupdate.type=portainer"
    - "autoupdate.webhook=<webhook_url>"
```

# Utilisation
```bash
git clone https://github.com/PAPAMICA/container-updater
cd container-updater
./container-updater.sh <discord_webhook>
```

## Pour une execution journalière, ajouter un cron
```bash
00 09 * * * /chemin/vers/container-updater.sh <discord_webhook> >> /var/log/container-updater.log
```

