#!/bin/bash

# Reusable vars in scripts.
# Should be replaced by VAR+=VAR or re-declared in forge.sh

NOW=$(date +"%Y-%m-%dT%H-%M-%S")

# TODO migrate vars to use system ACRONYM in start?!
CUSTOM_VARS_FRAGMENT="FORGE_SYSTEM|TARGET_|GIT_|APP_PATH|PGPASSFILE|DB_|DJANGO|AUTHORIZATION|DEPLOYMENT"

# FIXME hard codedd adc here. Shoul use APP_PATH - but if no env var is loaded?!
# /opt/adc/backend/bare.git/hooks/.* /opt/adc/backend/bare.git/hooks/*"
CONF_FILES=".target-server .pgpass .mise-en-place.conf api/.env bot/.env backoffice/.env bot/.env git-hooks/.mise-en-place.conf git-hooks/forge.sh"

declare -a SYMBOLIC_LINK_FILES=(
    ".pgpass"
    ".target-server"
    "api/.env"
    "backoffice/.env"
    "bot/.env"
)

# FIXME upstream and edge should be considered as env or just folder in worktree? Should separate git checkout worktree (local | dev | stage | prod) from full git repos (upstream | edge)
declare -a ENVS_AVAILABLE=(
    "local"
    "dev"
    "stage"
    "prod"
    "upstream"
    "edge"
)

# TODO use it!
declare -a WORKFLOW_ENVS_AVAILABLE=(
	"local"
    "dev"
    "stage"
    "prod"
)

declare -a PYTHON_PROJECTS_AVAILABLE=(
    "api"
    "backoffice"
    "bot"
)

declare -a DJANGO_PROJECTS_AVAILABLE=(
    "backoffice"
    "api"
)

# This should be replaced by a fully declare statement
declare -a DJANGO_MEDIA_FILE_AVAILABLE=(
    "REPLACE_IT__some_folder_for_save_media__REPLACE_IT"
    "REPLACE_IT__another_folder_for_save_media__REPLACE_IT"
)
