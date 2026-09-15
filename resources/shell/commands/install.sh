#!/bin/bash

# call it: clear; date; curl -fsSL your-git-raw.example.tld/install.sh | bash -s -- $HOME/universal/projects/${FORGE_ORG}/${FORGE_PROJECT} git@your-git.example.tld:your-org/project.git stage

FORGE_SYSTEM_ACRONYM=${1:-""}
FORGE_ORGANIZATION_ACRONYM=${2:-""}
GIT_BRANCH=${3:-"master"}
FORGE_SOURCE=${4:-"repos"}         # options: repos (do nothing) or upstream (force update to HEAD)
FORGE_ORGANIZATION_VAULT=${5:-"secrets"}

install_banner() {
	# Same as original print_banner helper function but lives here because all dependencies must live together and be accessible by one file.
    BANNER_MSG=$1
    CHARS_BANNER_MSG=${#BANNER_MSG}
    BORDER=$(printf -- '-%.0s' $(seq 1 $(($CHARS_BANNER_MSG))))
    echo ""
    echo "|+$BORDER+|"
    echo "| $BANNER_MSG |"
    echo "|+$BORDER+|"
    echo""
}

run() {
    # Get the project and install it for dev env
    # [MANDATORY] VAULT SECRETS IN PLACE (CENTRALIZED)..: Used to gather information about project. BEWARE that if not supplied it will be assumed $FORGE_ORGANIZATION_ACRONYM/secrets.
    # [MANDATORY] FORGE_SYSTEM_ACRONYM..................: To choose the project that will be installed.
    # [MANDATORY] FORGE_ORGANIZATION_ACRONYM............: To compose the default path of your app.
    # [OPTIONAL ] GIT_BRANCH............................: To choose wich branch will checkedout. Normally you can use [master | stage | dev | local].
    # [OPTIONAL ] FORGE_SOURCE..........................: Choose between 'upstream' (to force submodule forge in project target to be updated to HEAD of master) or 'repos' - or any other value - to use the forge as is.
    # [OPTIONAL ] FORGE_ORGANIZATION_VAULT..............: The custom url to vault, if needed. Is assumed that will live inside $HOME/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_ORGANIZATION_VAULT}.

    local PROJECT_DIR="${HOME}/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/${FORGE_SYSTEM_ACRONYM}"
	install_banner "[FORGE_INSTALL] VALIDATING PROJECT_DIR IN $PROJECT_DIR"
    if [[ -e "$PROJECT_DIR" ]];
    then
        echo "[FORGE_INSTALL] NOT GOING FUTHER: $PROJECT_DIR ALREADY exist!!"
        return 1
    fi

    local VAULT_PATH="$HOME/universal/projects/${FORGE_ORGANIZATION_ACRONYM}/secrets"
	install_banner "[FORGE_INSTALL] VALIDATING VAULT IN $VAULT_PATH"
	if [[ ! -d "$VAULT_PATH/code" ]];
	then
		(git clone "${FORGE_ORGANIZATION_VAULT}" "${VAULT_PATH}/code") >/dev/null 2>&1
	else
		(cd "$VAULT_PATH/code" && git pull) >/dev/null 2>&1
	fi

	# TODO move centralized vault to /usr/share or something more posix-friendly
    local MISE_EN_PLACE_ENCRYPTED_PATH="${VAULT_PATH}/code/encrypted/${FORGE_SYSTEM_ACRONYM}/.mise-en-place.conf.gpg"
	install_banner "[FORGE_INSTALL] VALIDATING MISE-EN-PLACE IN $MISE_EN_PLACE_ENCRYPTED_PATH"
    if [[ ! -f "${MISE_EN_PLACE_ENCRYPTED_PATH}" ]];
    then
        echo "[FORGE_INSTALL] NOT GOING FUTHER: MISSING mise en place configuration file in path ${MISE_EN_PLACE_ENCRYPTED_PATH}"
        return 1
    fi
    local VAULT_SENSIBLE_PATH="${VAULT_PATH}/.forge_workspace/original/${FORGE_SYSTEM_ACRONYM}"

	# clear; awk -F: '{print $1}' my_trust_backup.txt | while read -r fpr; do gpg -q --list-keys "$fpr" | grep 'uid'; done
	install_banner "[FORGE_INSTALL] SET PUBKEYS IN KEYRING && TRUSTDB..."
	find "${VAULT_PATH}/code/pubkeys" -type f -name "*.asc" | while read -r KEYFILE; do
		gpg --import "$KEYFILE" >/dev/null 2>&1
		KEY_ID=$(gpg --with-colons --show-keys "$KEYFILE" 2>/dev/null | awk -F: '$1=="fpr" {print $10; exit}')
		echo "[FORGE_INSTALL] Processing: $KEYFILE :: $KEY_ID"

		if [ -n "$KEY_ID" ]; then
			echo "${KEY_ID}:5:" | gpg --import-ownertrust
		else
			echo "[FORGE_INSTALL] Warning: Could not extract a valid Key ID from $KEYFILE"
		fi
	done
    mkdir -p "${VAULT_SENSIBLE_PATH}" && gpg -q --yes -o "${VAULT_SENSIBLE_PATH}/.mise-en-place.conf" -d $MISE_EN_PLACE_ENCRYPTED_PATH

	install_banner "[FORGE_INSTALL] CLONING THE PROJECT..."
    local FORGE_SYSTEM_BASE_DNS=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep FORGE_SYSTEM_BASE_DNS | cut -d = -f2)
    local GIT_PROTOCOL=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_PROTOCOL | cut -d = -f2)
    local GIT_BASE_URL=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_BASE_URL | cut -d = -f2)
    local GIT_USER=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_USER | cut -d = -f2)
    local GIT_REMOTE="${GIT_PROTOCOL}${GIT_USER}@${GIT_BASE_URL}/${FORGE_SYSTEM_BASE_DNS}.git"
    export GIT_PASSWORD=$(cat ${VAULT_SENSIBLE_PATH}/.mise-en-place.conf | grep GIT_PASSWORD | cut -d = -f2) # side-note: need to be availiable to sub-shell
	if [[ "$DEBUG" == "1" ]];
    then
		echo "FORGE_SYSTEM_BASE_DNS..: $FORGE_SYSTEM_BASE_DNS"
		echo "GIT_PROTOCOL...........: $GIT_PROTOCOL"
		echo "GIT_BASE_URL...........: $GIT_BASE_URL"
		echo "GIT_USER...............: $GIT_USER"
		echo "GIT_REMOTE.............: $GIT_REMOTE"
		echo "GIT_PASSWORD...........: $GIT_PASSWORD"
    fi
	mkdir -p "$PROJECT_DIR"
    git -c credential.helper='!f() { sleep 1; echo "password=${GIT_PASSWORD}"; }; f' clone -b ${GIT_BRANCH} --recurse-submodules $GIT_REMOTE "${PROJECT_DIR}/backend"
    cp "${VAULT_SENSIBLE_PATH}/.mise-en-place.conf" "${PROJECT_DIR}/backend/.credentials/.mise-en-place.conf"

    install_banner "----- Updating forge ('upstream' goes to HEAD from 'master'; 'repos' or any will be as is): $FORGE_SOURCE -----"
    [[ "$FORGE_SOURCE" == "upstream" ]] && cd $PROJECT_DIR/backend/forge && git pull origin master >/dev/null 2>&1
    cd $PROJECT_DIR/backend && source ${PROJECT_DIR}/backend/forge/main.sh
    install_banner "[FORGE_INSTALL] Erupt dev_terraform local on $(pwd) ..."
    erupt dev_terraform local

	return 0
}

echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"
echo "${FORGE_SYSTEM_ACRONYM} ${FORGE_ORGANIZATION_ACRONYM} ::: ${GIT_BRANCH} ${FORGE_SOURCE} ${FORGE_ORGANIZATION_VAULT}"
echo "--------------------------- forge-install.sh ==> $PROJECT_DIR ---------------------------"
[[ ! -z "$FORGE_SYSTEM_ACRONYM" && ! -z "$FORGE_ORGANIZATION_ACRONYM" ]] && run || echo "[FORGE_INSTALL] NOT EXECUTING: MANDATORY VARS MISSING OR SOMETHING GONE WRONG!!"
