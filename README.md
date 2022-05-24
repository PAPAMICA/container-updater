<p align="center">
  <a href="https://papamica.com">
    <img src="https://zupimages.net/up/20/04/7vtd.png" width="140px" alt="PAPAMICA" />
  </a>
</p>

<p align="center">
  <a href="#"><img src="https://readme-typing-svg.herokuapp.com?center=true&vCenter=true&lines=Container+updater;"></a>
</p>
<p align="center">
    🚀 A little bash script for alert and autoupdate containers deployed with docker run, docker-compose or Portainer.
</p>
<p align="center">
    <a href="https://github.com/PAPAMICA/container-updater#requirements"><img src="https://img.shields.io/badge/How_to_use-%2341454A.svg?style=for-the-badge&logo=target&logoColor=white"> </a>
    <a href="https://github.com/PAPAMICA/container-updater#monitoring"><img src="https://img.shields.io/badge/Monitoring-%2341454A.svg?style=for-the-badge&logo=target&logoColor=white"> </a>
    <a href="https://github.com/PAPAMICA/container-updater#auto-update"><img src="https://img.shields.io/badge/Auto_update-%2341454A.svg?style=for-the-badge&logo=target&logoColor=white"> </a>
    <br /><br />
    <a href="#"><img src="https://img.shields.io/badge/bash-%23CDCDCE.svg?style=for-the-badge&logo=gnubash&logoColor=1B1B1F"> </a>
    <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/docker-%232496ED.svg?style=for-the-badge&logo=docker&logoColor=white"> </a>
    <a href="https://www.portainer.io/"><img src="https://img.shields.io/badge/portainer-%2313BEF9.svg?style=for-the-badge&logo=portainer&logoColor=white"> </a>
    <a href="https://zabbix.com"><img src="https://img.shields.io/badge/zabbix-%23CC2936.svg?style=for-the-badge&logo=zotero&logoColor=white"> </a>
    <a href="https://www.discord.com"><img src="https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white"> </a>
    <br />
</p> 

🔵 Support of Docker hub (docker.io) and Github (ghcr.io) registries

🟣 Send notification to Discord (optionnal)

🔴 Send data to Zabbix (optionnal)

🔆 Discord notification example :
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

If you use Github as registry, you need to set your personnal access token:
```bash
-g <access_tocken>
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

You can blacklist packages for autoupdate:
```bash
-b <package,package>
```
### For a daily execution, add a cron
```bash
00 09 * * * /chemin/vers/container-updater.sh -d <discord_webhook> -b <package,package> -z <zabbix_server> >> /var/log/container-updater.log
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
You need to have Portainer in enterprise version ([free license up to 5 nodes](https://www.portainer.io/pricing/take5?hsLang=en)). 
You can find the webhook in the stack or container settings.
```yaml
labels:
    - "autoupdate=true"
    - "autoupdate.webhook=<webhook_url>"
```

## To Do
- Add private registry support
- Better json generate for Discord notification
- Others notifications support


