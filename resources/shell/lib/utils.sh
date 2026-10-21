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

# TODO create a generic function to run passbolt commands, including with retries
get_passbolt_folder_ids() {
    # Grab all folders ID from passbolt using the default organization: forge -> ORGANIZATION -> SYSTEM -> ENVIRONMENT -> CONFIGURATION FILE
    # Each configuration file will have multiple resources with the name as the same as the key and in passworld will be stored the secret/sensible information (configuration itself)
    # [MANDATORY] $1 PASSBOLT_IDS         :: array where all data grabed will be stored.
    # [OPTIONAL]  $2 ENV_DESIRED          :: set the environmet that will be used. The dafult is use $TARGET_ENV
    # [OPTIONAL]  $3 PASSBOLT_ROOT_FOLDER :: the folder that will be the root of all to stored data into passbolt. Default value is: forge

    declare -n PASSBOLT_IDS="$1"
    local ENV_DESIRED=${2:-$TARGET_ENV}
    local PASSBOLT_ROOT_FOLDER=${3:-"${PASSBOLT_DEFAULT_ROOT_FOLDER}"}
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

    local PASSBOLT_FOLDERS=("${PASSBOLT_BASE_FOLDER_HIERARCHY[@]}" "${CONF_FILE_ACRONYM[@]}")
    for fld in "${PASSBOLT_FOLDERS[@]}"; do
        local PASSBOLT_IDS_KEY=$fld
        case $fld in
            "ROOT")
                ALL_PASSBOLT_ENTRY=$(jq -r --arg root "$PASSBOLT_ROOT_FOLDER" '.[] | select(.name == $root and (.folder_parent_id == null or .folder_parent_id == "")) | .id' "$tmp_folders")
                ;;
            "ORG")
                ALL_PASSBOLT_ENTRY=$(jq -r --arg org "$FORGE_ORGANIZATION_ACRONYM" --arg root "${PASSBOLT_IDS[ROOT]}" '.[] | select(.name == $org and .folder_parent_id == $root) | .id' "$tmp_folders")
                ;;
            "SYS")
                ALL_PASSBOLT_ENTRY=$(jq -r --arg sys "$FORGE_SYSTEM_ACRONYM" --arg org "${PASSBOLT_IDS[ORG]}" '.[] | select(.name == $sys and .folder_parent_id == $org) | .id' "$tmp_folders") # $FORGE_SYSTEM_ACRONYM -> river
                ;;
            "ENV")
                ALL_PASSBOLT_ENTRY=$(jq -r --arg env "$ENV_DESIRED" --arg sys "${PASSBOLT_IDS[SYS]}" '.[] | select(.name == $env and .folder_parent_id == $sys) | .id' "$tmp_folders") # $ENV_DESIRED -> local
                PASSBOLT_IDS_KEY="$ENV_DESIRED"
                ;;
            *)
                local matched=false
                for acronym in "${CONF_FILE_ACRONYM[@]}"; do
                    if [[ "$fld" == "$acronym" ]]; then
                        matched=true
                        break
                    fi
                done

                if [ "$matched" = true ]; then
                    [[ "$fld" == "MIENPL" ]] && PARENT_FOLDER="${PASSBOLT_IDS[SYS]}" || PARENT_FOLDER="${PASSBOLT_IDS[$ENV_DESIRED]}"
                    ALL_PASSBOLT_ENTRY=$(jq -r --arg file_sample "${CONF_FILE_CANONICAL_NAME[$fld]}" --arg parent "$PARENT_FOLDER" '.[] | select(.name == $file_sample and .folder_parent_id == $parent) | .id' "$tmp_folders") # $FILE_SAMPLE -> .target-server (.mise-en-place.conf should be linked with folder system)
                else
                    echo "Value of fld ${fld} not foreseen. Exiting..."
                    exit 1
                fi
                ;;
        esac

        PASSBOLT_IDS["${PASSBOLT_IDS_KEY}"]=$(echo "$ALL_PASSBOLT_ENTRY" | head -n 1)
        MATCH_COUNT=$(echo "$ALL_PASSBOLT_ENTRY" | grep -v '^$' | wc -l)
        [[ $MATCH_COUNT -gt 1 ]] && echo "[ROOT] ⚠️ Warning: Found $MATCH_COUNT duplicate FOLDERS named '${PASSBOLT_IDS[${PASSBOLT_IDS_KEY}]}' at same level! 👉 Selecting the first discovered ID: ${PASSBOLT_IDS[${PASSBOLT_IDS_KEY}]}"
        if [[ -z "${PASSBOLT_IDS[${PASSBOLT_IDS_KEY}]}" || "${PASSBOLT_IDS[${PASSBOLT_IDS_KEY}]}" == "null" ]]; then
            local passbolt_output
            if ! passbolt_output=$("$FORGE_PASSBOLT_BIN" create folder -j -n "${PASSBOLT_IDS[${PASSBOLT_IDS_KEY}]}" 2>&1); then
                echo "[FORGE] Fatal: Passbolt command execution failed for folder '${PASSBOLT_IDS[${PASSBOLT_IDS_KEY}]}' -> $passbolt_output" >&2
                exit 1
            fi
            local jq_output
            jq_output=$(echo "$passbolt_output" | jq -r '.id' 2>/dev/null)
            if [[ -z "$jq_output" || "$jq_output" == "null" ]]; then
                echo "[FORGE] jq failed to parse pasbolt's response: $passbolt_output" >&2
                exit 1
            fi
            PASSBOLT_IDS["${PASSBOLT_IDS_KEY}"]="$jq_output"
            echo "[FORGE] ${fld}_ID returned empty: the folder ${fld} originally do not exist in passbolt. Creating the specific ${fld}_ID: ${PASSBOLT_IDS[${PASSBOLT_IDS_KEY}]}."
        fi
        [[ "$FORGE_DEBUG" == "1" ]] && echo "PASSBOLT_IDS[${PASSBOLT_IDS_KEY}] -> ${PASSBOLT_IDS[${PASSBOLT_IDS_KEY}]} :: MATCH_COUNT -> ${MATCH_COUNT}"
    done

    print_banner "[${ENV_DESIRED}] ROOT -> ${PASSBOLT_IDS[ROOT]} :: ORG -> ${PASSBOLT_IDS[ORG]} :: SYS -> ${PASSBOLT_IDS[SYS]} :: ENV(${PASSBOLT_IDS_KEY}) -> ${PASSBOLT_IDS[$PASSBOLT_IDS_KEY]}"
}

get_passbolt_resource_ids() {
    # Grab all resources ID from passbolt using the default organization: forge -> ORGANIZATION -> SYSTEM -> ENVIRONMENT -> CONFIGURATION FILE
    # Each configuration file will have multiple resources with the name as the same as the key and in passworld will be stored the secret/sensible information (configuration itself)
    # [MANDATORY] $1 PASSBOLT_IDS             :: array where all data grabed will be stored.
    # [MANDATORY] $2 PASSBOLT_CALC_FOLDER_IDS :: array to get passbolt id of folder that has the resources
    # [MANDATORY] $3 ACRONYM                  :: acronym tha will retrive all keys
    # [OPTIONAL]  $4 ENV_DESIRED              :: set the environmet that will be used. The dafult is use $TARGET_ENV
    

    declare -n PASSBOLT_RES_IDS="$1"
    declare -n PASSBOLT_CALC_FOLDER_IDS="$2"
    # local PASSBOLT_FOLDER_FIL_ID="${3:-}"
    # if [[ -z "$PASSBOLT_FOLDER_FIL_ID" ]]; then
    #     echo "Can't go on: PASSBOLT_FOLDER_FIL_ID is empty!!"
    #     exit 1
    # fi
    local ACRONYM="${3:-}"
    # FIXME test -z can be replace by another idiom
    if [[ -z "$ACRONYM" ]]; then
        echo "Can't go on: ACRONYM is empty!!"
        exit 1
    fi
    local ENV_DESIRED=${4:-$TARGET_ENV}
    if [[ -z "$ENV_DESIRED" ]]; then
        echo "Can't go on: ENV_DESIRED is empty!!"
        exit 1
    fi
    local FILE_SAMPLE="${CONF_FILE_CANONICAL_NAME[$ACRONYM]}"
    local ENV_FILE="${FILE_SAMPLE}$([[ "$FILE_SAMPLE" == ".mise-en-place.conf" ]] && echo "" || echo ".${ENV_DESIRED}")"
    local REF="${CONF_FILE_ACRONYM_BY_FILENAME[${FILE_SAMPLE}]}"
    local PASSBOLT_FOLDER_FIL_ID="${PASSBOLT_CALC_FOLDER_IDS[$REF]}"
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
        # [[ "$FORGE_DEBUG" == "1" ]] && echo "[FORGE] KEY_ID is ${PASSBOLT_RESOURCE_KEY_ID} -> resource with name ${var_name} (${KEY})"
    done <<< "$KEYS"
    # [[ "$FORGE_DEBUG" == "1" ]] && echo "----------------------------------------------------- </RESULT>  ------------------------------------------------------"
    # [[ "$FORGE_DEBUG" == "1" ]] && echo ""
}
