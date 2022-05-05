# container-updater
🚀 A little bash script for alert and autoupdate containers deployed with docker run, docker-compose or Portainer.

🟣 Send notification to Discord (optionnal)

🔴 Send data to Zabbix (optionnal)

🔆 Discord notification exemple :
![ohunebellenotif](https://send.papamica.fr/f.php?h=25rsdWHk&p=1)

## Requirements
```
jq, zabbix-sender (if you use Zabbix)
```

## Use 
```bash
git clone https://github.com/PAPAMICA/container-updater
cd container-updater
./container-updater.sh
```

You can send notification to Discord with this argument:
```bash
-d <discord_webhook>
```

You can send data to Zabbix with this argument:
```bash
-z <zabbix_server>
-n <host_name> (optional)
```
### For a daily execution, add a cron
```bash
00 09 * * * /chemin/vers/container-updater.sh -d <discord_webhook> -z <zabbix_server> >> /var/log/container-updater.log
```

## Monitoring
To supervise the updates of a container, you just have to add this label:
```yaml
labels:
    - "autoupdate=monitor"
```
In this case, if an update is available, the script will simply send a notification to Discord.
All you have to do is update the container.

## Auto-update
To activate the automatic update of the container, you must add these labels:


### docker run
```bash
-l "autoupdate=true" -l "autoupdate.docker-run=true"
```

### docker-compose
```yaml
labels:
    - "autoupdate=true"
    - "autoupdate.docker-compose=/link/to/docker-compose.yml"
```

### Portainer
You need to have Portainer in enterprise version (free license up to 5 nodes). 
You can find the webhook in the stack or container settings.
```yaml
labels:
    - "autoupdate=true"
    - "autoupdate.webhook=<webhook_url>"
```



