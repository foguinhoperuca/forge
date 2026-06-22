#!/bin/bash

# call it: clear; date; curl -fsSL your-git-raw.example.tld/install.sh | bash -s -- $HOME/universal/projects/${FORGE_ORG}/${FORGE_PROJECT} git@your-git.example.tld:your-org/project.git stage

export PROJECT_DIR=${1:-"$HOME/universal/projects/${FORGE_ORG}/${FORGE_PROJECT}"}
export GIT_REMOTE=${2:-""}
export GIT_BRANCH=${3:-"master"}
echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"
echo "PROJECT_DIR is ${PROJECT_DIR} :: ${FORGE_ORG} ${FORGE_PROJECT}"
echo "GIT_REMOTE is ${GIT_REMOTE} GIT_BRANCH is ${GIT_BRANCH}"
echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"

# # FIXME use with care rm - test if dir exist!!
# rm -r "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
git clone -b ${GIT_BRANCH} --recurse-submodules $GIT_REMOTE "${PROJECT_DIR}/backend"

# TODO add all gpg keys in keyring -> ideas: export trust-file db and sign all keys
gpg --yes -o "${PROJECT_DIR}/backend/.credentials/.mise-en-place.conf" -d "${PROJECT_DIR}/backend/.credentials/secure/.mise-en-place.conf.gpg"

cd $PROJECT_DIR/backend && pwd
source ${PROJECT_DIR}/backend/forge/main.sh
erupt dev_terraform local
