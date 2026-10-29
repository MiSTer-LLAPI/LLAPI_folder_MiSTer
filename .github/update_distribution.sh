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


# Current experimental controller test; replaces earlier updater pilots.
install_1943_llapi_snac_pilot() {
    local TARGET_DIR="${1}"
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/v1943-llapi-snac-20261029-2p"
    local TMP_PILOT
    TMP_PILOT="$(mktemp -d)"
    # Prefer the OSD-pause correction only after it is publicly released.
    # Until then, retain the previously validated controller build.
    local PAUSE_TAG="v1943-llapi-snac-20261029-osd-pause"
    local PAUSE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/${PAUSE_TAG}"
    if curl -fsSL "https://api.github.com/repos/MiSTer-LLAPI/jtcores/releases/tags/${PAUSE_TAG}" -o "${TMP_PILOT}/release.json" 2>/dev/null; then
        python3 - "${TMP_PILOT}" <<'PYCODE'
import json,re,sys
from pathlib import Path
p=Path(sys.argv[1]); d=json.loads((p/'release.json').read_text())
assert d['tag_name']=='v1943-llapi-snac-20261029-osd-pause' and not d['draft']
names=['jt1943_llapi_snac_20261029_pause.rbf','1943-LLAPI-SNAC-Test.mra','timing-acceptance.json']
lines=[]
for name in names:
    a=[a for a in d['assets'] if a['name']==name]
    assert len(a)==1 and re.fullmatch(r'sha256:[0-9a-f]{64}',a[0].get('digest') or '')
    lines.append(a[0]['digest'][7:]+'  '+name)
(p/'accepted-assets.sha256').write_text('\n'.join(lines)+'\n')
PYCODE
        curl -fsSL "${PAUSE_URL}/jt1943_llapi_snac_20261029_pause.rbf" -o "${TMP_PILOT}/jt1943_llapi_snac_20261029_pause.rbf"
        curl -fsSL "${PAUSE_URL}/1943-LLAPI-SNAC-Test.mra" -o "${TMP_PILOT}/1943-LLAPI-SNAC-Test.mra"
        curl -fsSL "${PAUSE_URL}/timing-acceptance.json" -o "${TMP_PILOT}/timing-acceptance.json"
        (cd "${TMP_PILOT}" && sha256sum -c accepted-assets.sha256)
        python3 - "${TMP_PILOT}" <<'PYCODE'
import json,sys,xml.etree.ElementTree as ET
from pathlib import Path
p=Path(sys.argv[1]);d=json.loads((p/'timing-acceptance.json').read_text())
required={'setup','hold','recovery','removal','minimum pulse width'}
assert d['accepted'] and required.issubset(d['worst_slack_ns'])
assert all(v>=0 for v in d['worst_slack_ns'].values())
assert ET.parse(p/'1943-LLAPI-SNAC-Test.mra').findtext('rbf')=='jt1943_llapi_snac_20261029_pause'
PYCODE
        copy_file "${TMP_PILOT}/jt1943_llapi_snac_20261029_pause.rbf" "${TARGET_DIR}/_LLAPI/cores/jt1943_llapi_snac_20261029_pause.rbf"
        copy_file "${TMP_PILOT}/1943-LLAPI-SNAC-Test.mra" "${TARGET_DIR}/_LLAPI/_Arcade/1943-LLAPI-Test.mra"
        rm -f "${TARGET_DIR}/_LLAPI/cores/jt1943_llapi_snac_20261029.rbf"
        rm -rf "${TMP_PILOT}"
        return
    fi
    curl -fsSL "${RELEASE_URL}/jt1943_llapi_snac_20261029_test.rbf" -o "${TMP_PILOT}/jt1943_llapi_snac_20261029.rbf"
    curl -fsSL "${RELEASE_URL}/1943-LLAPI-SNAC-Test.mra" -o "${TMP_PILOT}/1943-LLAPI-Test.mra"
    printf '%s\n' \
        '6571e3d34449677502035f9b82af2bac0dc04c19268f32215c687264038a6e17  jt1943_llapi_snac_20261029.rbf' \
        'f67f5879f6d62aebf32492d5261dd7965691795dd11f652a5e8a947ade80da57  1943-LLAPI-Test.mra' \
        | (cd "${TMP_PILOT}" && sha256sum -c -)
    copy_file "${TMP_PILOT}/jt1943_llapi_snac_20261029.rbf" "${TARGET_DIR}/_LLAPI/cores/jt1943_llapi_snac_20261029.rbf"
    copy_file "${TMP_PILOT}/1943-LLAPI-Test.mra" "${TARGET_DIR}/_LLAPI/_Arcade/1943-LLAPI-Test.mra"
    rm -rf "${TMP_PILOT}"
}


# Explicit experimental Amiga variants; retain the existing stable Amiga core.
install_amiga_experimental() {
    local TARGET_DIR="${1}" TMP_AMIGA ASSET
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/Minimig-AGA_MiSTer/releases/download/amiga-llapi-snac-20261029-accepted"
    TMP_AMIGA="$(mktemp -d)"
    cat > "${TMP_AMIGA}/expected.sha256" <<'SUMS'
4a98b08637a0b38552b08359df7a31ad2d61e8ad4e9e09c5b2160148303debdb  Amiga_LLAPI-2P_20261029_experimental.rbf
572b6bc07465c48f7eaec674b58ca070821f7c514ffb8e29169cf7dc92964ceb  Amiga_SNAC-DB15-2P_20261029_experimental.rbf
4f101a185007defd9f1bbc844b82e2d0df6178eed7e8cc9bdfe59df388552ed2  Amiga_SNAC-SNES-2P_20261029_experimental.rbf
dace04e46e532214099338dbfe02af0482ae9a45842d5daf10f5a525771a5727  Amiga_SNAC-SATURN-1P_20261029_experimental.rbf
779dabfec574add1ca68ca288397ca5d368f94b78f27a322c53d4b2d032444d3  AVAILABLE-BUILDS.md
da49c91a7e41f7eecc4289ec10504199df789d11fff154b75fc4adb32c2188b8  timing-acceptance.json
SUMS
    while read -r digest ASSET; do
        curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_AMIGA}/${ASSET}"
    done < "${TMP_AMIGA}/expected.sha256"
    (cd "${TMP_AMIGA}" && sha256sum -c expected.sha256)
    python3 - "${TMP_AMIGA}" <<'PYCODE'
import json,math,sys
from pathlib import Path
p=Path(sys.argv[1]); data=json.loads((p/'timing-acceptance.json').read_text())
required={'setup','hold','recovery','removal','minimum pulse width'}
for mode in ['LLAPI-2P','SNAC-DB15-2P','SNAC-SNES-2P','SNAC-SATURN-1P']:
    d=data[mode]
    assert d['accepted'] and required.issubset(d['worst_slack_ns'])
    assert all(math.isfinite(v) and v>=0 for v in d['worst_slack_ns'].values())
PYCODE
    for ASSET in "${TMP_AMIGA}"/Amiga_*.rbf; do
        copy_file "${ASSET}" "${TARGET_DIR}/_LLAPI/_Amiga_Experimental/${ASSET##*/}"
    done
    copy_file "${TMP_AMIGA}/AVAILABLE-BUILDS.md" "${TARGET_DIR}/docs/Amiga-LLAPI-Experimental/AVAILABLE-BUILDS.md"
    copy_file "${TMP_AMIGA}/timing-acceptance.json" "${TARGET_DIR}/docs/Amiga-LLAPI-Experimental/timing-acceptance.json"
    rm -rf "${TMP_AMIGA}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}" ""
    install_1943_llapi_snac_pilot "${1}"
    install_amiga_experimental "${1}"
fi

