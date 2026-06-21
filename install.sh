#!/bin/bash

# call it: clear; date; curl -fsSL your-git-raw.example.tld/install.sh | bash -s -- $HOME/universal/projects/${FORGE_ORG}/${FORGE_PROJECT} git@your-git.example.tld:your-org/project.git

export PROJECT_DIR=${1:-"$HOME/universal/projects/${FORGE_ORG}/${FORGE_PROJECT}"}
export GIT_REMOTE=${2:-""}
echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"
echo "PROJECT_DIR is ${PROJECT_DIR}"
echo "GIT_REMOTE is ${GIT_REMOTE}"
echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"

# # FIXME use with care rm - test if dir exist!!
# rm -r "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
git clone --recurse-submodules $GIT_REMOTE "${PROJECT_DIR}/backend"

# TODO add all gpg keys in keyring
gpg --yes -o "${PROJECT_DIR}/backend/.credentials/.mise-en-place.conf" -d "${PROJECT_DIR}/backend/.credentials/secure/.mise-en-place.conf.gpg"

cd $PROJECT_DIR/backend && pwd
source ${PROJECT_DIR}/backend/forge/main.sh
erupt dev_terraform local
