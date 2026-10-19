#!/bin/bash

validate_safe_path() {
    local path_under_review="$1"

    if [[ -z "$path_under_review" ]]; then
        echo "[FATAL] ERROR: Path is empty" >&2
        return 1
    fi

    case "$path_under_review" in
        /*) : ;;  # absoluto, ok
        *) echo "[FATAL] ERROR: Path must be absolute: '$path_under_review'" >&2; return 1 ;;
    esac

    case "$path_under_review" in
        /|/bin|/boot|/dev|/etc|/home|/lib|/lib64|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var)
            echo "[FATAL] ERROR: Dangerous path: '$path_under_review'" >&2
            return 1
            ;;
    esac

    case "$path_under_review" in
        /etc/*|/opt/*|/srv/*) : ;;  # permitido
        *) echo "[FATAL] ERROR: Path not under allowed base directories: '$path_under_review'" >&2; return 1 ;;
    esac

    if [[ "$path_under_review" =~ \\.\. || "$path_under_review" =~ [[:space:]] ]]; then
        echo "[FATAL] ERROR: Invalid characters in path: '$path_under_review'" >&2
        return 1
    fi

    return 0
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

# echo "+$(printf -- '=%.0s' $(seq 1 $(($CHARS_BANNER_MSG))))+"; echo "| HELLO |"; echo "+$(printf -- '=%.0s' $(seq 1 $(($CHARS_BANNER_MSG))))+"
print_banner() {
    BANNER_MSG=$1
    CHARS_BANNER_MSG=${#BANNER_MSG}
    BORDER=$(printf -- '=%.0s' $(seq 1 $(($CHARS_BANNER_MSG))))
    echo ""
    echo "|+$BORDER+|"
    echo "| $BANNER_MSG |"
    echo "|+$BORDER+|"
    echo""
}

do_sleep_break() {
    # Do a pause in code execution. Same as sleep.
    # Call it whit something like: [[ "$DO_BREAK" == "true" ]] && do_sleep_break || :

    echo ""
    echo "--- [PRESS ENTER TO CONTINUE] ---"
    echo ""
    read sleep_break
}

deployment_stats() {
    local STATS_PATH="${1:-$APP_PATH_DOCUMENT_ROOT}/deployment_stats.txt"

    print_banner "[FORGE] Deploy stats to ${STATS_PATH}"
    date +"%Y-%m-%dT%H-%M-%S" > "$STATS_PATH"
    git -C "$APP_PATH_DOCUMENT_ROOT" rev-parse --short=8 HEAD >> "$STATS_PATH"
}

get_passbolt_folder_ids() {
    # Grab all folders ID from passbolt using the default organization: forge -> ORGANIZATION -> SYSTEM -> ENVIRONMENT -> CONFIGURATION FILE
    # Each configuration file will have multiple resources with the name as the same as the key and in passworld will be stored the secret/sensible information (configuration itself)
    # [MANDATORY] $1 PASSBOLT_IDS         :: array where all data grabed will be stored.
    # [OPTIONAL]  $2 ENV_DESIRED          :: set the environmet that will be used. The dafult is use $TARGET_ENV
    # [OPTIONAL]  $3 PASSBOLT_ROOT_FOLDER :: the folder that will be the root of all to stored data into passbolt. Default value is: forge

    declare -n PASSBOLT_IDS="$1"
    local ENV_DESIRED=${2:-$TARGET_ENV}
    local PASSBOLT_ROOT_FOLDER=${3:-"forge"}

    [[ "$FORGE_DEBUG" == "1" ]] && echo "[FORGE] Verified PASSBOLT system binary: $PASSBOLT_BIN"
    if [[ -z "$FORGE_PASSBOLT_BIN" ]]; then
        echo "❌ Error: Neither 'go-passbolt-cli' nor 'passbolt' was found in your PATH." >&2
        exit 1
    fi

    local tmp_folders
    tmp_folders=$(mktemp)
    trap 'rm -f "$tmp_folders"' EXIT
    if [[ "$FORGE_DEBUG" == "1" ]]; then
        cat ../.forge_workspace/passbolt/.folders.json
    else
        $FORGE_PASSBOLT_BIN list folders --json
    fi > "$tmp_folders"

    ALL_PASSBOLT_ENTRY=$(jq -r --arg root "$PASSBOLT_ROOT_FOLDER" '.[] | select(.name == $root and (.folder_parent_id == null or .folder_parent_id == "")) | .id' "$tmp_folders")
    PASSBOLT_FOLDER_ROOT_ID=$(echo "$ALL_PASSBOLT_ENTRY" | head -n 1)
    MATCH_COUNT=$(echo "$ALL_PASSBOLT_ENTRY" | grep -v '^$' | wc -l)
    [[ $MATCH_COUNT -gt 1 ]] && echo "[ROOT] ⚠️ Warning: Found $MATCH_COUNT duplicate FOLDERS named '${PASSBOLT_ROOT_FOLDER}' at same level! 👉 Selecting the first discovered ID: $PASSBOLT_FOLDER_ROOT_ID"
    if [[ -z "$PASSBOLT_FOLDER_ROOT_ID" || "$PASSBOLT_FOLDER_ROOT_ID" == "null" ]]; then
        PASSBOLT_FOLDER_ROOT_ID=$("$FORGE_PASSBOLT_BIN" create folder -j -n "$PASSBOLT_ROOT_FOLDER" | jq -r '.id')
        echo "[FORGE] ROOT_ID returned empty: the folder ${PASSBOLT_ROOT_FOLDER} originally do not exist in passbolt. Creating the specific ROOT ID: ${PASSBOLT_FOLDER_ROOT_ID}."
    fi
    PASSBOLT_IDS["ROOT"]=$PASSBOLT_FOLDER_ROOT_ID

    ALL_PASSBOLT_ENTRY=$(jq -r --arg org "$FORGE_ORGANIZATION_ACRONYM" --arg root "$PASSBOLT_FOLDER_ROOT_ID" '.[] | select(.name == $org and .folder_parent_id == $root) | .id' "$tmp_folders")
    PASSBOLT_FOLDER_ORG_ID=$(echo "$ALL_PASSBOLT_ENTRY" | head -n 1)
    MATCH_COUNT=$(echo "$ALL_PASSBOLT_ENTRY" | grep -v '^$' | wc -l)
    if [[ $MATCH_COUNT -gt 1 ]]; then
        echo "[ORG ] ⚠️ Warning: Found $MATCH_COUNT duplicate FOLDERS named '${FORGE_ORGANIZATION_ACRONYM}' at same level! 👉 Selecting the first discovered ID: $PASSBOLT_FOLDER_ORG_ID"
        [[ "$FORGE_DEBUG" == "1" ]] && echo "[ORG ] ⚠️ Warning tracking full path: ROOT: ${PASSBOLT_FOLDER_ROOT_ID}"
    fi
    if [[ -z "$PASSBOLT_FOLDER_ORG_ID" || "$PASSBOLT_FOLDER_ORG_ID" == "null" ]]; then
        PASSBOLT_FOLDER_ORG_ID=$("$FORGE_PASSBOLT_BIN" create folder -j -n "$FORGE_ORGANIZATION_ACRONYM" -f "$PASSBOLT_FOLDER_ROOT_ID" | jq -r '.id')
        echo "[FORGE] ORG_ID returned empty: the folder ${FORGE_ORGANIZATION_ACRONYM} originally do not exist in passbolt. Creating the specific ORG ID: ${PASSBOLT_FOLDER_ORG_ID}."
    fi
    PASSBOLT_IDS["ORG"]=$PASSBOLT_FOLDER_ORG_ID

    ALL_PASSBOLT_ENTRY=$(jq -r --arg sys "$FORGE_SYSTEM_ACRONYM" --arg org "$PASSBOLT_FOLDER_ORG_ID" '.[] | select(.name == $sys and .folder_parent_id == $org) | .id' "$tmp_folders") # $FORGE_SYSTEM_ACRONYM -> river
    PASSBOLT_FOLDER_SYS_ID=$(echo "$ALL_PASSBOLT_ENTRY" | head -n 1)
    MATCH_COUNT=$(echo "$ALL_PASSBOLT_ENTRY" | grep -v '^$' | wc -l)
    if [[ $MATCH_COUNT -gt 1 ]]; then
        echo "[SYS ] ⚠️ Warning: Found $MATCH_COUNT duplicate FOLDERS named '${FORGE_SYSTEM_ACRONYM}' at same level! 👉 Selecting the first discovered ID: ${PASSBOLT_FOLDER_SYS_ID}"
        [[ "$FORGE_DEBUG" == "1" ]] && echo "[SYS ] ⚠️ Warning tracking full path: ${PASSBOLT_FOLDER_ORG_ID} -> ROOT: ${PASSBOLT_FOLDER_ROOT_ID}"
    fi
    if [[ -z "$PASSBOLT_FOLDER_SYS_ID" || "$PASSBOLT_FOLDER_SYS_ID" == "null" ]]; then
        PASSBOLT_FOLDER_SYS_ID=$("$FORGE_PASSBOLT_BIN" create folder -j -n "$FORGE_SYSTEM_ACRONYM" -f "$PASSBOLT_FOLDER_ORG_ID" | jq -r '.id')
        echo "[FORGE] SYS_ID returned empty: the folder ${FORGE_SYSTEM_ACRONYM} originally do not exist in passbolt. Creating the specific SYS ID: ${PASSBOLT_FOLDER_SYS_ID}."
    fi
    PASSBOLT_IDS["SYS"]=$PASSBOLT_FOLDER_SYS_ID

    ALL_PASSBOLT_ENTRY=$(jq -r --arg env "$ENV_DESIRED" --arg sys "$PASSBOLT_FOLDER_SYS_ID" '.[] | select(.name == $env and .folder_parent_id == $sys) | .id' "$tmp_folders") # $ENV_DESIRED -> local
    PASSBOLT_FOLDER_ENV_ID=$(echo "$ALL_PASSBOLT_ENTRY" | head -n 1)
    MATCH_COUNT=$(echo "$ALL_PASSBOLT_ENTRY" | grep -v '^$' | wc -l)
    if [[ $MATCH_COUNT -gt 1 ]]; then
        echo "[ENV ] ⚠️ Warning: Found $MATCH_COUNT duplicate FOLDERS named '${ENV_DESIRED}' at same level! 👉 Selecting the first discovered ID: ${PASSBOLT_FOLDER_ENV_ID}"
        [[ "$FORGE_DEBUG" == "1" ]] && echo "[ENV ] ⚠️ Warning tracking full path: ${PASSBOLT_FOLDER_SYS_ID} -> ${PASSBOLT_FOLDER_ORG_ID} -> ROOT: ${PASSBOLT_FOLDER_ROOT_ID}"
    fi
    if [[ -z "$PASSBOLT_FOLDER_ENV_ID" || "$PASSBOLT_FOLDER_ENV_ID" == "null" ]]; then
        PASSBOLT_FOLDER_ENV_ID=$("$FORGE_PASSBOLT_BIN" create folder -j -n "$ENV_DESIRED" -f "$PASSBOLT_FOLDER_SYS_ID" | jq -r '.id')
        echo "[FORGE] ENV_ID returned empty: the folder ${ENV_DESIRED} originally do not exist in passbolt. Creating the specific ENV ID: ${PASSBOLT_FOLDER_ENV_ID}."
    fi
    PASSBOLT_IDS["ENV"]=$PASSBOLT_FOLDER_ENV_ID

    print_banner "[${ENV_DESIRED}] PASSBOLT: ROOT_ID -> $PASSBOLT_FOLDER_ROOT_ID :: ORG_ID -> $PASSBOLT_FOLDER_ORG_ID :: SYS_ID -> $PASSBOLT_FOLDER_SYS_ID :: ENV_ID -> $PASSBOLT_FOLDER_ENV_ID"

    for filepath in .credentials/samples/.*example; do
        local FILE_SAMPLE="${filepath##*/}"
        FILE_SAMPLE="${FILE_SAMPLE%.target-env-example}"
        FILE_SAMPLE="${FILE_SAMPLE%.example}"
        local CLEAN_FILE_SAMPLE="${FILE_SAMPLE//./}"
        CLEAN_FILE_SAMPLE="${CLEAN_FILE_SAMPLE//-/_}"
        declare -n REF="CONF_FILE_ACRONYM[$CLEAN_FILE_SAMPLE]"

        [[ "$FILE_SAMPLE" == ".mise-en-place.conf" ]] && PARENT_FOLDER="$PASSBOLT_FOLDER_SYS_ID" || PARENT_FOLDER="$PASSBOLT_FOLDER_ENV_ID"
        ALL_PASSBOLT_ENTRY=$(jq -r --arg file_sample "$FILE_SAMPLE" --arg parent "$PARENT_FOLDER" '.[] | select(.name == $file_sample and .folder_parent_id == $parent) | .id' "$tmp_folders") # $FILE_SAMPLE -> .target-server (.mise-en-place.conf should be linked with folder system)
        PASSBOLT_FOLDER_FIL_ID=$(echo "$ALL_PASSBOLT_ENTRY" | head -n 1)
        MATCH_COUNT=$(echo "$ALL_PASSBOLT_ENTRY" | grep -v '^$' | wc -l)
        if [[ $MATCH_COUNT -gt 1 ]]; then
            echo "[${REF}] ⚠️ Warning: Found $MATCH_COUNT duplicate FOLDERS named '${FILE_SAMPLE}' at same level! 👉 Selecting the first discovered ID: $PASSBOLT_FOLDER_FIL_ID"
            [[ "$FORGE_DEBUG" == "1" ]] && echo "[${REF}] ⚠️ Warning tracking full path: PARENT: ${PARENT_FOLDER} :: ENV: ${PASSBOLT_FOLDER_ENV_ID} ($ENV_FILE) -> SYS: ${PASSBOLT_FOLDER_SYS_ID} -> ORG: ${PASSBOLT_FOLDER_ORG_ID} -> ROOT: ${PASSBOLT_FOLDER_ROOT_ID}"
        fi
        if [[ -z "$PASSBOLT_FOLDER_FIL_ID" || "$PASSBOLT_FOLDER_FIL_ID" == "null" ]]; then
            PASSBOLT_FOLDER_FIL_ID=$($FORGE_PASSBOLT_BIN create folder -j -f "$PARENT_FOLDER" -n "$FILE_SAMPLE" | jq -r '.id')
            echo "[FORGE] PASSBOLT_FOLDER_FIL_ID returned empty: the resource ${FILE_SAMPLE} originally do not exist in passbolt. Creating the specific RESOURCE ID: ${PASSBOLT_FOLDER_FIL_ID}."
        fi
        PASSBOLT_IDS["$REF"]="$PASSBOLT_FOLDER_FIL_ID"
        [[ "$FORGE_DEBUG" == "1" ]] && print_banner "[${REF}] FILE_SAMPLE -> ${FILE_SAMPLE} (${ENV_FILE}) :: ${REF} (${CLEAN_FILE_SAMPLE}) :: PASSBOLT_FOLDER_FIL_ID (${MATCH_COUNT}) -> ${PASSBOLT_FOLDER_FIL_ID} (^: ${PARENT_FOLDER})"
    done

    if [[ "$FORGE_DEBUG" == "1" ]]; then
        print_banner "[FORGE] Passbolt folder ids"
        for my_key in "${!PASSBOLT_IDS[@]}"; do
            my_value="${PASSBOLT_IDS[$my_key]}"
            echo "Key: $my_key -> Value: $my_value"
        done
    fi
}

get_passbolt_resource_ids() {
    # Grab all resources ID from passbolt using the default organization: forge -> ORGANIZATION -> SYSTEM -> ENVIRONMENT -> CONFIGURATION FILE
    # Each configuration file will have multiple resources with the name as the same as the key and in passworld will be stored the secret/sensible information (configuration itself)
    # [MANDATORY] $1 PASSBOLT_IDS            :: array where all data grabed will be stored.
    # [MANDATORY] $2 PASSBOLT_FOLDER_FIL_ID  :: set passbolt id of folder that has the resources
    # [MANDATORY] $3 FILE_SAMPLE             :: file sample tha will retrive all keys

    declare -n PASSBOLT_RES_IDS="$1"
    local REF="${2:-}"
    # FIXME test -z can be replace by another idiom
    if [[ -z "$REF" ]]; then
        echo "Can't go on: REF is empty!!"
        exit 1
    fi
    local PASSBOLT_FOLDER_FIL_ID="${3:-}"
    if [[ -z "$PASSBOLT_FOLDER_FIL_ID" ]]; then
        echo "Can't go on: PASSBOLT_FOLDER_FIL_ID is empty!!"
        exit 1
    fi
    local ENV_DESIRED="${4:-}"
    if [[ -z "$ENV_DESIRED" ]]; then
        echo "Can't go on: ENV_DESIRED is empty!!"
        exit 1
    fi
    local FILE_SAMPLE="${5:-}"
    if [[ -z "$FILE_SAMPLE" ]]; then
        echo "Can't go on: FILE_SAMPLE is empty!!"
        exit 1
    fi
    local ENV_FILE="${FILE_SAMPLE}$([[ "$FILE_SAMPLE" == ".mise-en-place.conf" ]] && echo "" || echo ".${ENV_DESIRED}")"
    [[ "$FORGE_DEBUG" == "" ]] && echo "[FORGE] PASSBOLT system binary $PASSBOLT_BIN :: PASSBOLT_FOLDER_FIL_ID -> ${PASSBOLT_FOLDER_FIL_ID} :: FILE_SAMPLE -> ${FILE_SAMPLE}"
    if [[ -z "$FORGE_PASSBOLT_BIN" ]]; then
        echo "❌ Error: Neither 'go-passbolt-cli' nor 'passbolt' was found in your PATH." >&2
        exit 1
    fi

    local tmp_resources
    tmp_resources=$(mktemp)
    trap 'rm -f "$tmp_resources"' EXIT
    if [[ "$FORGE_DEBUG" == "1" ]]; then
        cat ../.forge_workspace/passbolt/"${ENV_FILE}".resources.json
    else
        "${FORGE_PASSBOLT_BIN}" list resources --json --folder "$PASSBOLT_FOLDER_FIL_ID"
    fi > "$tmp_resources"

    case "$FILE_SAMPLE" in
        ".pgpass")
            KEYS=$(cat .credentials/samples/"$FILE_SAMPLE"*example | sed '1d' | grep -v '^#' | grep -v '^$' | awk -F: '{print $1"\n"$2"\n"$3"\n"$4"\n"$5}')
            ;;
        ".user_seeds.csv")
            KEYS=$(env | grep FORGE_USEEDS_ | cut -d = -f1 | grep -v '^FORGE_USEEDS_0_' | sed 's/^FORGE_USEEDS_//g' | sort  -h)
            ;;
        *)
            KEYS=$(cat .credentials/samples/"$FILE_SAMPLE"*example | sed '1d' | grep -v '^#' | grep -v '^$' | cut -d = -f1)
            ;;
    esac
    if [[ "$FORGE_DEBUG" == "1" ]]; then
        echo "$KEYS"
        echo "----------------------------------------------------- </KEYS> --------------------------------------------------------"
        echo "----------------------------------------------------- <RESULT>  ------------------------------------------------------"
    fi
    while read -r KEY; do
        [[ -z "$KEY" ]] && continue
        if [[ "$KEY" =~ [\<\>] ]]; then
            echo "[FORGE] ⚠️ Skipping invalid key name containing restricted characters: ${KEY}"
            continue
        fi
        local var_name="FORGE_${REF}_${KEY}"

        ALL_PASSBOLT_ENTRY=$(jq -r --arg key "$var_name" '.[] | select(.name == $key) | .id' "${tmp_resources}")
        PASSBOLT_RESOURCE_KEY_ID=$(echo "$ALL_PASSBOLT_ENTRY" | head -n 1)
        MATCH_COUNT=$(echo "$ALL_PASSBOLT_ENTRY" | grep -v '^$' | wc -l)
        if [[ $MATCH_COUNT -gt 1 ]]; then
            echo "[FORGE] ⚠️ Warning: Found $MATCH_COUNT duplicate RESOURCES named '${var_name}' at same level! 👉 Selecting the first discovered ID: ${PASSBOLT_RESOURCE_KEY_ID}"
            [[ "$FORGE_DEBUG" == "1" ]] && echo "[FORGE] ⚠️ Warning tracking full path: ${PASSBOLT_FOLDER_FIL_ID} (${FILE_SAMPLE}) -> PARENT: ${PARENT_FOLDER} :: ENV: ${PASSBOLT_FOLDER_ENV_ID} ($ENV_FILE) -> SYS: ${PASSBOLT_FOLDER_SYS_ID} -> ORG: ${PASSBOLT_FOLDER_ORG_ID} -> ROOT: ${PASSBOLT_FOLDER_ROOT_ID}"
        fi
        PASSBOLT_RES_IDS["$var_name"]=$PASSBOLT_RESOURCE_KEY_ID
        [[ "$FORGE_DEBUG" == "1" ]] && echo "[FORGE] KEY_ID is ${PASSBOLT_RESOURCE_KEY_ID} -> resource with name ${var_name} (${KEY})"
    done <<< "$KEYS"
    [[ "$FORGE_DEBUG" == "1" ]] && echo "----------------------------------------------------- </RESULT>  ------------------------------------------------------"
    [[ "$FORGE_DEBUG" == "1" ]] && echo ""
}
