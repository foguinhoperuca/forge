#!/bin/bash

unset_vars() {
    # for var in $(env | sort | grep -E "(PMS_SYSTEM|TARGET_|GIT_|APP_PATH|PGPASSFILE|DB_|DJANGO|AUTHORIZATION|DEPLOYMENT)" | cut -d = -f1);
    for var in $(env | sort | grep -E "(${CUSTOM_VARS_FRAGMENT})" | cut -d = -f1);
    do
        unset $var
    done
}

set_vars() {
    # [MANDATORY] $1 :: define main TARGET_ENV
    # [OPTIONAL]  $2 :: define GIT_REPOS different from default
    # [OPTIONAL]  $3 :: define GIT_BRANCH different from default

    # PROJECT specific variables
    DEPLOYMENT_FILE=$(dirname $0)/.credentials/.mise-en-place.conf
    export PMS_SYSTEM_ACRONYM=$(cat $DEPLOYMENT_FILE | grep PMS_SYSTEM_ACRONYM | cut -d = -f2)
    export PMS_SYSTEM_BASE_DNS=$(cat $DEPLOYMENT_FILE | grep PMS_SYSTEM_BASE_DNS | cut -d = -f2)
    # FIXME [REVIEW IT!!] PMS_SYSTEM_NAME is used only in terraform.sql (search for more uses!!) - can be replaced by PMS_SYSTEM_ACRONYM?!
    export PMS_SYSTEM_NAME="$(echo $PMS_SYSTEM_BASE_DNS | sed -e s/\-/\_/g)"

    export APP_PATH="/opt/river" # FIXME remove it!
    
    # Bare minimum for GIT repository
    if [ "$2" == "" ];
    then
        export GIT_REPOS="backend"
    else
        export GIT_REPOS=$2
    fi
    # FIXME APP_PATH_ORIGIN_EDGE shouldn't be $HOME but /home/$TARGET_SERVER_USER/
    export APP_PATH_ORIGIN_EDGE="${HOME}/universal/projects/pms/${PMS_SYSTEM_ACRONYM}/$GIT_REPOS"
    export APP_PATH_ETC="/etc/${PMS_SYSTEM_ACRONYM}"
    export APP_PATH_VAR_WWW="/var/www/${PMS_SYSTEM_BASE_DNS}"
    export APP_PATH_MNT="/mnt/storage_sistemas/${PMS_SYSTEM_BASE_DNS}" # FIXME use BASE_DNS or SYSTEM_ACRONYM !?
    export APP_PATH_OPT="/opt/${PMS_SYSTEM_ACRONYM}/${GIT_REPOS}"
    export APP_PATH_BARE="$APP_PATH_OPT/bare.git"
    export APP_PATH_WORKTREE="$APP_PATH_OPT/worktree"
    export APP_PATH_DOCUMENT_ROOT="$APP_PATH_WORKTREE/document_root"
    export APP_PATH_UPSTREAM="$APP_PATH_WORKTREE/upstream"

    # ENVIRONMENT specific variables
    case $1 in
        "local" | "dev" | "stage" | "prod")
            export TARGET_ENV=$1
            if [ "$3" == "" ];
            then
                if [ "$1" == "prod" ];
                then
                    export GIT_BRANCH="master"
                else
                    export GIT_BRANCH=$1
                fi
            else
                export GIT_BRANCH=$3
            fi
            ;;
        *)
            # TODO TARGET_ENV should use DEFAULT_TARGET_ENV from .mise-en-place
            export TARGET_ENV=$(ls -lah .pgpass | cut -d " " -f12 | cut -d . -f3) # if not setted
            export GIT_BRANCH=$TARGET_ENV
            echo "ENV USAGE: [local | dev | stage | prod]. $1 *NOT* found!! Using already setted!"
            ;;
    esac
    echo ""
    echo "[SET ENV] You choosed $1 parameters TARGET_ENV: $1 :: GIT_REPOS: $2 :: GIT_BRANCH: $3 :: INTERRUPTS: $4 ::: result is TARGET_ENV=$TARGET_ENV ::: GIT_BRANCH=$GIT_BRANCH"
    
    # FIXME This part depends from set_symbolic_link. Should be there?
    if [[ "$4" != "INTERRUPTS" ]];
    then
        set_vars_from_conf
    fi
}

set_vars_from_conf() {
    # TODO use APP_PATH_ETC instead of $APP_PATH_ETC/
    export PGPASSFILE=$APP_PATH_ETC/.pgpass.$TARGET_ENV
    export DB_HOST=$(cat $PGPASSFILE | cut -d : -f1 | sed -n '1,1p')
    export DB_PORT=$(cat $PGPASSFILE | cut -d : -f2 | sed -n '1,1p')
    export DB_DATABASE=$(cat $PGPASSFILE | cut -d : -f3 | sed -n '1,1p')
    export DB_USER=$(cat $PGPASSFILE | cut -d : -f4 | sed -n '1,1p')
    export DB_PASS=$(cat $PGPASSFILE | cut -d : -f5 | sed -n '1,1p')
    export DB_ADMIN_HOST=$(cat $PGPASSFILE | cut -d : -f1 | sed -n '2,2p')
    export DB_ADMIN_PORT=$(cat $PGPASSFILE | cut -d : -f2 | sed -n '2,2p')
    export DB_ADMIN_DATABASE=$(cat $PGPASSFILE | cut -d : -f3 | sed -n '2,2p')
    export DB_ADMIN_USER=$(cat $PGPASSFILE | cut -d : -f4 | sed -n '2,2p')
    export DB_ADMIN_PASS=$(cat $PGPASSFILE | cut -d : -f5 | sed -n '2,2p')

    export STR_DJANGO_ADMIN_PASS=$APP_PATH_ETC/.env.backoffice.$TARGET_ENV
    export DJANGO_SUPERUSER_USERNAME=$(cat $STR_DJANGO_ADMIN_PASS | grep DJANGO_SUPERUSER_USERNAME | cut -d = -f2)
    export DJANGO_SUPERUSER_PASSWORD=$(cat $STR_DJANGO_ADMIN_PASS | grep DJANGO_SUPERUSER_PASSWORD | cut -d = -f2)
    export DJANGO_SUPERUSER_EMAIL=$(cat $STR_DJANGO_ADMIN_PASS | grep DJANGO_SUPERUSER_EMAIL | cut -d = -f2)
    export DJANGO_SUPERUSER_FIRSTNAME=$(cat $STR_DJANGO_ADMIN_PASS | grep DJANGO_SUPERUSER_FIRSTNAME | cut -d = -f2)
    export DJANGO_SUPERUSER_LASTNAME=$(cat $STR_DJANGO_ADMIN_PASS | grep DJANGO_SUPERUSER_LASTNAME | cut -d = -f2)

    # TODO add AUTHORIZATION_TOKEN HERE (adc)

    export TARGET_SERVER_FILE=$APP_PATH_ETC/.target-server.$TARGET_ENV
    export TARGET_SERVER_ADDR=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_ADDR | cut -d = -f2)
    export TARGET_SERVER_USER=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_USER | cut -d = -f2)
    export TARGET_SERVER_PROXY_ADDR=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_PROXY_ADDR | cut -d = -f2)
    export TARGET_SERVER_PROXY_USER=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_PROXY_USER | cut -d = -f2)

    export DEPLOYMENT_FILE=$APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.conf
    export GIT_PASSWORD=$(cat $DEPLOYMENT_FILE | grep GIT_PASSWORD | cut -d = -f2)

    # FIXME adjust `cat .env` bellow
    export BOT_ENV_FILE=$APP_PATH_ETC/.env.bot.$TARGET_ENV
    export RIVER_APP_PWD=$(cat $BOT_ENV_FILE | grep RIVER_APP_PWD | cut -d = -f2)
    export RIVER_PWD=$(cat $BOT_ENV_FILE | grep RIVER_PWD | cut -d = -f2)
}

unset_symbolic_link() {
    # TODO remove tmp files from origin
    rm -f .*~ *~ *#
    for slf in ${SYMBOLIC_LINK_FILES[@]};
    do
        echo "**UNSET** link file: $APP_PATH_DOCUMENT_ROOT/$slf"
        rm -f "$APP_PATH_DOCUMENT_ROOT/$slf"
    done

    rm -f $APP_PATH_ORIGIN_EDGE/git-hooks/forge
    rm -f $APP_PATH_ORIGIN_EDGE/git-hooks/forge.sh
    rm -f $APP_PATH_ORIGIN_EDGE/git-hooks/.mise-en-place.conf
    rm -f $APP_PATH_ORIGIN_EDGE/.mise-en-place.conf
}

set_symbolic_link() {
    unset_symbolic_link

    echo ""
    echo "Setting symbolic link"
    echo ""

    ln -sf $APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.conf $APP_PATH_BARE/hooks/.mise-en-place.conf # special - should not be removed
    ln -s $APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.conf $APP_PATH_ORIGIN_EDGE/.mise-en-place.conf
    ln -s $APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.conf $APP_PATH_ORIGIN_EDGE/git-hooks/.mise-en-place.conf
    ln -s $APP_PATH_ORIGIN_EDGE/forge.sh $APP_PATH_ORIGIN_EDGE/git-hooks/forge.sh
    ln -s $APP_PATH_ORIGIN_EDGE/forge $APP_PATH_ORIGIN_EDGE/git-hooks/forge

    ln -s $APP_PATH_ETC/.target-server.$TARGET_ENV $APP_PATH_DOCUMENT_ROOT/.target-server
    ln -s $APP_PATH_ETC/.pgpass.$TARGET_ENV $APP_PATH_DOCUMENT_ROOT/.pgpass

    for python_project in ${PYTHON_PROJECTS_AVAILABLE[@]};
    do
        ln -s $APP_PATH_ETC/.env.$python_project.$TARGET_ENV $APP_PATH_DOCUMENT_ROOT/$python_project/.env
    done

    chmod 600 $APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.*
    chmod 600 $APP_PATH_ETC/.pgpass.*
    chmod 600 $APP_PATH_ETC/.target-server.*
    chmod 640 $APP_PATH_ETC/.env.*
}

show_env() {
    # Show variables in memory to use in all devops tasks
    # $1 :: ["PWD" | NULL] - control if sensitive data must be showed again separated
    # $2 :: [DO_BREAK | NULL] - control if should do a break

    echo "|+------------------------------+|"
    echo "|     SHOW VARS [$TARGET_ENV]    |"
    echo "|+------------------------------+|"
    date

    # TODO migrate vars to use system ACRONYM in start?!
    for var in $(env | sort | grep -E "(${CUSTOM_VARS_FRAGMENT})" | cut -d = -f1);
	do
        var_name="$var"
        echo "$var_name=${!var_name}"
	done

    if [[ "$1" == "PWD" ]];
    then
        echo ""
        echo "|+-------------------------------------------+|"
        echo "|    [$TARGET_ENV] SHOWING SENSITIVE DATA     |"
        echo "|+-------------------------------------------+|"
        echo "DB_PASS=$DB_PASS"
        echo "DB_ADMIN_PASS=$DB_ADMIN_PASS"
        echo "DJANGO_SUPERUSER_PASSWORD=$DJANGO_SUPERUSER_PASSWORD"
        echo "API_AUTHORIZATION_TOKEN=$API_AUTHORIZATION_TOKEN"
    fi

    echo ""
    echo "|+--------------------------------------+|"
    echo "|     [$TARGET_ENV] SHOW VARS SYMLINKS   |"
    echo "|+--------------------------------------+|"
    # TODO think about how to show it without env vars... maybe forcing get basic info from $(dirname $0)/.credentials/.mise-en-place.conf
    FILES=".target-server .pgpass .mise-en-place.conf backoffice/.env bot/.env api/.env api/.google-service-account git-hooks/.mise-en-place.conf git-hooks/forge.sh /opt/adc/backend/bare.git/hooks/.* /opt/adc/backend/bare.git/hooks/*"
    ls -lah --color=auto $FILES

    if [ "$2" == "DO_BREAK" ];
    then
        echo ""
        echo "--- [PRESS ENTER TO CONTINUE] doing a break"
        echo ""
        read break
    fi
}

export_env() {
    # To be used in command line. Prepare the environment to run command with Makefile.
    # $1 :: define main TARGET_ENV
    # $2 :: define GIT_REPOS different from default
    # $3 :: define GIT_BRANCH different from default
    clear
    echo "Starting with variable ENV $1 :: REPOS $2 :: GIT_BRANCH $3"
    case $1 in
        "local" | "dev" | "stage" | "prod")
            echo ""
            echo "------------ BEFORE --------------"
            echo ""
            show_env "PWD"

            unset_vars
            echo ""
            echo "UNSETED vars..."
            echo ""

            set_vars $1 $2 $3 ""
            echo ""
            echo "SETTED vars with ENV $1 :: REPOS $2 :: GIT_BRANCH $3 ..."
            echo ""

            set_symbolic_link
            echo ""
            echo "SETTED vars..."
            echo ""

            echo ""
            echo "------------- AFTER --------------"
            echo ""
            show_env "PWD"
            ;;
        *)
            echo "ENV USAGE: [local | dev | stage | prod]. $1 *NOT* found!!"
            ;;
    esac
}
