#!/bin/bash

# Template to use in your project.
# Add it in your project's root as mount_etna.sh and `chmod 750 mount_etna.sh`

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "----------------------------------- forged in Mount Etna ==> $SCRIPT_DIR -----------------------------------"
source "$SCRIPT_DIR"/forge/resources/shell/main.sh
echo "------------- Put all customization of forge between source it and call main function (erupt) --------------"

# Rewrote only functions starting with complement_ and put it between source main and call erupt.

erupt "$@"
