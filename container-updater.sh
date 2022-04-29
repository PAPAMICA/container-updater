#!/bin/bash
DISCORD_WEBHOOK=$1
UPDATED=""
UPDATE=""
for CONTAINER in $(docker ps --format {{.Names}}); do
    echo $CONTAINER
    IMAGE=$(docker container inspect $CONTAINER | jq -r '.[].Config.Image' | cut -d: -f1)
    token=$(curl --silent "https://auth.docker.io/token?scope=repository:$IMAGE:pull&service=registry.docker.io" | jq -r '.token')
    digest=$(curl --silent -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        -H "Authorization: Bearer $token" \
        "https://registry.hub.docker.com/v2/$IMAGE/manifests/latest" | jq -r '.config.digest')
    local_digest=$(docker images -q --no-trunc $IMAGE)
    if [ "$digest" != "$local_digest" ] ; then
        UPDATE=$(echo -E "$UPDATE$IMAGE\n")
        CONTAINERS=$(echo -E "$CONTAINERS$CONTAINER\n")
    fi
    AUTOUPDATE=""
    AUTOUPDATE=$(docker container inspect $CONTAINER | jq -r '.[].Config.Labels."autoupdate"')
    PORTAINER_WEBHOOK=$(docker container inspect $CONTAINER | jq -r '.[].Config.Labels."autoupdate.webhook"')
    if [ "$AUTOUPDATE" == "true" ]; then
        echo "$CONTAINER A METTRE A JOUR ($PORTAINER_WEBHOOK)"
        UPDATED=$(echo -E "$UPDATED$CONTAINER\n")
    fi
done
docker image prune -f

echo $UPDATE
echo $CONTAINERS
echo $UPDATED

if [ -n $UPDATED ]; then 
    echo "1"
    curl  -H "Content-Type: application/json" \
    -d '{
        "content": null,
        "embeds": [
        {
            "title": "There are some updates to do !",
            "color": 16759896,
            "fields": [
            {
                "name": "Container",
                "value": "'$CONTAINERS'",
                "inline": true
            },
            {
                "name": "Images",
                "value": "'$UPDATE'",
                "inline": true
            },
            {
                "name": "Auto Updated",
                "value": "'$UPDATED'",
                "inline": false
            }
            ],
            "author": {
            "name": "'$HOST'"
            }
        }
        ],
        "attachments": []
    }' \
    $DISCORD_WEBHOOK
    exit
fi
if [ -n $UPDATE ]; then 
    echo "2"
    curl  -H "Content-Type: application/json" \
    -d '{
        "content": null,
        "embeds": [
        {
            "title": "There are some updates to do !",
            "color": 16759896,
            "fields": [
            {
                "name": "Container",
                "value": "'$CONTAINERS'",
                "inline": true
            },
            {
                "name": "Images",
                "value": "'$UPDATE'",
                "inline": true
            },
            ],
            "author": {
            "name": "'$HOST'"
            }
        }
        ],
        "attachments": []
    }' \
    $DISCORD_WEBHOOK
    exit
else
    echo "3"
    curl  -H "Content-Type: application/json" \
    -d '{
  "content": null,
  "embeds": [
    {
      "title": "Everything is up to date ! 😍",
      "color": 5832543,
      "author": {
        "name": "'$HOST'"
      }
    }
  ],
  "attachments": []
}' \
    $DISCORD_WEBHOOK
fi