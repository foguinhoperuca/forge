#!/bin/bash

# call it: clear; date; curl -fsSL your-git-raw.example.tld/install.sh | bash -s -- $HOME/universal/projects/${FORGE_ORG}/${FORGE_PROJECT} git@your-git.example.tld:your-org/project.git stage

FORGE_SYSTEM_ACRONYM=${1:-""}
FORGE_ORGANIZATION_ACRONYM=${2:-""}
GIT_BRANCH=${3:-"master"}
FORGE_ORGANIZATION_VAULT=${4:-"secrets"}
FORGE_SOURCE=${5:-"repos"}         # options: repos or upstream

echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"
echo "${FORGE_SYSTEM_ACRONYM} ${FORGE_ORGANIZATION_ACRONYM} ${GIT_BRANCH} ${FORGE_ORGANIZATION_VAULT}"
echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"

run() {
    # Get the project and install it for dev env
    # [MANDATORY] VAULT SECRETS IN PLACE (CENTRALIZED): Used to gather information about project. BEWARE that if not supplied it will be assumed $FORGE_ORGANIZATION_ACRONYM/secrets.
    # [MANDATORY] FORGE PROJECT IN PLACE (CENTRALIZED): Used to run main installation script.

    export PROJECT_DIR="${HOME}/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_SYSTEM_ACRONYM}"
    if [[ -e "$PROJECT_DIR" ]];
    then
        echo "NOT GOING FUTHER: $PROJECT_DIR ALREADY exist!!"
        return 1
    fi
    mkdir -p "$PROJECT_DIR"

    export MISE_EN_PLACE_ENCRYPTED_PATH="$HOME/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_ORGANIZATION_VAULT}/code/encrypted/${FORGE_SYSTEM_ACRONYM}/.mise-en-place.conf.gpg"
    if [[ ! -f "${MISE_EN_PLACE_ENCRYPTED_PATH}" ]];
    then
        echo "NOT GOING FUTHER: MISSING mise en place configuration file in path ${MISE_EN_PLACE_ENCRYPTED_PATH}"
        return 1
    fi
    export VAULT_SENSIBLE_PATH=$HOME/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_ORGANIZATION_VAULT}/.credentials_backup/original/${FORGE_SYSTEM_ACRONYM}
    mkdir -p "${VAULT_SENSIBLE_PATH}" && gpg --yes -o "${VAULT_SENSIBLE_PATH}/.mise-en-place.conf" -d $MISE_EN_PLACE_ENCRYPTED_PATH

    export FORGE_SYSTEM_BASE_DNS=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep FORGE_SYSTEM_BASE_DNS | cut -d = -f2)
    export GIT_PROTOCOL=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_PROTOCOL | cut -d = -f2)
    export GIT_BASE_URL=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_BASE_URL | cut -d = -f2)
    export GIT_USER=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_USER | cut -d = -f2)
    export GIT_PASSWORD=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_PASSWORD | cut -d = -f2)
    export GIT_REMOTE="${GIT_PROTOCOL}${GIT_USER}@${GIT_BASE_URL}/${FORGE_SYSTEM_BASE_DNS}.git"
    git -c credential.helper='!f() { sleep 1; echo "password=${GIT_PASSWORD}"; }; f' clone -b ${GIT_BRANCH} --recurse-submodules $GIT_REMOTE "${PROJECT_DIR}/backend"

    # TODO add all gpg keys in keyring -> ideas: export trust-file db and sign all keys
    cp "${VAULT_SENSIBLE_PATH}/.mise-en-place.conf" "${PROJECT_DIR}/backend/.credentials/.mise-en-place.conf"

    # TODO maybe each project has an outdated version of forge (same can occur with vault!!). Should it run from project (**YES** because dev_terraform use RELATIVE PATH (maybe can git pull before run instead using a variable to control it) - is it a real problem?!; **NO** because it always will be the latest but it can break the local project forcing a dependency) :: SHOULD DECIDE LATER AFTER THINK ABOUT IT - USE FORGE_SOURCE: [LOCAL_REPOS | CENTRAL | AND COME FROM EDGE_MASTER or NOT]
    echo "----- Updating forge: $FORGE_SOURCE -----"
    [[ "$FORGE_SOURCE" == "upstream" ]] && cd $PROJECT_DIR/backend/forge && git pull origin master
    cd $PROJECT_DIR/backend && source ${PROJECT_DIR}/backend/forge/main.sh
    print_banner "Erupt dev_terraform local on $(pwd) ..."
    erupt dev_terraform local
}

echo "(1) system acronym: ${FORGE_SYSTEM_ACRONYM} and (2) organization acronym: ${FORGE_ORGANIZATION_ACRONYM}. ALSO, FOUND GIT_BRANCH AS $GIT_BRANCH :: ALSO, FOUND FORGE_ORGANIZATION_VAULT AS $FORGE_ORGANIZATION_VAULT"
if [[ ! -z "$FORGE_SYSTEM_ACRONYM" && ! -z "$FORGE_ORGANIZATION_ACRONYM" ]];
then
    run
else
    echo "NOT EXECUTING: MANDATORY VARS MISSING!!"
fi
