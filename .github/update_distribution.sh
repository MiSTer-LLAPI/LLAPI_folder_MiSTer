#!/usr/bin/env bash
# Copyright (c) 2021 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

curl -o /tmp/update_distribution.source "https://raw.githubusercontent.com/MiSTer-devel/Distribution_MiSTer/main/.github/update_distribution.sh"

source /tmp/update_distribution.source
rm /tmp/update_distribution.source

curl -o /tmp/calculate_db.py "https://raw.githubusercontent.com/MiSTer-devel/Distribution_MiSTer/develop/.github/calculate_db.py"
chmod +x /tmp/calculate_db.py

files_with_stripped_date() {
    local FOLDER="${1}"
    pushd "${FOLDER}" > /dev/null 2>&1
    for file in *; do
        local WITH_DATE="${file%.*}"
        if [[ "${WITH_DATE}" =~ ^.+_([0-9]{8})$ ]] && [[ "${WITH_DATE}" =~ LLAPI ]] ; then
            echo "${WITH_DATE%%?????????}"
        fi
    done
    popd > /dev/null 2>&1
}

CORE_URLS=
fetch_core_urls() {
    local MISTER_URL="https://github.com/MiSTer-LLAPI/Updater_script_MiSTer"
    CORE_URLS="user-content-consoles---classic"$'\n'$(curl -sSLf "$MISTER_URL/wiki"| grep -ioE '(https://github.com/[a-zA-Z0-9./_-]*[_-]MiSTer/tree/[_a-zA-Z0-9-]+)|(https://github.com/[a-zA-Z0-9./_-]*[_-]MiSTer)|(user-content-[a-zA-Z0-9-]*)' | sed '/^.*Updater_script_MiSTer.*/d' | sed '/^user-.*/d')
    CORE_URLS=${CORE_URLS}$'\n'"user-content-arcade-cores"$'\n'$(curl -sSLf "$MISTER_URL/wiki/Arcade-Cores-List"| grep -ioE '(https://github.com/[a-zA-Z0-9./_-]*[_-]MiSTer/tree/[_a-zA-Z0-9-]+)|(https://github.com/[a-zA-Z0-9./_-]*[_-]MiSTer)|(user-content-[a-zA-Z0-9-]*)' | sed '/^.*Updater_script_MiSTer.*/d' | sed '/^user-.*/d')
}

install_console_core() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    for bin in $(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq) ; do

        if is_arcade_core "${bin}" ; then
            continue
        fi
        
        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/_LLAPI/${LAST_RELEASE_FILE}"
    done
}

install_arcade_core() {
    local TMP_FOLDER="${1}"
    local TARGET_DIR="${2}"
    local IFS=$'\n'

    if [ ! -d "${TMP_FOLDER}/releases" ] ; then
        return
    fi

    local BINARY_NAMES=$(files_with_stripped_date "${TMP_FOLDER}/releases" | uniq)
    if [[ "${BINARY_NAMES}" == "MRA-Alternatives" ]] ; then
        return
    fi
    
    local ARCADE_INSTALLED="false"

    for bin in ${BINARY_NAMES} ; do

        get_latest_release "${TMP_FOLDER}" "${bin}"
        local LAST_RELEASE_FILE="${GET_LATEST_RELEASE_RET}"

        if is_not_rbf_release "${LAST_RELEASE_FILE}" ; then
            continue
        fi

        if is_arcade_core "${bin}" ; then
            ARCADE_INSTALLED="true"
        elif [[ "${ARCADE_INSTALLED}" == "true" ]] ; then
            continue
        fi

        copy_file "${TMP_FOLDER}/releases/${LAST_RELEASE_FILE}" "${TARGET_DIR}/_LLAPI/cores/${LAST_RELEASE_FILE#Arcade-}"
    done

    for mra in $(mra_files "${TMP_FOLDER}/releases") ; do
        copy_file "${TMP_FOLDER}/releases/${mra}" "${TARGET_DIR}/_LLAPI/_Arcade/${mra}"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}" "${2:-}"
fi
