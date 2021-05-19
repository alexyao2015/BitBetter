#!/bin/bash

yq() {
  docker run --rm -i -v "${PWD}:/workdir" mikefarah/yq:4 "$@"
}

# Default path is the current directory of the BitBetter script
SCRIPT_BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BW_VERSION="$(curl --silent https://raw.githubusercontent.com/bitwarden/server/master/scripts/bitwarden.sh | grep 'COREVERSION="' | sed 's/^[^"]*"//; s/".*//')"

echo "Starting Bitwarden update, newest server version: $BW_VERSION"

# Get Bitwarden base from user (or keep default value)
read -e -rp "Enter Bitwarden base directory [$SCRIPT_BASE]: " tmpbase
SCRIPT_BASE=${tmpbase:-$SCRIPT_BASE}

# Check if directory exists and is valid
[ -d "$SCRIPT_BASE" ] || { echo "Bitwarden base directory $SCRIPT_BASE not found!"; exit 1; }
[ -f "$SCRIPT_BASE/bitwarden.sh" ] || { echo "Bitwarden base directory $SCRIPT_BASE is not valid!"; exit 1; }

# Check if user wants to recreate the docker-compose override file
RECREATE_OV="y"
read -p "Rebuild docker-compose override? [Y/n]: " tmprecreate
RECREATE_OV=${tmprecreate:-$RECREATE_OV}

if [[ $RECREATE_OV =~ ^[Yy]$ ]]
then
    yq -i eval "version = '3'" $SCRIPT_BASE/bwdata/docker/docker-compose.override.yml
    yq -i eval "services.api.image = 'ghcr.io/alexyao2015/bitbetter:api-$BW_VERSION'" $SCRIPT_BASE/bwdata/docker/docker-compose.override.yml
    yq -i eval "services.identity.image = 'ghcr.io/alexyao2015/bitbetter:identity-$BW_VERSION'"
    echo "BitBetter docker-compose override updated!"
else
    echo "Make sure to check if the docker override contains the correct image version ($BW_VERSION) in $SCRIPT_BASE/bwdata/docker/docker-compose.override.yml!"
fi

# Now start the bitwarden update
cd $SCRIPT_BASE

./bitwarden.sh updateself

./bitwarden.sh update

cd $SCRIPT_BASE
echo "Bitwarden update completed!"
