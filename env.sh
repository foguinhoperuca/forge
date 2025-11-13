#!/bin/bash

unset_vars() {
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
    # FIXME DEPLOYMENT_FILE path is hardcoded. Should receive project's path here to have access to .credentials
    export DEPLOYMENT_FILE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.credentials/.mise-en-place.conf

    export FORGE_SYSTEM_ACRONYM=$(cat $DEPLOYMENT_FILE | grep FORGE_SYSTEM_ACRONYM | cut -d = -f2)
    export FORGE_SYSTEM_BASE_DNS=$(cat $DEPLOYMENT_FILE | grep FORGE_SYSTEM_BASE_DNS | cut -d = -f2)
    # FIXME [REVIEW IT!!] FORGE_SYSTEM_NAME is used only in terraform.sql (search for more uses!!) - can be replaced by FORGE_SYSTEM_ACRONYM?!
    export FORGE_SYSTEM_NAME="$(echo $FORGE_SYSTEM_BASE_DNS | sed -e s/\-/\_/g)"
    export GIT_BASE_URL=$(cat $DEPLOYMENT_FILE | grep GIT_BASE_URL | cut -d = -f2)
    export GIT_USER=$(cat $DEPLOYMENT_FILE | grep GIT_USER | cut -d = -f2)
    export GIT_PASSWORD=$(cat $DEPLOYMENT_FILE | grep GIT_PASSWORD | cut -d = -f2)
    if [ "$2" == "" ];
    then
        export GIT_REPOS="backend"
    else
        export GIT_REPOS=$2
    fi
    # FIXME APP_PATH_ORIGIN_EDGE shouldn't be $HOME but /home/$TARGET_SERVER_USER/
    export APP_PATH_ORIGIN_EDGE="${HOME}/universal/projects/pms/${FORGE_SYSTEM_ACRONYM}/$GIT_REPOS"
    export APP_PATH_ETC="/etc/${FORGE_SYSTEM_ACRONYM}"
    export APP_PATH_VAR_WWW="/var/www/${FORGE_SYSTEM_BASE_DNS}"
    export APP_PATH_MNT="/mnt/storage_sistemas/${FORGE_SYSTEM_BASE_DNS}" # FIXME use BASE_DNS or SYSTEM_ACRONYM !?
    export APP_PATH_OPT="/opt/${FORGE_SYSTEM_ACRONYM}/${GIT_REPOS}"
    export APP_PATH_BARE="$APP_PATH_OPT/bare.git"
    export APP_PATH_WORKTREE="$APP_PATH_OPT/worktree"
    export APP_PATH_DOCUMENT_ROOT="$APP_PATH_WORKTREE/document_root"
    export APP_PATH_UPSTREAM="$APP_PATH_WORKTREE/upstream"
    # TODO implement it!
    export APP_PATH_BASE_DB_BACKUP="/var/backups/postgres/"

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
            export TARGET_ENV=$(cat $DEPLOYMENT_FILE | grep DEFAULT_TARGET_ENV | cut -d = -f2) # if not setted
            export GIT_BRANCH=$TARGET_ENV
            echo "ENV USAGE: [local | dev | stage | prod]. $1 *NOT* found!! Using already setted!"
            ;;
    esac
    echo ""
    echo "[SET ENV] You choosed $1 parameters TARGET_ENV: $1 :: GIT_REPOS: $2 :: GIT_BRANCH: $3 ::: result is TARGET_ENV=$TARGET_ENV ::: GIT_BRANCH=$GIT_BRANCH"
}

set_vars_by_env() {
    echo ""
    echo "[SET VARS BY ENV] Vars that dependent from environment (ENV is $TARGET_ENV)"

    export TARGET_SERVER_FILE=$APP_PATH_ETC/.target-server.$TARGET_ENV
    export TARGET_SERVER_ADDR=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_ADDR | cut -d = -f2)
    export TARGET_SERVER_USER=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_USER | cut -d = -f2)
    export TARGET_SERVER_PROXY_ADDR=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_PROXY_ADDR | cut -d = -f2)
    export TARGET_SERVER_PROXY_USER=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_PROXY_USER | cut -d = -f2)
    # TODO implement vars for VOLUME_* from .target-server
    export TARGET_SERVER_DB_SYS_GRP=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_DB_SYS_GRP | cut -d = -f2)
    export TARGET_SERVER_DBAS=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_DBAS | cut -d = -f2)

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

    # TODO add custom confs from api, backoffice and bot
    export BACKOFFICE_ENV_FILE=$APP_PATH_ETC/.env.backoffice.$TARGET_ENV
    export DJANGO_SUPERUSER_USERNAME=$(cat $BACKOFFICE_ENV_FILE | grep DJANGO_SUPERUSER_USERNAME | cut -d = -f2)
    export DJANGO_SUPERUSER_PASSWORD=$(cat $BACKOFFICE_ENV_FILE | grep DJANGO_SUPERUSER_PASSWORD | cut -d = -f2)
    export DJANGO_SUPERUSER_EMAIL=$(cat $BACKOFFICE_ENV_FILE | grep DJANGO_SUPERUSER_EMAIL | cut -d = -f2)
    export DJANGO_SUPERUSER_FIRSTNAME=$(cat $BACKOFFICE_ENV_FILE | grep DJANGO_SUPERUSER_FIRSTNAME | cut -d = -f2)
    export DJANGO_SUPERUSER_LASTNAME=$(cat $BACKOFFICE_ENV_FILE | grep DJANGO_SUPERUSER_LASTNAME | cut -d = -f2)

    export API_ENV_FILE=$APP_PATH_ETC/.env.api.$TARGET_ENV
    export API_AUTHORIZATION_TOKEN=$(cat $API_ENV_FILE | grep API_AUTHORIZATION_TOKEN | cut -d = -f2)

    export BOT_ENV_FILE=$APP_PATH_ETC/.env.bot.$TARGET_ENV
}

unset_symbolic_link() {
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

complement_set_symbolic_link() {
    echo "|+-----------------------------------------------+|"
    echo "| [FORGE] COMPLEMENT for set symbiolic link logic |"
    echo "|+-----------------------------------------------+|"
}

set_symbolic_link() {
    unset_symbolic_link

    echo ""
    echo "[FORGE] Setting symbolic link"
    echo ""

    ln -sf $APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.conf $APP_PATH_BARE/hooks/.mise-en-place.conf # special - should not be removed
    ln -s $APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.conf $APP_PATH_ORIGIN_EDGE/.mise-en-place.conf
    ln -s $APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.conf $APP_PATH_ORIGIN_EDGE/git-hooks/.mise-en-place.conf
    ln -s $APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.conf $APP_PATH_DOCUMENT_ROOT/.mise-en-place.conf

    ln -s $APP_PATH_ORIGIN_EDGE/forge.sh $APP_PATH_ORIGIN_EDGE/git-hooks/forge.sh
    ln -s $APP_PATH_ORIGIN_EDGE/forge $APP_PATH_ORIGIN_EDGE/git-hooks/forge

    ln -s $APP_PATH_ETC/.target-server.$TARGET_ENV $APP_PATH_DOCUMENT_ROOT/.target-server
    ln -s $APP_PATH_ETC/.pgpass.$TARGET_ENV $APP_PATH_DOCUMENT_ROOT/.pgpass

    for python_project in ${PYTHON_PROJECTS_AVAILABLE[@]};
    do
        ln -s $APP_PATH_ETC/.env.$python_project.$TARGET_ENV $APP_PATH_DOCUMENT_ROOT/$python_project/.env
    done

    # FIXME mise-en-place should stay in /etc or .credentials!? If stay in /etc it could be copied from .credentials and be replaced DEFAULT_TARGET_ENV with ENV in terraform
    chmod 600 $APP_PATH_ORIGIN_EDGE/.credentials/.mise-en-place.*
    chmod 600 $APP_PATH_ETC/.pgpass.*
    chmod 600 $APP_PATH_ETC/.target-server.*
    chmod 640 $APP_PATH_ETC/.env.*

    complement_set_symbolic_link
}

# TODO use other technics tho tet $1 and $2 is NULL
show_env() {
    # Show variables in memory to use in all devops tasks
    # $1 :: ["PWD" | NULL] - control if sensitive data must be showed again separated
    # $2 :: [DO_BREAK | NULL] - control if should do a break

    echo "|+------------------------------+|"
    echo "|     SHOW VARS [$TARGET_ENV]    |"
    echo "|+------------------------------+|"
    date

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
        # TODO show primary and FOREIGN DB
        echo "DJANGO_SUPERUSER_PASSWORD=$DJANGO_SUPERUSER_PASSWORD"
        echo "API_AUTHORIZATION_TOKEN=$API_AUTHORIZATION_TOKEN"
    fi

    echo ""
    echo "|+--------------------------------------+|"
    echo "|     [$TARGET_ENV] SHOW VARS SYMLINKS   |"
    echo "|+--------------------------------------+|"
    # TODO think about how to show it without env vars... maybe forcing get basic info from $(dirname $0)/.credentials/.mise-en-place.conf
    # TODO add api/.google-service-account to be used as symlink
    ls -lah --color=auto $CONF_FILES

    if [ "$2" == "DO_BREAK" ];
    then
        echo ""
        echo "--- [PRESS ENTER TO CONTINUE] doing a break"
        echo ""
        read break
    fi
}

generate_secret() {
	PW_LEN=$1
	if [ -z "$PW_LEN" ];
	then
		echo "No PW_LEN specified and not set. Usage: $0 PW_LEN. Default is 64." >&2
		PW_LEN="64"
	fi
	
	local len=${1:-$PW_LEN}
	local raw=$(( (len * 3 + 3) / 4 ))
	gpg --gen-random 1 "$raw" | base64 | tr -d '/+' | tr -d '\n' | cut -c1-"$len"
}


encrypt_file() {
	local file="$1"
	if [ -n "${GPG_RECIPIENT:-}" ]; then
		# public-key encryption
		gpg --yes --batch --trust-model always --output "${file}.gpg" --encrypt --recipient "$GPG_RECIPIENT" "$file"
	elif [ -n "${GPG_PASSPHRASE:-}" ]; then
		# symmetric encryption using provided passphrase
		gpg --yes --batch --passphrase "$GPG_PASSPHRASE" --symmetric --cipher-algo AES256 --output "${file}.gpg" "$file"
	else
		echo "Neither GPG_RECIPIENT nor GPG_PASSPHRASE set. Cannot create encrypted copy." >&2
		return 2
	fi
}

generate_conf_file() {
	ENV_DESIRED=$1
	if [ "$1" == "" ];
    then
        echo ""
        echo "--- Load env"
        echo ""
		ENV_DESIRED=$TARGET_ENV
    fi
	echo ""
	echo "ENV_DESIRED --> $ENV_DESIRED"
	echo ""

    # TODO implement using git submodule to store all secrets. That will have an layout as:
    # -- secrets/public_keys/
    # ---- devs/
    # ---- machines/
    # -- secrets/projects/
    # ---- $FORGE_SYSTEM_ACRONYM - project_alpha
    # ---- $FORGE_SYSTEM_ACRONYM - project_beta
    # ---- $FORGE_SYSTEM_ACRONYM - project_gamma
    # ---- ...

	for FILE_SAMPLE in $(ls .credentials/.*.sample | sed -e s/\.credentials\\/\.//g | sed -e s/\.sample//g);
	do
		TARGET_ENTRY=$ENV_DESIRED
		CONTENT=$(cat .credentials/."$FILE_SAMPLE".sample | sed '1d' | cut -d = -f1)
		case $FILE_SAMPLE in
			"pgpass")
				CONTENT=$(cat .credentials/."$FILE_SAMPLE".sample | sed '1d')
				;;
			"mise-en-place.conf")
				TARGET_ENTRY="ingredient"
				;;
			*)
				# echo "--------------------"
				# echo "Skip $FILE_SAMPLE for test purpose only"
				# echo "--------------------"
				# continue
				;;
		esac

		echo ""
		echo "+==================================================================================================+"
		echo "| FILE_SAMPLE --> $FILE_SAMPLE ::: TARGET_ENTRY --> $TARGET_ENTRY ::: ENV_DESIRED --> $ENV_DESIRED |"
		echo "+==================================================================================================+"
		echo ""
		case $FILE_SAMPLE in
			"mise-en-place.conf")
				DESTINY=.credentials/."$FILE_SAMPLE"
				;;
			*)
				DESTINY=.credentials/."$FILE_SAMPLE"."$TARGET_ENTRY"
				;;
		esac
		: > $DESTINY

		# TODO implement fn arg "ALL" to generate all entries for all envs

		IFS=$'\n'
		for LINE in $CONTENT;
		do
			if [[ "$LINE" == \#* ]]; then
				continue
			fi

			IFS=':' read -r -a ENTRIES <<< "$LINE"
			BUILD_UP_LINE=""
			for ENTRY in "${ENTRIES[@]}"; do
				SECRET=$(generate_secret "16")
				# TODO generate_secret do not make much sense for various. Maybe grab data from .seed file with defaults (username for DB, username for app, server ip, etc) - those files (.seed) shouldn't be checked into git but keep it in another secure place

				# SECRET=$(kpcli --readonly --kdb ".credentials/sample.kdbx" --pwfile ".credentials/pass.txt" --command "show -f \"/sample/"$FILE_SAMPLE"/"$ENTRY"/"$TARGET_ENTRY"\"" | grep -E 'Pass: ' | cut -d : -f2 | sed 's/^[[:space:]]*//') # FIXME --key ".credentials/sample.keyx" not working
				case $FILE_SAMPLE in
					"pgpass")
						BUILD_UP_LINE+="$SECRET"":"
						;;
					*)
						BUILD_UP_LINE+="$ENTRY""=""$SECRET"
						;;
				esac
			done

			case $FILE_SAMPLE in
				"pgpass")
					echo ${BUILD_UP_LINE%:} >> $DESTINY
					# echo ${BUILD_UP_LINE%:}
					;;
				*)
					echo $BUILD_UP_LINE >> $DESTINY
					# echo $BUILD_UP_LINE
					;;
			esac
		done
	done
}

# TODO finish it!
cp_secrets() {
    # set -eu

    # TODO do a better logic: TARGET_ENV can be not defined
	ENV_CP=$1
    case "$ENV_CP" in
		"ALL"|"all")
            for TRG in ${WORKFLOW_ENVS_AVAILABLE[@]};
            do
                CP_FILES_ETC+="$(ls .credentials/.*.sample | sed -e s/\.sample/\.$TRG/g | sed -e s/\.conf\.$TRG/\.conf/g) "
                CP_FILES_ETC=$(echo $CP_FILES_ETC | awk '{ for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i; printf "\n" }')
                CP_FILES_EDGE+="$(ls .credentials/.*.sample | sed -e s/\.credentials\\//\.credentials\\/secrets\\//g | sed -e s/\.sample/\.$TRG\.gpg/g | sed -e s/conf\.$TRG/conf/g) "
                CP_FILES_EDGE=$(echo $CP_FILES_EDGE | awk '{ for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i; printf "\n" }')
            done
			;;
		*)
            if [[ -z "$ENV_CP" ]];
	        then
                ENV_CP=$TARGET_ENV
	        fi
            CP_FILES_ETC=$(ls .credentials/.*.sample  | sed -e s/\.sample/\.$ENV_CP/g | sed -e s/\.conf\.$ENV_CP/\.conf/g)
            CP_FILES_EDGE=$(ls .credentials/.*.sample | sed -e s/\.credentials\\//\.credentials\\/secrets\\//g | sed -e s/\.sample/\.$ENV_CP\.gpg/g | sed -e s/\.conf\.$ENV_CP/\.conf/g)
			;;
	esac

    # FIXME not copying .mise-en-place.conf to $EDGE/.credentials - that's essential today 'cause syslimk came from there...

    ETC_DEPLOYMENT="$APP_PATH_ETC/"
    EDGE_DEPLOYMENT="${APP_PATH_WORKTREE}/edge/.credentials/secrets/"
    # scp .credentials/.mise-en-place.conf .credentials/.env.* .credentials/.google-service-account* .credentials/.pgpass.* .credentials/.target-server.* $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR):$(shell echo "${APP_PATH_ORIGIN_EDGE}" | sed -e "s/${USER}/${TARGET_SERVER_USER}/g")/.credentials/

    # FIXME fix FORGE_TEST to use secrets2 *INSIDE* original intention
    FORGE_TEST=${FORGE_TEST:-0}
    if [[ "$FORGE_TEST" == "1" ]];
    then
        ETC_DEPLOYMENT="${ETC_DEPLOYMENT}/secrets2/"
        EDGE_DEPLOYMENT="${EDGE_DEPLOYMENT}/secrets2/"
    fi

    DRY_RUN=${DRY_RUN:-0}
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "DRY_RUN $DRY_RUN ::: FORGE_TEST $FORGE_TEST"
        echo "-------------------------------------------"
        echo "[DRY-RUN] CP_FILES_ETC --> $ENV_CP :: $TARGET_SERVER_USER :: $TARGET_SERVER_ADDR :: $APP_PATH_ETC :: $ETC_DEPLOYMENT"
        echo $CP_FILES_ETC
        echo ""
        echo "====="
        echo ""
        echo "[DRY-RUN] CP_FILES_EDGE --> $ENV_CP :: $TARGET_SERVER_USER :: $TARGET_SERVER_ADDR :: $APP_PATH_WORKTREE :: $EDGE_DEPLOYMENT"
        echo $CP_FILES_EDGE
        echo "-------------------------------------------"
        echo ""

        return 0
    fi

    echo "cp to $ETC_DEPLOYMENT"
    scp $CP_FILES_ETC "$TARGET_SERVER_USER"@"$TARGET_SERVER_ADDR":"$ETC_DEPLOYMENT"
    echo "====="
    echo "cp to $EDGE_DEPLOYMENT"
    scp $CP_FILES_EDGE "$TARGET_SERVER_USER"@"$TARGET_SERVER_ADDR":"$EDGE_DEPLOYMENT"

    ssh $TARGET_SERVER_USER@$TARGET_SERVER_ADDR "echo $NOW > $ETC_DEPLOYMENT/deployment.txt; echo $NOW > $EDGE_DEPLOYMENT/deployment.txt"

    # TODO set value of DEFAULT_TARGET_ENV in .mise-en-place.conf
    # FIXME need sed -i to backup change?!
    ssh $TARGET_SERVER_USER@$TARGET_SERVER_ADDR "sudo sed -i.bkp \"s/^DEFAULT_TARGET_ENV=.*/DEFAULT_TARGET_ENV=${ENV_CP}/\" $ETC_DEPLOYMENT/.mise-en-place.conf"
}
