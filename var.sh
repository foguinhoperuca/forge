#!/bin/bash

NOW=$(date +"%Y-%m-%dT%H-%M-%S")

# TODO migrate vars to use system ACRONYM in start?!
CUSTOM_VARS_FRAGMENT="PMS_SYSTEM|TARGET_|GIT_|APP_PATH|PGPASSFILE|DB_|DJANGO|AUTHORIZATION|DEPLOYMENT"

declare -a SYMBOLIC_LINK_FILES=(
    ".target-server"
    ".pgpass"
    "backoffice/.env"
    "bot/.env"
)


# FIXME upstream and edge should be considered as env or just folder in worktree? Should separate git checkout worktree (lcoal | dev |Z stage | prod) from full git repos (upstream | edge)
declare -a ENVS_AVAILABLE=(
    "local"
    "dev"
    "stage"
    "prod"
    "upstream"
    "edge"
)

declare -a PYTHON_PROJECTS_AVAILABLE=(
    "backoffice"
    "bot"
)

declare -a DJANGO_MEDIA_FILE_AVAILABLE=(
    "pedido_ajuda"
    "photo_guia_atendimento"
)
