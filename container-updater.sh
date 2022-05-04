#!/bin/bash
DISCORD_WEBHOOK=$1
UPDATED=""
UPDATE=""

# Check if Debian / Ubuntu and if root
if [ "$EUID" -ne 0 ]
  then echo " ❌ Please run as root"
  exit 1
fi
if [ -x "$(command -v apt-get)" ]; then
    :
else
    echo 'This script is only compatible with Debian and Ubuntu'
    exit 1
fi


# Update debian
apt update > /dev/null 2> /dev/null

PAQUET_UPDATE=""
apt list --upgradable 2> /dev/null | tail -n +2 >> temp
while read line ; do 
    PAQUET=$(echo $line | cut -d / -f 1)
    echo "  🚸 Update available: $PAQUET"
    PAQUET_UPDATE=$(echo -E "$PAQUET_UPDATE$PAQUET\n")
done < temp
rm temp
if [[ -z "$PAQUET_UPDATE" ]]; then
   echo " ✅ System is already up to date."
fi

# make sure that docker is running
DOCKER_INFO_OUTPUT=$(docker info 2> /dev/null | grep "Containers:" | awk '{print $1}')

if [ "$DOCKER_INFO_OUTPUT" != "Containers:" ]
  then
    exit 1
fi



# check if first part of image name contains a dot, then it's a registry domain and not from hub.docker.com
Check-Image-Uptdate () {
   IMAGE_ABSOLUTE=$1
   if [[ $(echo $IMAGE_ABSOLUTE | cut -d : -f 1 | cut -d / -f 1) == *"."* ]] ; then
      IMAGE_REGISTRY=$(echo $IMAGE_ABSOLUTE | cut -d / -f 1)
      IMAGE_REGISTRY_API=$IMAGE_REGISTRY
      IMAGE_PATH_FULL=$(echo $IMAGE_ABSOLUTE | cut -d / -f 2-)
   elif [[ $(echo $IMAGE_ABSOLUTE | awk -F"/" '{print NF-1}') == 0 ]] ; then
      IMAGE_REGISTRY="docker.io"
      IMAGE_REGISTRY_API="registry-1.docker.io"
      IMAGE_PATH_FULL=library/$IMAGE_ABSOLUTE
   else
      IMAGE_REGISTRY="docker.io"
      IMAGE_REGISTRY_API="registry-1.docker.io"
      IMAGE_PATH_FULL=$IMAGE_ABSOLUTE
   fi

   # detect image tag
   if [[ "$IMAGE_PATH_FULL" == *":"* ]] ; then
      IMAGE_PATH=$(echo $IMAGE_PATH_FULL | cut -d : -f 1)
      IMAGE_TAG=$(echo $IMAGE_PATH_FULL | cut -d : -f 2)
      IMAGE_LOCAL="$IMAGE_ABSOLUTE"
   else
      IMAGE_PATH=$IMAGE_PATH_FULL
      IMAGE_TAG="latest"
      IMAGE_LOCAL="$IMAGE_ABSOLUTE:latest"
   fi
   # printing full image information
   #echo "Checking for available update for $IMAGE_REGISTRY/$IMAGE_PATH:$IMAGE_TAG..."
}



Check-Local-Digest () {
   DIGEST_LOCAL=$(docker images -q --no-trunc $IMAGE_LOCAL)
   if [ -z "${DIGEST_LOCAL}" ] ; then
      echo "Local digest: not found" 1>&2
      echo "For security reasons, this script only allows updates of already pulled images." 1>&2
      exit 1
   fi
   #echo "Local digest:  ${DIGEST_LOCAL}"
}

Check-Remote-Digest () {
   AUTH_DOMAIN_SERVICE=$(curl --head "https://${IMAGE_REGISTRY_API}/v2/" 2>&1 | grep realm | cut -f2- -d "=" | tr "," "?" | tr -d '"' | tr -d "\r")
   AUTH_SCOPE="repository:${IMAGE_PATH}:pull"
   AUTH_TOKEN=$(curl --silent "${AUTH_DOMAIN_SERVICE}&scope=${AUTH_SCOPE}&offline_token=1&client_id=shell" | jq -r '.token')
   DIGEST_RESPONSE=$(curl --silent -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
      -H "Authorization: Bearer ${AUTH_TOKEN}" \
      "https://${IMAGE_REGISTRY_API}/v2/${IMAGE_PATH}/manifests/${IMAGE_TAG}")
   RESPONSE_ERRORS=$(jq -r "try .errors[] // empty" <<< $DIGEST_RESPONSE)
   if [[ -n $RESPONSE_ERRORS ]]; then
      echo " ❌ [$IMAGE_LOCAL] Error : $(echo "$RESPONSE_ERRORS" | jq -r .message)" 1>&2
   fi
   DIGEST_REMOTE=$(jq -r ".config.digest" <<< $DIGEST_RESPONSE)

   #echo "Remote digest: ${DIGEST_REMOTE}"
}


Compare-Digest () {
   if [ "$DIGEST_LOCAL" != "$DIGEST_REMOTE" ] ; then
      echo "UPDATE"
   else
      echo "OK"
   fi
}

for CONTAINER in $(docker ps --format {{.Names}}); do
    AUTOUPDATE=$(docker container inspect $CONTAINER | jq -r '.[].Config.Labels."autoupdate"')
    if [ "$AUTOUPDATE" == "true" ]; then
        IMAGE=$(docker container inspect $CONTAINER | jq -r '.[].Config.Image')
        Check-Image-Uptdate $IMAGE
        Check-Local-Digest
        Check-Remote-Digest
        if [[ -z $RESPONSE_ERRORS ]]; then
         RESULT=$(Compare-Digest)
            if [ "$RESULT" == "UPDATE" ]; then
               echo " 🚸 [$IMAGE_LOCAL] Update available !"
               echo " 🚀 [$IMAGE_LOCAL] Launch autoupdate !"
               DOCKER_COMPOSE=$(docker container inspect $CONTAINER | jq -r '.[].Config.Labels."autoupdate.docker-compose"')
               if [[ "$DOCKER_COMPOSE" != "null" ]]; then 
                  docker-compose -f $DOCKER_COMPOSE up -d
               fi
               PORTAINER_WEBHOOK=$(docker container inspect $CONTAINER | jq -r '.[].Config.Labels."autoupdate.webhook"')
               if [[ "$PORTAINER_WEBHOOK" != "null" ]]; then 
                  curl -X POST $PORTAINER_WEBHOOK
               fi
               DOCKER_RUN=$(docker container inspect $CONTAINER | jq -r '.[].Config.Labels."autoupdate.docker-run"')
               if [[ "$DOCKER_RUN" != "null" ]]; then 
                  docker run $DOCKER_RUN
               fi
               UPDATED=$(echo -E "$UPDATED$CONTAINER\n")
            else
               echo " ✅ [$IMAGE_LOCAL] Already up to date."
            fi
         fi
    fi
    if [ "$AUTOUPDATE" == "monitor" ]; then
        IMAGE=$(docker container inspect $CONTAINER | jq -r '.[].Config.Image')
        Check-Image-Uptdate $IMAGE
        Check-Local-Digest
        Check-Remote-Digest
        RESULT=$(Compare-Digest)
         if [ "$RESULT" == "UPDATE" ]; then
            echo " 🚸 [$IMAGE_LOCAL] Update available !"
            UPDATE=$(echo -E "$UPDATE$IMAGE\n")
            CONTAINERS=$(echo -E "$CONTAINERS$CONTAINER\n")
         else
            echo " ✅ [$IMAGE_LOCAL] Already up to date."
         fi
    fi
done
echo ""
docker image prune -f

if [[ ! -z "$UPDATED" ]] && [[ ! -z "$UPDATE" ]] && [[ ! -z "$PAQUET_UPDATE" ]]; then 
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
               "name":"Paquets",
               "value":"'$PAQUET_UPDATE'",
               "inline":true
            },
            {
               "name":"Containers",
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

if [[ ! -z "$UPDATED" ]] && [[ ! -z "$UPDATE" ]]; then 
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
               "name":"Containers",
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

if [[ ! -z "$UPDATED" ]] && [[ ! -z "$PAQUET_UPDATE" ]]; then 
    curl  -H "Content-Type: application/json" \
    -d '{
   "username":"['$HOSTNAME']",
   "content":null,
   "embeds":[
      {
         "title":"Containers are autoupdated !",
         "color":5832543,
         "fields":[
            {
               "name":"Paquets",
               "value":"'$PAQUET_UPDATE'",
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

if [[ ! -z "$UPDATED" ]]; then 
    curl  -H "Content-Type: application/json" \
    -d '{
   "username":"['$HOSTNAME']",
   "content":null,
   "embeds":[
      {
         "title":"Containers are autoupdated !",
         "color":5832543,
         "fields":[
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


if [[ ! -z "$UPDATE" ]] && [[ ! -z "$PAQUET_UPDATE" ]]; then 
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
                  "name":"Paquets",
                  "value":"'$PAQUET_UPDATE'",
                  "inline":true
               },
                {
                   "name":"Containers",
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
                   "name":"Containers",
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
fi

if [[ ! -z "$PAQUET_UPDATE" ]]; then 
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
                  "name":"Paquets",
                  "value":"'$PAQUET_UPDATE'",
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