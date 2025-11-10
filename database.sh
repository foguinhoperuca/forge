#!/bin/bash

db_script() {
    DBHOST=$1
    DBPORT=$2
    DBDATABASE=$3
    DBUSER=$4
    DBSCRIPT=$5
    FORGESYSPATH=$(pwd)

    echo "[FORGE] db vars: forgesyspath=$FORGESYSPATH -h $DBHOST -p $DBPORT -d $DBDATABASE -U $DBUSER -f $DBSCRIPT"
    psql -v forgesyspath=$FORGESYSPATH -h $DBHOST -p $DBPORT -d $DBDATABASE -U $DBUSER -f $DBSCRIPT
}

db_backup_full() {
    # TODO fully implement it
    echo "Backup full postgres from database $1"
    pg_dump -U $PGUSER -d $1 -F c -f "${BACKUP_PATH}/full_${NOW}.bkp"
}

db_backup_partial() {
    # $1 :: database
    # $2 :: schema
    echo "TODO implement a partial backup by schema"
}

# TODO implement backup incremental between daily backup full - keep 2 day of uincremental (backup full can be corrupted)
