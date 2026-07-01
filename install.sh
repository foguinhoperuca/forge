#!/bin/bash

# call it: clear; date; curl -fsSL your-git-raw.example.tld/install.sh | bash -s -- $HOME/universal/projects/${FORGE_ORG}/${FORGE_PROJECT} git@your-git.example.tld:your-org/project.git stage

FORGE_SYSTEM_ACRONYM=${1:-""}
FORGE_ORGANIZATION_ACRONYM=${2:-""}
GIT_BRANCH=${3:-"master"}
FORGE_SOURCE=${4:-"repos"}         # options: repos (do nothing) or upstream (force update to HEAD)
FORGE_ORGANIZATION_VAULT=${5:-"secrets"}

echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"
echo "${FORGE_SYSTEM_ACRONYM} ${FORGE_ORGANIZATION_ACRONYM} ${GIT_BRANCH} ${FORGE_ORGANIZATION_VAULT}"
echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"

run() {
    # Get the project and install it for dev env
    # [MANDATORY] VAULT SECRETS IN PLACE (CENTRALIZED)..: Used to gather information about project. BEWARE that if not supplied it will be assumed $FORGE_ORGANIZATION_ACRONYM/secrets.
    # [MANDATORY] FORGE_SYSTEM_ACRONYM..................: To choose the project that will be installed.
    # [MANDATORY] FORGE_ORGANIZATION_ACRONYM............: To compose the default path of your app.
    # [OPTIONAL ] GIT_BRANCH............................: To choose wich branch will checkedout. Normally you can use [master | stage | dev | local].
    # [OPTIONAL ] FORGE_ORGANIZATION_VAULT..............: The custom path to vault. Is assumed that will live inside $HOME/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_ORGANIZATION_VAULT}.
    # [OPTIONAL ] FORGE_SOURCE..........................: Choose between 'upstream' (to force submodule forge in project target to be updated to HEAD of master) or 'repos' - or any other value - to use the forge as is.

    PROJECT_DIR="${HOME}/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_SYSTEM_ACRONYM}"
    if [[ -e "$PROJECT_DIR" ]];
    then
        echo "NOT GOING FUTHER: $PROJECT_DIR ALREADY exist!!"
        return 1
    fi
    mkdir -p "$PROJECT_DIR"

    # TODO move centralized vault to /usr/share or something more posix-friendly. Also, give the ability to download it if necessary
    export MISE_EN_PLACE_ENCRYPTED_PATH="$HOME/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_ORGANIZATION_VAULT}/code/encrypted/${FORGE_SYSTEM_ACRONYM}/.mise-en-place.conf.gpg"
    if [[ ! -f "${MISE_EN_PLACE_ENCRYPTED_PATH}" ]];
    then
        echo "NOT GOING FUTHER: MISSING mise en place configuration file in path ${MISE_EN_PLACE_ENCRYPTED_PATH}"
        return 1
    fi
    export VAULT_SENSIBLE_PATH=$HOME/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_ORGANIZATION_VAULT}/.credentials_backup/original/${FORGE_SYSTEM_ACRONYM}
    mkdir -p "${VAULT_SENSIBLE_PATH}" && gpg --yes -o "${VAULT_SENSIBLE_PATH}/.mise-en-place.conf" -d $MISE_EN_PLACE_ENCRYPTED_PATH

    FORGE_SYSTEM_BASE_DNS=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep FORGE_SYSTEM_BASE_DNS | cut -d = -f2)
    GIT_PROTOCOL=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_PROTOCOL | cut -d = -f2)
    GIT_BASE_URL=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_BASE_URL | cut -d = -f2)
    GIT_USER=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_USER | cut -d = -f2)
    GIT_PASSWORD=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_PASSWORD | cut -d = -f2)
    GIT_REMOTE="${GIT_PROTOCOL}${GIT_USER}@${GIT_BASE_URL}/${FORGE_SYSTEM_BASE_DNS}.git"
    git -c credential.helper='!f() { sleep 1; echo "password=${GIT_PASSWORD}"; }; f' clone -b ${GIT_BRANCH} --recurse-submodules $GIT_REMOTE "${PROJECT_DIR}/backend"

    # TODO add all gpg keys in keyring -> ideas: export trust-file db and sign all keys
    cp "${VAULT_SENSIBLE_PATH}/.mise-en-place.conf" "${PROJECT_DIR}/backend/.credentials/.mise-en-place.conf"

    echo "----- Updating forge (The value 'upstream' will update repository to HEAD from 'master'; 'repos' or any other value stay as is checked out): $FORGE_SOURCE -----"
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
