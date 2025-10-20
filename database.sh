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
