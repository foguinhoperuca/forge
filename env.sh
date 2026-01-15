#!/bin/bash

unset_vars() {
    for var in $(env | sort | grep -E "(${CUSTOM_VARS_FRAGMENT})" | cut -d = -f1);
    do
        unset $var
    done
}

complement_set_vars() {
    echo "|+-----------------------------------------------+|"
    echo "| [FORGE] COMPLEMENT for set vars logic           |"
    echo "|+-----------------------------------------------+|"
}

# TODO implement a function to read .mise-en-place.conf and load vars from there without be specified before
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
    export FORGE_ORGANIZATION_ACRONYM=$(cat $DEPLOYMENT_FILE | grep FORGE_ORGANIZATION_ACRONYM | cut -d = -f2)
    export FORGE_ORGANIZATION_BASEDNS=$(cat $DEPLOYMENT_FILE | grep FORGE_ORGANIZATION_BASEDNS | cut -d = -f2)
    # TODO review it - URL can be used from git remote origin (fetch)
    export GIT_PROTOCOL=$(cat $DEPLOYMENT_FILE | grep GIT_PROTOCOL | cut -d = -f2)
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
    # FIXME .credentials/secrets_output/.gitignore should be added in host repository?
    export APP_PATH_CREDENTIALS_GENERATED_OUTPUT="secrets_output"
	export APP_PATH_CREDENTIALS_GENERATED_INPUT="secrets_input"
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

    complement_set_vars
}

complement_set_vars_by_env() {
    echo "|+-----------------------------------------------+|"
    echo "| [FORGE] COMPLEMENT for set vars by env logic    |"
    echo "|+-----------------------------------------------+|"
}

set_vars_by_env() {
    echo ""
    echo "[SET VARS BY ENV] Vars that dependent from environment (ENV is $TARGET_ENV)"

    export TARGET_SERVER_FILE=$APP_PATH_ETC/.target-server.$TARGET_ENV
    export TARGET_SERVER_ADDR=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_ADDR | cut -d = -f2)
    export TARGET_SERVER_USER=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_USER | cut -d = -f2)
    export TARGET_SERVER_PROXY_ADDR=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_PROXY_ADDR | cut -d = -f2)
    export TARGET_SERVER_PROXY_USER=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_PROXY_USER | cut -d = -f2)
    export TARGET_SERVER_DB_SYS_GRP=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_DB_SYS_GRP | cut -d = -f2)
    export TARGET_SERVER_DBAS=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_DBAS | cut -d = -f2)
    export TARGET_SERVER_VOLUME_USERNAME=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_VOLUME_USERNAME | cut -d = -f2)
    export TARGET_SERVER_VOLUME_PASSWORD=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_VOLUME_PASSWORD | cut -d = -f2)
    export TARGET_SERVER_VOLUME_DOMAIN=$(cat $TARGET_SERVER_FILE | grep TARGET_SERVER_VOLUME_DOMAIN | cut -d = -f2)

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
    export DB_FOREIGN_HOST=$(cat $PGPASSFILE | cut -d : -f1 | sed -n '3,3p')
    export DB_FOREIGN_PORT=$(cat $PGPASSFILE | cut -d : -f2 | sed -n '3,3p')
    export DB_FOREIGN_DATABASE=$(cat $PGPASSFILE | cut -d : -f3 | sed -n '3,3p')
    export DB_FOREIGN_USER=$(cat $PGPASSFILE | cut -d : -f4 | sed -n '3,3p')
    export DB_FOREIGN_PASS=$(cat $PGPASSFILE | cut -d : -f5 | sed -n '3,3p')
    export DB_FOREIGN_ADMIN_HOST=$(cat $PGPASSFILE | cut -d : -f1 | sed -n '4,4p')
    export DB_FOREIGN_ADMIN_PORT=$(cat $PGPASSFILE | cut -d : -f2 | sed -n '4,4p')
    export DB_FOREIGN_ADMIN_DATABASE=$(cat $PGPASSFILE | cut -d : -f3 | sed -n '4,4p')
    export DB_FOREIGN_ADMIN_USER=$(cat $PGPASSFILE | cut -d : -f4 | sed -n '4,4p')
    export DB_FOREIGN_ADMIN_PASS=$(cat $PGPASSFILE | cut -d : -f5 | sed -n '4,4p')

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

    complement_set_vars_by_env
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
    echo "| [FORGE] COMPLEMENT for set symbolic link logic  |"
    echo "|+-----------------------------------------------+|"
}

# TODO implement a version to set symlink by [ENV | document_root | edge | upstream]
set_symbolic_link() {
    unset_symbolic_link

    echo ""
    echo "[FORGE] Setting symbolic link"
    echo ""

    # TODO update files: only need ln -s hooks*/forge and ln -s hooks*/post-receive
    # TODO make forge.sh recoginize .credentials/.mise-en-place.conf
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

# TODO use other technics tho test $1 and $2 is NULL
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

encrypt_multiple() {
    # encrypt secret files using all pubkeys availiable per project.
    # [OPTIONAL]  $DRY_RUN :: do not execute changes with side-effect (e.g.: create files)
    # [OPTIONAL]  $DEBUG :: show debug messages
    GPG_RECIPIENTS=""
    for pubkey in $(ls .credentials/encrypted/secure/*.asc);
    do
        GPG_RECIPIENTS+="-r $(gpg --show-keys --with-colons $pubkey | awk -F':' '$1=="pub"{print $5}') "
    done

    DRY_RUN=${DRY_RUN:-0}
    if [[ "$DRY_RUN" == "1" ]];
    then
        echo ""
        echo "Would use GPG_RECIPIENTS --> ${GPG_RECIPIENTS}"
        echo "exiting..."
        echo ""
        return 0
    fi

    for filename in $(ls "$APP_PATH_ETC"/.*);
    do
        OUTPUT_FILE=$(echo $filename | sed -e "s|${APP_PATH_ETC}/||g")

        DEBUG=${DEBUG:-0}
        if [[ "$DEBUG" == "1" ]];
        then
            echo .credentials/$APP_PATH_CREDENTIALS_GENERATED_INPUT/$OUTPUT_FILE.gpg ${GPG_RECIPIENTS} $filename
            echo "---------------"
        fi

        gpg --batch --yes -e -o .credentials/$APP_PATH_CREDENTIALS_GENERATED_INPUT/$OUTPUT_FILE.gpg ${GPG_RECIPIENTS} $filename
    done
    echo "${NOW}" | sudo tee .credentials/$APP_PATH_CREDENTIALS_GENERATED_INPUT/deployment_datetime.txt > /dev/null
}

generate_conf_file() {
    # Generate conf file from samples. It would grab secrets into remote vault, local vault (keepass) or be generated here
    # [MANDATORY] $1 :: define environment desired to be generate. ALL is implemented in the call of this function.
    # [MANDATORY] $2 :: define $SOURCE_SECRETS [passbolt | keepass | new | gpg]
    # [OPTIONAL]  $DEPLOY_GENERATED_FILES :: define if generated files will be deployed to each target
    # [OPTIONAL]  $DRY_RUN :: do not execute changes with side-effect (e.g.: create files)
    # [OPTIONAL]  $DEBUG :: show debug messages

    ENV_DESIRED=$1
    if [ "$1" == "" ];
    then
        ENV_DESIRED=$TARGET_ENV
        echo ""
        echo "--- Load env ${ENV_DESIRED}"
        echo ""
    fi
    SOURCE_SECRETS=$2
    if [ "$2" == "" ];
    then
        SOURCE_SECRETS="new"
        echo ""
        echo "--- Source Secrets ${SOURCE_SECRETS}"
        echo ""
    fi
    DEPLOY_GENERATED_FILES=${DEPLOY_GENERATED_FILES:-0}

    for FILE_SAMPLE in $(ls .credentials/samples/.*example | sed -e "s|\.credentials/samples/||g" | sed -e s/\.target-env-example//g | sed -e s/\.example//g);
    do
        if [[ "${SOURCE_SECRETS}" == "gpg" ]];
        then
            DEST="${FILE_SAMPLE}$([[ "$FILE_SAMPLE" == ".mise-en-place.conf" ]] && echo "" || echo ".${ENV_DESIRED}")"
            gpg --quiet --batch --yes --output .credentials/${APP_PATH_CREDENTIALS_GENERATED_OUTPUT}/${DEST} --decrypt .credentials/encrypted/secure/${DEST}.gpg
            echo "${NOW}" | sudo tee .credentials/${APP_PATH_CREDENTIALS_GENERATED_OUTPUT}/deployment_datetime.txt > /dev/null
            continue
        fi

        TARGET_ENTRY=$([[ "$FILE_SAMPLE" == ".mise-en-place.conf" ]] && echo "ingredient" || echo "$ENV_DESIRED")
        DESTINY=".credentials/${APP_PATH_CREDENTIALS_GENERATED_OUTPUT}/${FILE_SAMPLE}$([[ "$FILE_SAMPLE" == ".mise-en-place.conf" ]] && echo "" || echo ".${TARGET_ENTRY}")"
        CONTENT=$([[ "$FILE_SAMPLE" == ".pgpass" ]] && cat .credentials/samples/"$FILE_SAMPLE"*example | sed '1d' || cat .credentials/samples/"$FILE_SAMPLE"*example | sed '1d' | cut -d = -f1)

        DEBUG=${DEBUG:-0}
        if [[ "$DEBUG" == "1" ]];
        then
            echo ""
            echo "+===================================================================================================================================="
            echo "| [DEBUG] DRY_RUN -> $DRY_RUN :: FILE_SAMPLE -> $FILE_SAMPLE :: TARGET_ENTRY -> $TARGET_ENTRY :: ENV_DESIRED -> $ENV_DESIRED :: DESTINY -> $DESTINY :: DEPLOY_GENERATED_FILES -> $DEPLOY_GENERATED_FILES"
            echo "+===================================================================================================================================="
            echo "------------------------------------------- <CONTENT>  -------------------------------------------"
            echo "$CONTENT"
            echo "------------------------------------------- </CONTENT> -------------------------------------------"
            echo "------------------------------------------- <RESULT>  --------------------------------------------"
        fi

        DRY_RUN=${DRY_RUN:-0}
        if [[ "$DRY_RUN" != "1" ]];
        then
            : > $DESTINY
        fi

        IFS=$'\n'
        for LINE in $CONTENT;
        do
            if [[ "$LINE" == \#* ]]; then
                continue
            fi

            IFS=':' read -r -a ENTRIES <<< "$LINE"
            BUILD_UP_LINE=""
            for ENTRY in "${ENTRIES[@]}"; do
                # TODO generate_secret do not make much sense for various. Maybe grab data from .seed file with defaults (username for DB, username for app, server ip, etc) - those files (.seed) shouldn't be checked into git but keep it in another secure place
                # TODO make sense to grab secrets from .*.gpg files?!
                case $SOURCE_SECRETS in
                    "keepass")
                        # FIXME use correct sample.kdbx and pwfile (pass.txt) - implement some strategy to grab pass.txt (it should be encrypted with gpg)
                        SECRET=$(kpcli --readonly --kdb "${APP_PATH_WORKTREE}/edge/.credentials/encrypted/secure/vault.kdbx" --pwfile "${APP_PATH_WORKTREE}/edge/.credentials/encrypted/secure/pass.txt" --command "show -f \"/sample/"$FILE_SAMPLE"/"$ENTRY"/"$TARGET_ENTRY"\"" | grep -E 'Pass: ' | cut -d : -f2 | sed 's/^[[:space:]]*//') # FIXME --key ".credentials/sample.keyx" not working
                        ;;
                    "passbolt")
                        SECRET="TODO implement client to get REMOTE ENTRY using PASSBOLT"
                        ;;
                    "new")
                        SECRET=$(generate_secret "16")
                        ;;
                    *)
                        echo "[ERROR] Should do nothing: SOURCE_SECRETS -> ${SOURCE_SECRETS}"
                        exit 1
                        ;;
                esac

                case $FILE_SAMPLE in
                    ".pgpass")
                        BUILD_UP_LINE+="$SECRET"":"
                        ;;
                    *)
                        BUILD_UP_LINE+="$ENTRY""=""$SECRET"
                        ;;
                esac
            done

            if [[ "$DRY_RUN" != "1" ]];
            then
                case $FILE_SAMPLE in
                    ".pgpass")
                        echo ${BUILD_UP_LINE%:} >> $DESTINY
                        DEBUG=${DEBUG:-0}
                        if [[ "$DEBUG" == "1" ]];
                        then
                            echo ${BUILD_UP_LINE%:}
                        fi
                        ;;
                    *)
                        echo $BUILD_UP_LINE >> $DESTINY
                        if [[ "$DEBUG" == "1" ]];
                        then
                            echo $BUILD_UP_LINE
                        fi
                        ;;
                esac
            fi
        done
        if [[ "$DEBUG" == "1" ]];
        then
            echo "------------------------------------------- </RESULT> -------------------------------------------"
        fi
    done

    sudo chown -R "$TARGET_SERVER_USER:$TARGET_SERVER_USER" .credentials/$APP_PATH_CREDENTIALS_GENERATED_OUTPUT/
    echo "${NOW}" | tee .credentials/$APP_PATH_CREDENTIALS_GENERATED_OUTPUT/deployment_datetime.txt

    if [[ "$DEPLOY_GENERATED_FILES" == "1" ]];
    then
        echo "Copying generated files to deploy target..."
        cp ".credentials/$APP_PATH_CREDENTIALS_GENERATED_OUTPUT/.mise-en-place.conf" ".credentials/$APP_PATH_CREDENTIALS_GENERATED_OUTPUT/deployment_datetime.txt" ".credentials/"
        cp ".credentials/$APP_PATH_CREDENTIALS_GENERATED_OUTPUT/.env"* ".credentials/$APP_PATH_CREDENTIALS_GENERATED_OUTPUT/.pgpass"* ".credentials/$APP_PATH_CREDENTIALS_GENERATED_OUTPUT/.target-server"* ".credentials/$APP_PATH_CREDENTIALS_GENERATED_OUTPUT/deployment_datetime.txt" "$APP_PATH_ETC"
    fi
}

cp_secrets() {
    # copy secrets to desired environment.
    # [MANDATORY] $1 :: define environment desired to be generate.
    # [WIP]       $2 :: define the type of files that will be copied [etc | edge | mise-en-place | all]
    # [OPTIONAL]  $DRY_RUN :: do not execute changes with side-effect (e.g.: create files)
    # [OPTIONAL]  $DEBUG :: show debug messages

    # set -eu

    # TODO do a better logic: TARGET_ENV can be not defined
    ENV_CP=$1
    case "$ENV_CP" in
        "ALL"|"all")
            for TRG in ${WORKFLOW_ENVS_AVAILABLE[@]};
            do
                CP_FILES_ETC+="$(ls  .credentials/samples/.*example | grep -v mise-en-place | sed -e "s#samples#$APP_PATH_CREDENTIALS_GENERATED_OUTPUT#g" | sed -e s/\.target-env-example/\.$TRG/g) "
                CP_FILES_EDGE+="$(ls .credentials/samples/.*example | sed -e s/samples/encrypted\\/secure/g | sed -e s/\.target-env-example/\.$TRG\.gpg/g | sed -e s/\.conf.example/\.conf\.gpg/g) "
            done
            CP_FILES_ETC=$(echo $CP_FILES_ETC | awk '{ for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i; printf "\n" }')
            CP_FILES_EDGE=$(echo $CP_FILES_EDGE | awk '{ for (i=1; i<=NF; i++) if (!seen[$i]++) printf "%s ", $i; printf "\n" }')
            ;;
        *)
            if [[ -z "$ENV_CP" ]];
            then
                ENV_CP=$TARGET_ENV
            fi
            CP_FILES_ETC=$(ls .credentials/samples/.*example  | grep -v mise-en-place | sed -e "s|samples|$APP_PATH_CREDENTIALS_GENERATED_OUTPUT|g" | sed -e "s/\.target-env-example/\.$ENV_CP/g" | sed -e "s/\.conf\.example/\.conf/g")
            CP_FILES_EDGE=$(ls .credentials/samples/.*example | sed -e s/samples/encrypted\\/secure/g | sed -e s/\.target-env-example/\.$ENV_CP\.gpg/g | sed -e s/\.conf\.example/\.conf\.gpg/g)
            ;;
    esac

    DEPLOY_GENERATED_FILES=$2

    ETC_DEPLOYMENT="$APP_PATH_ETC"
    EDGE_DEPLOYMENT="${APP_PATH_WORKTREE}/edge/.credentials/encrypted/secure"
    MISE_EN_PLACE_DEPLOYMENT="${APP_PATH_WORKTREE}/edge/.credentials"
    # scp .credentials/.mise-en-place.conf .credentials/.env.* .credentials/.google-service-account* .credentials/.pgpass.* .credentials/.target-server.* $(TARGET_SERVER_USER)@$(TARGET_SERVER_ADDR):$(shell echo "${APP_PATH_ORIGIN_EDGE}" | sed -e "s/${USER}/${TARGET_SERVER_USER}/g")/.credentials/

    FORGE_TEST=${FORGE_TEST:-0}
    if [[ "$FORGE_TEST" == "1" ]];
    then
        ETC_DEPLOYMENT="${ETC_DEPLOYMENT}/${APP_PATH_CREDENTIALS_GENERATED_OUTPUT}"
        EDGE_DEPLOYMENT="${EDGE_DEPLOYMENT}/${APP_PATH_CREDENTIALS_GENERATED_OUTPUT}"
        MISE_EN_PLACE_DEPLOYMENT="${MISE_EN_PLACE_DEPLOYMENT}/${APP_PATH_CREDENTIALS_GENERATED_OUTPUT}/cp_tests/"
    fi

    DRY_RUN=${DRY_RUN:-0}
    if [[ "$DRY_RUN" == "1" ]];
    then
        echo "DRY_RUN $DRY_RUN ::: FORGE_TEST $FORGE_TEST :: $TARGET_SERVER_USER :: $TARGET_SERVER_ADDR"
        echo "-------------------------------------------"
        echo "[DRY-RUN] CP_FILES_ETC --> $ENV_CP :: $APP_PATH_ETC :: $ETC_DEPLOYMENT"
        echo $CP_FILES_ETC
        echo ""
        echo "================"
        echo "[DRY-RUN] CP_FILES_EDGE --> $ENV_CP :: $APP_PATH_WORKTREE :: $EDGE_DEPLOYMENT"
        echo $CP_FILES_EDGE
        echo ""
        echo "================"
        echo "[DRY-RUN] CP_FILES_MISE_EN_PLACE $MISE_EN_PLACE_DEPLOYMENT"
        echo ""

        return 0
    fi

    # TODO implement a logic to choose what gonna be copied: [etc | edge | all]
    echo "cp ETC to $ETC_DEPLOYMENT"
    scp $CP_FILES_ETC "$TARGET_SERVER_USER"@"$TARGET_SERVER_ADDR":"$ETC_DEPLOYMENT"
    echo "====="
    echo "cp EDGE to $EDGE_DEPLOYMENT"
    scp $CP_FILES_EDGE "$TARGET_SERVER_USER"@"$TARGET_SERVER_ADDR":"$EDGE_DEPLOYMENT"
    echo "====="
    echo "cp MISE-EN-PLACE to $MISE_EN_PLACE_DEPLOYMENT :: ${ENV_CP}"
    scp ".credentials/${APP_PATH_CREDENTIALS_GENERATED_OUTPUT}/.mise-en-place.conf" "$TARGET_SERVER_USER"@"$TARGET_SERVER_ADDR":"$MISE_EN_PLACE_DEPLOYMENT"
    if [[ "${ENV_CP}" != "all" ]];
    then
        ssh $TARGET_SERVER_USER@$TARGET_SERVER_ADDR "sudo sed -i.bkp_${NOW} \"s/^DEFAULT_TARGET_ENV=.*/DEFAULT_TARGET_ENV=${ENV_CP}/\" $MISE_EN_PLACE_DEPLOYMENT/.mise-en-place.conf"
    fi

    ssh $TARGET_SERVER_USER@$TARGET_SERVER_ADDR "echo $NOW > $ETC_DEPLOYMENT/deployment_datetime.txt; echo $NOW > $EDGE_DEPLOYMENT/deployment_datetime.txt; echo $NOW > $MISE_EN_PLACE_DEPLOYMENT/deployment_datetime.txt"
}
