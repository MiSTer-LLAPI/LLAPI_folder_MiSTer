#!/usr/bin/env bash
# Copyright (c) 2021-2022 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

source .github/update_distribution_devel.sh

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


# Experimental 1943 LLAPI pilot from the public jtcores release.
# Keep these pinned to the reviewed binaries; never import all JTCORES games.
install_1943_llapi_pilot() {
    local TARGET_DIR="${1}"
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/v1943-llapi-20261028-experimental"
    local TMP_PILOT
    TMP_PILOT="$(mktemp -d)"
    curl -fsSL "${RELEASE_URL}/jt1943_llapi_20261028_test.rbf" -o "${TMP_PILOT}/jt1943_llapi_20261028.rbf"
    curl -fsSL "${RELEASE_URL}/1943-LLAPI-Test.mra" -o "${TMP_PILOT}/1943-LLAPI-Test.mra"
    printf '%s\n' \
        '95a2bddf19d2d7c4ace8f0a5d784cb95533beab1bc3b5ffe7db1f356c23d42ce  jt1943_llapi_20261028.rbf' \
        '9d996db060917e5b6775342a46a3c09176a390e78bb0fe947583e5a104e0d196  1943-LLAPI-Test.mra' \
        | (cd "${TMP_PILOT}" && sha256sum -c -)
    copy_file "${TMP_PILOT}/jt1943_llapi_20261028.rbf" "${TARGET_DIR}/_LLAPI/cores/jt1943_llapi_20261028.rbf"
    copy_file "${TMP_PILOT}/1943-LLAPI-Test.mra" "${TARGET_DIR}/_LLAPI/_Arcade/1943-LLAPI-Test.mra"
    rm -rf "${TMP_PILOT}"
}

# Additional experimental SNAC build; preserve the tested LLAPI-only entry.
install_1943_llapi_snac_pilot() {
    local TARGET_DIR="${1}"
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/v1943-llapi-snac-20261028-experimental"
    local TMP_PILOT
    TMP_PILOT="$(mktemp -d)"
    curl -fsSL "${RELEASE_URL}/jt1943_llapi_snac_20261028_test.rbf" -o "${TMP_PILOT}/jt1943_llapi_snac_20261028.rbf"
    curl -fsSL "${RELEASE_URL}/1943-LLAPI-SNAC-Test.mra" -o "${TMP_PILOT}/1943-LLAPI-SNAC-Test.mra"
    printf '%s\n' \
        '5cce0c30c78d194cadbe6b167f97b65f5f381a72dd8f897a388fd1116900d9b1  jt1943_llapi_snac_20261028.rbf' \
        'f67f5879f6d62aebf32492d5261dd7965691795dd11f652a5e8a947ade80da57  1943-LLAPI-SNAC-Test.mra' \
        | (cd "${TMP_PILOT}" && sha256sum -c -)
    copy_file "${TMP_PILOT}/jt1943_llapi_snac_20261028.rbf" "${TARGET_DIR}/_LLAPI/cores/jt1943_llapi_snac_20261028.rbf"
    copy_file "${TMP_PILOT}/1943-LLAPI-SNAC-Test.mra" "${TARGET_DIR}/_LLAPI/_Arcade/1943-LLAPI-SNAC-Test.mra"
    rm -rf "${TMP_PILOT}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}" ""
    install_1943_llapi_pilot "${1}"
    install_1943_llapi_snac_pilot "${1}"
fi

