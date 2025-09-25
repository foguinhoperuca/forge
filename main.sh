#!/bin/bash

FORGE_PATH=$(dirname $0)
if [[ "$FORGE_PATH" == "." ]];
then
    FORGE_PATH="$FORGE_PATH/forge"
fi

source $FORGE_PATH/var.sh
source $FORGE_PATH/env.sh
source $FORGE_PATH/deployment.sh
source $FORGE_PATH/monitoring.sh

# TODO implement bash completation
case $1 in
    "show")
        clear
        show_env $2
        ;;
    "unenv")
        unset_symbolic_link
        unset_vars
        show_env $2
        ;;
    "env") export_env $2 $3 $4;;
    # "deploy") deploy;;
    # "githook") githook $2 $3 $4;;
    "terraform")
        terraform $2
        ;;
    "set_symbolic_link") set_symbolic_link;; # FIXME temp only to test
    "is_mounted") verify_mounted_path_online $2 $3;;
    *)
        # TODO better usage message
        echo "-----------"
        echo "[FORGE] $(dirname $0)"
        echo "[FORGE] $FORGE_PATH"
        echo "-----------"

        echo "USAGE: [show | unenv | env | githook | terraform]. $1 *NOT* found!!"
        echo "- show [PWD | \"\"]"
        echo "- unenv"
        echo "- env [local | dev | stage | prod] <OPTIONAL_GIT_REPOS> <OPTIONAL_GIT_BRANCH>. GIT_REPOS default is backend; GIT_BRANCH default is same as TARGET_ENV: (now is $TARGET_ENV)."
        # echo "- deploy"
        # echo "- githook - only used by post-receive script"
        # echo "- terraform - prepare devops"
        echo "- is_mounted - validate if mount point is online"
esac
