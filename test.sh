PAQUET="docker-compose"
BLACKLIST="prout,docker-compose,youpi"
if [[ "$BLACKLIST" == *"$PAQUET"* ]]; then
    echo "+ dans la liste"
else
    echo "- pas dans la liste"
fi