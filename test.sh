PAQUET="prout,docker*,youpi"
BLACKLIST="prout,docker*,youpi"
if [ "$PAQUET" != "$BLACKLIST" ]; then
    echo "pas dans la liste"
else
    echo "dans la liste"
fi