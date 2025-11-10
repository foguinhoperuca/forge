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
