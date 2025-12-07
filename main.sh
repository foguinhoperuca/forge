#!/bin/bash

# FORGE_PATH=$(dirname $0)
export FORGE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Setted FORGE_PATH to $FORGE_PATH"
if [[ "$FORGE_PATH" == "." ]];
then
    export FORGE_PATH="$FORGE_PATH/forge"
    echo "Setted FORGE_PATH to $FORGE_PATH **INSTEAD OF** ."
fi

source $FORGE_PATH/var.sh
source $FORGE_PATH/env.sh
source $FORGE_PATH/database.sh
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
		echo "${WORKFLOW_ENVS_AVAILABLE[@]}"
		for ENV_TRG in ${ENVS_AVAILABLE[@]};
		do
			# if [[ "$2" == ${WORKFLOW_ENVS_AVAILABLE[@]} ]];
			if [[ "$2" == @(local|dev|stage|prod) ]];
			then
				echo "IS VALID ENV ::: $2"
				# generate_conf_file $2
				break
			fi

<<<<<<< Updated upstream
			if [[ "$ENV_TRG" != @(edge|upstream) && "$2" == @(all|ALL) ]];
			then
				echo ""
				echo "************************************"
				echo "|| Genereting env files for $ENV_TRG"
				echo "************************************"
				echo ""
				# generate_conf_file $ENV_TRG
			fi
		done
        ;;
    # "githook") githook $2 $3 $4;;
    "deploy") deploy;;
    "terraform")
        terraform $2
        ;;
    "is_mounted") verify_mounted_path_online $2 $3;;
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
        case $3 in
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
    "set_symbolic_link") set_symbolic_link;; # FIXME temp only to test
    *)
        # TODO better usage message
        echo "-----------"
        echo "[FORGE] $(dirname $0)"
        echo "[FORGE] $FORGE_PATH"
        echo "-----------"
||||||| Stash base
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
		    cp_secrets $2
		    ;;
        # "githook") githook $2 $3 $4;;
        "deploy")
		    deploy
		    ;;
        "etc_terraform") terraform_app_path_etc;;
        "apache_terraform") terraform_app_path_var_www_app;;
        "terraform")
            terraform $2
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
            case $3 in
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
=======
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
		    cp_secrets $2
		    ;;
		"encrypt_multiple")
			encrypt_multiple;;
        # "githook") githook $2 $3 $4;;
        "deploy")
		    deploy
		    ;;
        "etc_terraform") terraform_app_path_etc;;
        "apache_terraform") terraform_app_path_var_www_app;;
        "terraform")
            terraform $2
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
            case $3 in
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
>>>>>>> Stashed changes

        echo "USAGE: [show | unenv | env | githook | terraform]. $1 *NOT* found!!"
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
esac
