#!/bin/bash

db_script() {
    local DBHOST=$1
    local DBPORT=$2
    local DBDATABASE=$3
    local DBUSER=$4
    local DBSCRIPT=$5
    local FORGESYSPATH
	FORGESYSPATH=$(pwd)

    print_banner "[FORGE] db vars: forgesyspath=$FORGESYSPATH -h $DBHOST -p $DBPORT -d $DBDATABASE -U $DBUSER -f $DBSCRIPT"
    psql -v forgesyspath="$FORGESYSPATH" -h "$DBHOST" -p "$DBPORT" -d "$DBDATABASE" -U "$DBUSER" -f "$DBSCRIPT"
}

db_backup_full() {
    # TODO fully implement it
    echo "Backup full postgres from database $1"
    pg_dump -U "$PGUSER" -d "$1" -F c -f "${BACKUP_PATH}/full_${NOW}.bkp"
}

db_backup_partial() {
    # $1 :: database
    # $2 :: schema
    echo "TODO implement a partial backup by schema"
}

# TODO implement backup incremental between daily backup full - keep 2 day of uincremental (backup full can be corrupted)
