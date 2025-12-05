#!/bin/bash

# TODO replace storage_sistemas by $FORGE_ORGANIZATION_ACRONYM
verify_mounted_path_online() {
    path=$1
    env=$2

    if [ -z $1 ];
    then
        path=$FORGE_SYSTEM_BASE_DNS
    fi

    if [ -z $2 ];
    then
        env=$TARGET_ENV
    fi

    echo ""
    echo "---------------------------------------------------------------"
    echo "[$NOW] Validating mounted path for $1 ($path) and env $2 ($env)"
    echo "---------------------------------------------------------------"
    echo ""
    mounted=$(df -h | grep $path | grep $env)
    if [ $? -eq 0 ];
    then
        echo "System is already mounted"
        echo "..."
        df -h
    else
        echo "Failed to find if system is mounted. Trying again."
        echo "mount /mnt/storage_sistemas/$path-$env"
        mount /mnt/storage_sistemas/$path-$env

        echo "df -h | grep $path | grep $env"
        df -h | grep $path | grep $env
        echo "---"
        df -h
    fi
}
