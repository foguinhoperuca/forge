#!/bin/bash

# Template to use in your project.
# Add it in your project's root as mount_etna.sh and `chmod 750 mount_etna.sh`

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


echo "--------------------------- forged in Mount Etna ==> $SCRIPT_DIR ---------------------------"
source "$SCRIPT_DIR"/forge/resources/shell/main.sh
echo "--------------------------- forged in Mount Etna ==> $SCRIPT_DIR ---------------------------"

# Put all customization of forge between source it and call main function (erupt). Rewrote only functions with complement_ in the start of name

erupt "$@"
