#!/usr/bin/env bash
# Copyright (c) 2021 José Manuel Barroso Galindo <theypsilon@gmail.com>

set -euo pipefail

curl -o /tmp/update_distribution.source "https://raw.githubusercontent.com/MiSTer-devel/Distribution_MiSTer/main/.github/update_distribution.sh"

source /tmp/update_distribution.source
rm /tmp/update_distribution.source

curl -o /tmp/calculate_db.py "https://raw.githubusercontent.com/MiSTer-devel/Distribution_MiSTer/develop/.github/calculate_db.py"
chmod +x /tmp/calculate_db.py

update_distribution() {
    local OUTPUT_FOLDER="${1}"
    local PUSH_COMMAND="${2:-}"

    fetch_core_urls

    for url in ${CORE_URLS[@]} ; do
        process_url "${url}" "${OUTPUT_FOLDER}"
    done

    if [[ "${PUSH_COMMAND}" == "--push" ]] ; then
        git checkout -f develop -b main
        echo "Running detox"
        detox -v -s utf_8-only -r *
        echo "Detox done"
        git add "${OUTPUT_FOLDER}"
        git commit -m "-"
        git fetch origin main || true
        if ! git diff --exit-code main origin/main^ ; then
            echo "Calculating db..."
            /tmp/calculate_db.py
        else
            echo "Nothing to be updated."
        fi
    fi
}

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
    CORE_URLS=$(curl -sSLf "$MISTER_URL/wiki"| grep -ioE '(https://github.com/[a-zA-Z0-9./_-]*[_-]MiSTer/tree/[_a-zA-Z0-9-]+)|(https://github.com/[a-zA-Z0-9./_-]*[_-]MiSTer)|(user-content-[a-zA-Z0-9-]*)' | sed '/^.*Updater_script_MiSTer.*/d' | sed '/^user-.*/d')
}

process_url() {
    local URL="${1}"
    local TARGET_DIR="${2}"

    if ! [[ ${URL} =~ ^([a-zA-Z]+://)?github.com(:[0-9]+)?/([a-zA-Z0-9_-]*)/([a-zA-Z0-9_-]*)(/tree/([a-zA-Z0-9_-]+))?$ ]] ; then
        >&2 echo "WARNING! Wrong repository url '${URL}'."
        return
    fi

    local GITHUB_OWNER="${BASH_REMATCH[3]}"
    local GITHUB_REPO="${BASH_REMATCH[4]}"
    local GITHUB_BRANCH="${BASH_REMATCH[6]:-}"

    local TMP_FOLDER="$(mktemp -d)"

    download_repository "${TMP_FOLDER}" "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}.git" "${GITHUB_BRANCH}"

    install_other_core "${TMP_FOLDER}" "${TARGET_DIR}" "_LLAPI"

    rm -rf "${TMP_FOLDER}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}" "${2:-}"
fi
