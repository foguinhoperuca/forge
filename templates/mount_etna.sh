#!/bin/bash

# Template to use in your project.
# Add it in your project's root as mount_etna.sh and `chmod 750 mount_etna.sh`

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "--------------------------- forged in Mount Etna ==> $SCRIPT_DIR ---------------------------"
source $SCRIPT_DIR/forge/main.sh
echo "--------------------------- forged in Mount Etna ==> $SCRIPT_DIR ---------------------------"

# Put all customization of forge before call it

main $@
