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
