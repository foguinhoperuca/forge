#!/bin/bash

# call it: clear; date; curl -fsSL your-git-raw.example.tld/install.sh | bash -s -- $HOME/universal/projects/${FORGE_ORG}/${FORGE_PROJECT} git@your-git.example.tld:your-org/project.git stage

export FORGE_SYSTEM_ACRONYM=${1:-""}
export FORGE_ORGANIZATION_ACRONYM=${2:-""}
export GIT_BRANCH=${3:-"master"}
export FORGE_ORGANIZATION_VAULT=${4:-"secrets"}


echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"
echo "${FORGE_SYSTEM_ACRONYM} ${FORGE_ORGANIZATION_ACRONYM} ${GIT_BRANCH} ${FORGE_ORGANIZATION_VAULT}"
echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"

run() {
    export PROJECT_DIR="${HOME}/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_SYSTEM_ACRONYM}"
    if [[ -e "$PROJECT_DIR" ]];
    then
        echo "Not going futher: $PROJECT_DIR ALREADY exist!!"
        return 1
    fi
    mkdir -p "$PROJECT_DIR"

    export MISE_EN_PLACE_PATH="$HOME/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/secrets/code/encrypted/${FORGE_SYSTEM_ACRONYM}/.mise-en-place.conf.gpg"
    if [[ -f "${MISE_EN_PLACE_PATH}" ]];
    then
        echo "Not going futher: MISSING mise en place configuration file in path ${MISE_EN_PLACE_PATH}"
        return 1
    fi
    export DEPLOYMENT_PATH=$HOME/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/secrets/.credentials_backup/original/${FORGE_SYSTEM_ACRONYM}
    mkdir -p "${DEPLOYMENT_PATH}" && gpg --yes -o "${DEPLOYMENT_PATH}/.mise-en-place.conf" -d $MISE_EN_PLACE_PATH

    export FORGE_SYSTEM_BASE_DNS=$(cat $DEPLOYMENT_FILE | grep FORGE_SYSTEM_BASE_DNS | cut -d = -f2)
    export GIT_PROTOCOL=$(cat $DEPLOYMENT_FILE | grep GIT_PROTOCOL | cut -d = -f2)
    export GIT_BASE_URL=$(cat $DEPLOYMENT_FILE | grep GIT_BASE_URL | cut -d = -f2)
    export GIT_USER=$(cat $DEPLOYMENT_FILE | grep GIT_USER | cut -d = -f2)
    export GIT_PASSWORD=$(cat $DEPLOYMENT_FILE | grep GIT_PASSWORD | cut -d = -f2)
    export GIT_REMOTE="${GIT_PROTOCOL}${GIT_USER}@${GIT_BASE_URL}/${FORGE_SYSTEM_BASE_DNS}.git"
    git clone -b ${GIT_BRANCH} --recurse-submodules $GIT_REMOTE "${PROJECT_DIR}/backend"

    # TODO add all gpg keys in keyring -> ideas: export trust-file db and sign all keys
    cp "${MISE_EN_PLACE_PATH}" "${PROJECT_DIR}/backend/.credentials/.mise-en-place.conf"

    cd $PROJECT_DIR/backend && pwd
    source ${PROJECT_DIR}/backend/forge/main.sh
    erupt dev_terraform local
}

if [[ ! -z "$FORGE_SYSTEM_ACRONYM" && ! -z "$FORGE_ORGANIZATION_ACRONYM" ]];
then
    run
else
    echo "NOT EXECUTING: MANDATORY VARS MISSING --> (1) system acronym: ${FORGE_SYSTEM_ACRONYM} and (2) organization acronym: ${FORGE_ORGANIZATION_ACRONYM}. ALSO, FOUND GIT_BRANCH AS $GIT_BRANCH"
fi
