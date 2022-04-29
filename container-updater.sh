#!/bin/bash
DISCORD_WEBHOOK=$1
UPDATED=""
UPDATE=""

# make sure that docker is running
DOCKER_INFO_OUTPUT=$(docker info 2> /dev/null | grep "Containers:" | awk '{print $1}')

if [ "$DOCKER_INFO_OUTPUT" != "Containers:" ]
  then
    exit 1
fi


for CONTAINER in $(docker ps --format {{.Names}}); do
    AUTOUPDATE=$(docker container inspect $CONTAINER | jq -r '.[].Config.Labels."autoupdate"')
    if [ "$AUTOUPDATE" == "true" ]; then
        IMAGE=$(docker container inspect $CONTAINER | jq -r '.[].Config.Image')
        if ! docker pull $IMAGE | grep "Image is up to date"; then
            if [ $? != 0 ]; then
                ERROR=$(cat $ERROR_FILE | grep "not found")
                if [ "$ERROR" != "" ]; then
                echo "WARNING: Docker image $IMAGE not found in repository, skipping"
                else
                echo "ERROR: docker pull failed on image - $IMAGE"
                exit 2
                fi
            else
                PORTAINER_WEBHOOK=$(docker container inspect $CONTAINER | jq -r '.[].Config.Labels."autoupdate.webhook"')
                curl -X POST $PORTAINER_WEBHOOK
                UPDATED=$(echo -E "$UPDATED$CONTAINER\n")
            fi
        fi
    fi
    if [ "$AUTOUPDATE" == "monitor" ]; then
        IMAGE=$(docker container inspect $CONTAINER | jq -r '.[].Config.Image')
        if ! docker pull $IMAGE | grep "Image is up to date"; then
            if [ $? != 0 ]; then
                ERROR=$(cat $ERROR_FILE | grep "not found")
                if [ "$ERROR" != "" ]; then
                echo "WARNING: Docker image $IMAGE not found in repository, skipping"
                else
                echo "ERROR: docker pull failed on image - $IMAGE"
                exit 2
                fi
            else
                UPDATE=$(echo -E "$UPDATE$CONTAINER\n")
            fi
        fi
    fi
done
docker image prune -f

if [[ ! -z "$UPDATED" ]]; then 
    curl  -H "Content-Type: application/json" \
    -d '{
   "username":"['$HOSTNAME']",
   "content":null,
   "embeds":[
      {
         "title":"There are some updates to do !",
         "color":16759896,
         "fields":[
            {
               "name":"Container",
               "value":"'$CONTAINERS'",
               "inline":true
            },
            {
               "name":"Images",
               "value":"'$UPDATE'",
               "inline":true
            },
            {
               "name":"Auto Updated",
               "value":"'$UPDATED'",
               "inline":false
            }
         ],
         "author":{
            "name":"'$HOSTNAME'"
         }
      }
   ],
   "attachments":[
      
   ]
}' \
    $DISCORD_WEBHOOK
    exit
fi
if [[ ! -z "$UPDATE" ]]; then 
    curl  -H "Content-Type: application/json" \
    -d '{
        "username": "['$HOSTNAME']",
       "content":null,
       "embeds":[
          {
             "title":"There are some updates to do !",
             "color":16759896,
             "fields":[
                {
                   "name":"Container",
                   "value":"'$CONTAINERS'",
                   "inline":true
                },
                {
                   "name":"Images",
                   "value":"'$UPDATE'",
                   "inline":true
                }
             ],
             "author":{
                "name":"'$HOSTNAME'"
             }
          }
       ],
       "attachments":[
          
       ]
    }' \
    $DISCORD_WEBHOOK
    exit
else
    curl  -H "Content-Type: application/json" \
    -d '{
   "username":"['$HOSTNAME']",
   "content":null,
   "embeds":[
      {
         "title":"Everything is up to date ! 😍",
         "color":5832543,
         "author":{
            "name":"'$HOSTNAME'"
         }
      }
   ],
   "attachments":[
      
   ]
}' \
    $DISCORD_WEBHOOK
fi