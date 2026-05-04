#!/bin/bash

export FORGE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Setted FORGE_PATH to $FORGE_PATH"
if [[ "$FORGE_PATH" == "." ]];
then
    export FORGE_PATH="$FORGE_PATH/forge"
    echo "Setted FORGE_PATH to $FORGE_PATH **INSTEAD OF** ."
fi

source $FORGE_PATH/var.sh
source $FORGE_PATH/utils.sh
source $FORGE_PATH/env.sh
source $FORGE_PATH/database.sh
source $FORGE_PATH/deployment.sh
source $FORGE_PATH/monitoring.sh

# TODO use _forge inside mount_etna.sh to add custom completion
_forge_completation() {
    local cur prev opts

    COMPREPLY=()

    # cur=${COMP_WORDS[COMP_CWORD]}
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    cmd="${COMP_WORDS[1]}"
    opts="option1 option2 --help --version"

    local commands="show unenv env genenv cp-secrets encrypt_multiple python_deploy deploy etc_terraform apache_terraform terraform genesis is_mounted db_script db_backup"

    COMPREPLY=($(compgen -W "${commands}"))
}
complete -F _forge_completation erupt

# TODO remove it - rename all calls to mount_etna function
main() {
    erupt $@
}

erupt() {
    case $1 in
        "show")
            clear
            show_env $2 $3
            ;;
        "unenv")
            unset_symbolic_link
            unset_vars
            show_env $2
            ;;
        "env")
            case $2 in
                "local" | "dev" | "stage" | "prod")
                    unset_vars
                    set_vars $2 "$3" "$4"
                    set_vars_by_env
                    set_symbolic_link
                    show_env "PWD"
                    ;;
                *)
                    echo "ENV USAGE: [local | dev | stage | prod]. $1 *NOT* found!!"
                    ;;
            esac
            ;;
        "genenv")
		    # TODO use var WORKFLOW_ENVS_AVAILABLE in code bellow
		    # echo "${WORKFLOW_ENVS_AVAILABLE[@]}"
		    for ENV_TRG in ${ENVS_AVAILABLE[@]};
		    do
			    # if [[ "$2" == ${WORKFLOW_ENVS_AVAILABLE[@]} ]];
			    if [[ "$2" == @(local|dev|stage|prod) ]];
			    then
				    echo ""
				    echo "************************************"
				    echo "|| Genereting env for valid: $2"
				    echo "************************************"
				    echo ""
				    generate_conf_file $2 $3
				    break
			    fi

			    if [[ "$ENV_TRG" != @(edge|upstream) && "$2" == @(all|ALL) ]];
			    then
				    echo ""
				    echo "************************************"
				    echo "|| Genereting env files for $ENV_TRG"
				    echo "************************************"
				    echo ""
				    generate_conf_file $ENV_TRG $3
			    fi
		    done
            ;;
	    "cp-secrets")
		    cp_secrets $2 $3
		    ;;
		"encrypt_multiple")
			encrypt_multiple;;
        # "githook") githook $2 $3 $4;;
        "python_deploy")
            deploy_venv
            deploy_collectstatic
            ;;
        "deploy")
		    deploy
		    ;;
        "etc_terraform") terraform_app_path_etc;;
        "apache_terraform") terraform_app_path_var_www_app;;
        "terraform")
            terraform $2
            ;;
        "genesis")
            genesis
            ;;
        "is_mounted")
		    verify_mounted_path_online $2 $3
		    ;;
        "db_script")
            case $3 in
                "admin" | "adm")
                    db_script "$DB_ADMIN_HOST" "$DB_ADMIN_PORT" "$DB_ADMIN_DATABASE" "$DB_ADMIN_USER" $2
                    ;;
                *)
                    db_script "$DB_HOST" "$DB_PORT" "$DB_DATABASE" "$DB_USER" $2
                    ;;
            esac
            ;;
        "db_backup")
            case $2 in
                "full")
                    db_backup_full $DB_DATABASE
                    ;;
                "partial")
                    db_backup_partial $DB_DATABASE $DB_USER
                    ;;
                *)
                    echo "No backup was recognized: $3"
                    ;;
            esac
            ;;
        *)
            # TODO better usage message
            echo "-----------"
            echo "[FORGE] $(dirname $0)"
            echo "[FORGE] $FORGE_PATH"
            echo "-----------"

            echo "[FORGE] USAGE: [show | unenv | env | githook | terraform]. $1 *NOT* found!!"
            echo "- show [PWD | \"\"]"
            echo "- unenv"
            echo "- env [local | dev | stage | prod] <OPTIONAL_GIT_REPOS> <OPTIONAL_GIT_BRANCH>. GIT_REPOS default is backend; GIT_BRANCH default is same as TARGET_ENV: (now is $TARGET_ENV)."
            echo "- genenv [local | dev | stage | prod | all]"
            # echo "- githook - only used by post-receive script"
            echo "- deploy"
            echo "- terraform - prepare devops"
            echo "- is_mounted - validate if mount point is online"
            echo "- db_script <DB_SCRIPT> [admin|adm|""] - execute <DB_SCRIPT> as admin or not"
            echo "- db_backup_full - create a backup full from database"
            # return 1 # FIXME should return an error here?!
    esac

    return 0
}
