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
    local TARGET_DIR="${1}" TMP_PILOT
    local TAG="v1943-llapi-snac-20261030-freebuttons-experimental"
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/${TAG}"
    TMP_PILOT="$(mktemp -d)"
    if ! curl -fsSL "https://api.github.com/repos/MiSTer-LLAPI/jtcores/releases/tags/${TAG}" -o "${TMP_PILOT}/release.json"; then
        rm -rf "${TMP_PILOT}"
        return 1
    fi
    python3 - "${TMP_PILOT}" <<'PYCODE'
import json,re,sys
from pathlib import Path
p=Path(sys.argv[1]); d=json.loads((p/'release.json').read_text())
assert d['tag_name']=='v1943-llapi-snac-20261030-freebuttons-experimental' and not d['draft']
names=['jt1943_llapi_snac_20261030_freebuttons.rbf','1943-LLAPI-SNAC-Test.mra','timing-acceptance.json']
lines=[]
for name in names:
    a=[a for a in d['assets'] if a['name']==name]
    assert len(a)==1 and re.fullmatch(r'sha256:[0-9a-f]{64}',a[0].get('digest') or '')
    lines.append(a[0]['digest'][7:]+'  '+name)
(p/'accepted-assets.sha256').write_text('\n'.join(lines)+'\n')
PYCODE
    local ASSET
    for ASSET in jt1943_llapi_snac_20261030_freebuttons.rbf 1943-LLAPI-SNAC-Test.mra timing-acceptance.json; do
        curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_PILOT}/${ASSET}"
    done
    (cd "${TMP_PILOT}" && sha256sum -c accepted-assets.sha256)
    python3 - "${TMP_PILOT}" <<'PYCODE'
import json,math,sys,xml.etree.ElementTree as ET
from pathlib import Path
p=Path(sys.argv[1]); d=json.loads((p/'timing-acceptance.json').read_text())
required={'setup','hold','recovery','removal','minimum pulse width'}
assert d['accepted'] and required.issubset(d['worst_slack_ns'])
assert all(math.isfinite(v) and v>=0 for v in d['worst_slack_ns'].values())
m=ET.parse(p/'1943-LLAPI-SNAC-Test.mra')
assert m.findtext('rbf')=='jt1943_llapi_snac_20261030_freebuttons'
assert m.findtext('setname')=='1943'
PYCODE
    rm -f "${TARGET_DIR}/_LLAPI/cores/"jt1943_llapi_snac*.rbf
    copy_file "${TMP_PILOT}/jt1943_llapi_snac_20261030_freebuttons.rbf" "${TARGET_DIR}/_LLAPI/cores/jt1943_llapi_snac_20261030_freebuttons.rbf"
    copy_file "${TMP_PILOT}/1943-LLAPI-SNAC-Test.mra" "${TARGET_DIR}/_LLAPI/_Arcade/1943-LLAPI-Test.mra"
    rm -rf "${TMP_PILOT}"
}


# Experimental Amiga LLAPI only; SNAC variants withdrawn from this catalogue.
install_amiga_experimental() {
    local TARGET_DIR="${1}" TMP_AMIGA
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/Minimig-AGA_MiSTer/releases/download/amiga-llapi-snac-20261029-accepted"
    local ASSET="Amiga_LLAPI-2P_20261029_experimental.rbf"
    TMP_AMIGA="$(mktemp -d)"
    curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_AMIGA}/${ASSET}"
    printf '%s\n' '4a98b08637a0b38552b08359df7a31ad2d61e8ad4e9e09c5b2160148303debdb  Amiga_LLAPI-2P_20261029_experimental.rbf' | (cd "${TMP_AMIGA}" && sha256sum -c -)
    copy_file "${TMP_AMIGA}/${ASSET}" "${TARGET_DIR}/_LLAPI/_Experimental/${ASSET}"
    mkdir -p "${TARGET_DIR}/docs/Amiga-LLAPI-Experimental"
    cat > "${TARGET_DIR}/docs/Amiga-LLAPI-Experimental/AVAILABLE-BUILDS.md" <<'DOC'
# Amiga LLAPI 2P — experimental
Only Amiga_LLAPI-2P_20261029_experimental.rbf is distributed here. The SNAC variants have been withdrawn at the maintainer's request.
Uses the official MiSTer Main. Compilation and timing passed; hardware testing is pending. USER is dedicated to LLAPI, so physical floppy / MT32-pi are disabled in this RBF. Virtual ADF/HDF remain available. For USER MIDI/floppy peripherals use the official Amiga core.
Source: https://github.com/MiSTer-LLAPI/Minimig-AGA_MiSTer/tree/f48ad51a2305130e01aff89804ac248eeb43eeae
Original authors and licenses are preserved. No Kickstart or game data is included.
DOC
    rm -rf "${TMP_AMIGA}"
}

# Install only the named, timing-accepted 1944 experimental release.
install_1944_llapi_snac_pilot() {
    local TARGET_DIR="${1}" TMP_PILOT
    local TAG="v1944-llapi-snac-20261030-freebuttons-experimental"
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/${TAG}"
    TMP_PILOT="$(mktemp -d)"
    if ! curl -fsSL "https://api.github.com/repos/MiSTer-LLAPI/jtcores/releases/tags/${TAG}" -o "${TMP_PILOT}/release.json"; then
        rm -rf "${TMP_PILOT}"
        return 1
    fi
    python3 - "${TMP_PILOT}" <<'PYCODE'
import json,re,sys
from pathlib import Path
p=Path(sys.argv[1]); d=json.loads((p/'release.json').read_text())
assert d['tag_name']=='v1944-llapi-snac-20261030-freebuttons-experimental' and not d['draft']
names=['jt1944_llapi_snac_20261030_freebuttons.rbf','1944-LLAPI-Test.mra','timing-acceptance.json']
lines=[]
for name in names:
    a=[a for a in d['assets'] if a['name']==name]
    assert len(a)==1 and re.fullmatch(r'sha256:[0-9a-f]{64}',a[0].get('digest') or '')
    lines.append(a[0]['digest'][7:]+'  '+name)
(p/'accepted-assets.sha256').write_text('\n'.join(lines)+'\n')
PYCODE
    local ASSET
    for ASSET in jt1944_llapi_snac_20261030_freebuttons.rbf 1944-LLAPI-Test.mra timing-acceptance.json; do
        curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_PILOT}/${ASSET}"
    done
    (cd "${TMP_PILOT}" && sha256sum -c accepted-assets.sha256)
    python3 - "${TMP_PILOT}" <<'PYCODE'
import json,math,sys,xml.etree.ElementTree as ET
from pathlib import Path
p=Path(sys.argv[1]); d=json.loads((p/'timing-acceptance.json').read_text())
required={'setup','hold','recovery','removal','minimum pulse width'}
assert d['accepted'] and required.issubset(d['worst_slack_ns'])
assert all(math.isfinite(v) and v>=0 for v in d['worst_slack_ns'].values())
m=ET.parse(p/'1944-LLAPI-Test.mra')
assert m.findtext('rbf')=='jt1944_llapi_snac'
assert m.findtext('setname')=='1944'
PYCODE
    rm -f "${TARGET_DIR}/_LLAPI/cores/"jt1944_llapi_snac*.rbf
    copy_file "${TMP_PILOT}/jt1944_llapi_snac_20261030_freebuttons.rbf" "${TARGET_DIR}/_LLAPI/cores/jt1944_llapi_snac_20261030_freebuttons.rbf"
    copy_file "${TMP_PILOT}/1944-LLAPI-Test.mra" "${TARGET_DIR}/_LLAPI/_Arcade/1944-LLAPI-Test.mra"
    rm -rf "${TMP_PILOT}"
}

# Experimental PSX: only explicitly accepted hardware variants are listed here.
install_psx_experimental() {
    local TARGET_DIR="${1}" TMP_PSX
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/PSX_MiSTer/releases/download/v2026.10.31-llapi-rumble-normal-dual-experimental"
    local ASSET="PSX_LLAPI_normal_dual_20261031_seed3_experimental.rbf"
    TMP_PSX="$(mktemp -d)"
    curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_PSX}/${ASSET}"
    curl -fsSL "${RELEASE_URL}/TIMING.json" -o "${TMP_PSX}/TIMING.json"
    printf '%s\n' 'b434654eb4f9b76ee1f60de0b6a2bc477475c425b310809e2c5ed71129b6b79d  PSX_LLAPI_normal_dual_20261031_seed3_experimental.rbf' | (cd "${TMP_PSX}" && sha256sum -c -)
    python3 - "${TMP_PSX}/TIMING.json" <<'PYCODE'
import json,math,sys
d=json.load(open(sys.argv[1]))
required={'setup','hold','recovery','removal','minimum pulse width'}
assert d['accepted'] and required.issubset(d['worst_slack_ns'])
assert all(math.isfinite(v) and v>=0 for v in d['worst_slack_ns'].values())
PYCODE
    copy_file "${TMP_PSX}/${ASSET}" "${TARGET_DIR}/_LLAPI/_Experimental/${ASSET}"
    mkdir -p "${TARGET_DIR}/docs/PSX-LLAPI-Experimental"
    cat > "${TARGET_DIR}/docs/PSX-LLAPI-Experimental/AVAILABLE-BUILDS.md" <<'DOC'
# PSX LLAPI rumble — experimental
This build requires Dual SDRAM hardware and uses normal CPU speed. Do not use it on Single SDRAM hardware. The filename explicitly identifies both properties.
Rumble is OFF by default (OSD LLAPI rumble test). Combined finite jolts only; independent motor intensity is not supported. OSD disconnects LLAPI; effect expiry depends on adapter firmware. Physical testing remains pending.
Quartus compilation and five timing categories passed. Setup margin is only +0.007 ns.
Compiled source: c16632f952811a60b66c6cbf1b54a23bd14bd112 plus ONLY the attached QSF SEED 2 to 3 patch. No RTL/clocks/SDC/features changed.
Release, source, patch, license, checksums and reports: https://github.com/MiSTer-LLAPI/PSX_MiSTer/releases/tag/v2026.10.31-llapi-rumble-normal-dual-experimental
Other normal/2xCPU and Single/Dual variants will be included only after compilation and all timing checks pass. No BIOS or game data is included.
DOC
    rm -rf "${TMP_PSX}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}" ""
    install_1943_llapi_snac_pilot "${1}"
    install_amiga_experimental "${1}"
    install_psx_experimental "${1}"
    install_1944_llapi_snac_pilot "${1}"
fi





