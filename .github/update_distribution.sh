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


# Final 1943 controller release, promoted by maintainer on 31 October 2026.
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
    # Final launcher label only; verified ROM definitions, RBF reference and notices are retained.
    python3 - "${TMP_PILOT}/1943-LLAPI-SNAC-Test.mra" <<'PYCODE'
from pathlib import Path
import sys
p=Path(sys.argv[1]); d=p.read_bytes()
old="LLAPI + SNAC TEST".encode(); new=b'LLAPI + SNAC'
assert d.count(old)==1
p.write_bytes(d.replace(old,new,1))
PYCODE
    copy_file "${TMP_PILOT}/1943-LLAPI-SNAC-Test.mra" "${TARGET_DIR}/_LLAPI/_Arcade/1943-LLAPI.mra"
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
    local MENU_NAME="Amiga_LLAPI-2P_20261029.rbf"
    copy_file "${TMP_AMIGA}/${ASSET}" "${TARGET_DIR}/_LLAPI/_Experimental/${MENU_NAME}"
    mkdir -p "${TARGET_DIR}/docs/Amiga-LLAPI-Experimental"
    cat > "${TARGET_DIR}/docs/Amiga-LLAPI-Experimental/AVAILABLE-BUILDS.md" <<'DOC'
# Amiga LLAPI 2P — experimental
The MiSTer menu filename is Amiga_LLAPI-2P_20261029.rbf. The published release asset keeps its original experimental suffix. The SNAC variants have been withdrawn at the maintainer's request.
Uses the official MiSTer Main. Compilation and timing passed; hardware testing is pending. USER is dedicated to LLAPI, so physical floppy / MT32-pi are disabled in this RBF. Virtual ADF/HDF remain available. For USER MIDI/floppy peripherals use the official Amiga core.
Source: https://github.com/MiSTer-LLAPI/Minimig-AGA_MiSTer/tree/f48ad51a2305130e01aff89804ac248eeb43eeae
Original authors and licenses are preserved. No Kickstart or game data is included.
DOC
    rm -rf "${TMP_AMIGA}"
}

# Final 1944 controller release, promoted by maintainer on 31 October 2026.
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
    # Final launcher label only; verified ROM definitions, RBF reference and notices are retained.
    python3 - "${TMP_PILOT}/1944-LLAPI-Test.mra" <<'PYCODE'
from pathlib import Path
import sys
p=Path(sys.argv[1]); d=p.read_bytes()
old="LLAPI Test".encode(); new=b'LLAPI + SNAC'
assert d.count(old)==1
p.write_bytes(d.replace(old,new,1))
PYCODE
    copy_file "${TMP_PILOT}/1944-LLAPI-Test.mra" "${TARGET_DIR}/_LLAPI/_Arcade/1944-LLAPI.mra"
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
    local MENU_NAME="PSX_LLAPI_DS_20261031.rbf"
    copy_file "${TMP_PSX}/${ASSET}" "${TARGET_DIR}/_LLAPI/_Experimental/${MENU_NAME}"
    mkdir -p "${TARGET_DIR}/docs/PSX-LLAPI-Experimental"
    cat > "${TARGET_DIR}/docs/PSX-LLAPI-Experimental/AVAILABLE-BUILDS.md" <<'DOC'
# PSX LLAPI rumble — experimental
This build requires Dual SDRAM hardware and uses normal CPU speed. Do not use it on Single SDRAM hardware. The MiSTer menu filename is PSX_LLAPI_DS; DS means Dual SDRAM, matching the Saturn naming convention.
Rumble is OFF by default (OSD LLAPI rumble test). Combined finite jolts only; independent motor intensity is not supported. OSD disconnects LLAPI; effect expiry depends on adapter firmware. Physical testing remains pending.
Quartus compilation and five timing categories passed. Setup margin is only +0.007 ns.
Compiled source: c16632f952811a60b66c6cbf1b54a23bd14bd112 plus ONLY the attached QSF SEED 2 to 3 patch. No RTL/clocks/SDC/features changed.
Release, source, patch, license, checksums and reports: https://github.com/MiSTer-LLAPI/PSX_MiSTer/releases/tag/v2026.10.31-llapi-rumble-normal-dual-experimental
Except for the explicitly documented Single RAM Diagnostic below, other variants require compilation and all timing checks to pass. No BIOS or game data is included.
DOC
    rm -rf "${TMP_PSX}"
}

# Explicit maintainer exception: this exact Single RAM artifact is diagnostic only.
install_psx_single_diagnostic() {
    local TARGET_DIR="${1}" TMP_SINGLE
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/PSX_MiSTer/releases/download/v2026.10.31-llapi-rumble-single-diagnostic"
    local ASSET="PSX_LLAPI_SingleRAM_Diagnostic_20261031.rbf"
    TMP_SINGLE="$(mktemp -d)"
    curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_SINGLE}/${ASSET}"
    curl -fsSL "${RELEASE_URL}/TIMING.json" -o "${TMP_SINGLE}/TIMING.json"
    printf '%s\n' '1a5c267777018b33cc2134f710fc028ee2b670794c63c88b06fbe06141ee6e85  PSX_LLAPI_SingleRAM_Diagnostic_20261031.rbf' | (cd "${TMP_SINGLE}" && sha256sum -c -)
    python3 - "${TMP_SINGLE}/TIMING.json" <<'PYCODE'
import json,sys
d=json.load(open(sys.argv[1]))
assert d['accepted'] is False
assert d['worst_slack_ns']=={'setup':-0.523,'hold':-0.064,'recovery':3.783,'removal':1.081,'minimum pulse width':1.122}
PYCODE
    copy_file "${TMP_SINGLE}/${ASSET}" "${TARGET_DIR}/_LLAPI/_Experimental/${ASSET}"
    mkdir -p "${TARGET_DIR}/docs/PSX-LLAPI-Experimental"
    cp "${TMP_SINGLE}/TIMING.json" "${TARGET_DIR}/docs/PSX-LLAPI-Experimental/SingleRAM-Diagnostic-TIMING.json"
    cat >> "${TARGET_DIR}/docs/PSX-LLAPI-Experimental/AVAILABLE-BUILDS.md" <<'DOC'

## Single RAM Diagnostic — explicit timing exception
PSX_LLAPI_SingleRAM_Diagnostic_20261031.rbf uses normal CPU speed and Single SDRAM hardware. Compilation and fitting completed, but timing FAILED: setup -0.523 ns and hold -0.064 ns. TIMING.json remains accepted=false. This exact artifact is included by explicit maintainer authorization for diagnosis only; it is not stable or timing-approved. Use disposable memory cards/saves and keep backups. Hardware validation is pending. Rumble defaults OFF; finite combined jolts only, no independent motor control.
Source is c16632f952811a60b66c6cbf1b54a23bd14bd112 plus ONLY QSF SEED 2->3 and packing LOW->HIGH. Exact compiled source, patch, license, reports and checksums: https://github.com/MiSTer-LLAPI/PSX_MiSTer/releases/tag/v2026.10.31-llapi-rumble-single-diagnostic
This is existing LLAPI rumble integration, not the new Enhanced driver. Stable PSX and the accepted Dual SDRAM build are preserved. No 2x CPU artifact is included.
DOC
    rm -rf "${TMP_SINGLE}"
}

# Experimental Enhanced package; existing LLAPI finals remain separate.
install_1944_enhanced() {
    local TARGET_DIR="${1}" TMP_ENHANCED ASSET
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/v0.2.0-1944-enhanced"
    TMP_ENHANCED="$(mktemp -d)"
    for ASSET in jt1944_llapi_enhanced_v0_2_0_20261101.rbf 1944-LLAPI-Enhanced.mra TIMING.json README.md LICENSE; do
        curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_ENHANCED}/${ASSET}"
    done
    cat > "${TMP_ENHANCED}/expected.sha256" <<'HASHES'
95dae115940f2c1e223049d915499aac59d875138ffe662fc743e05a0dbb1dce  jt1944_llapi_enhanced_v0_2_0_20261101.rbf
d0fc595b70461578e4a935a09172d8b0de9e1ff3e0e4793f9fca33db6ce3302c  1944-LLAPI-Enhanced.mra
65bf21b9e2d74b848019efaa29a7ed286ef1e948fd38fdc6a767ae76965c6409  TIMING.json
ed75b021bafcedf8d9f12b165b1ed05a0327fd66d5b62012cb5842aac5117310  README.md
589ed823e9a84c56feb95ac58e7cf384626b9cbf4fda2a907bc36e103de1bad2  LICENSE
HASHES
    (cd "${TMP_ENHANCED}" && sha256sum -c expected.sha256)
    python3 - "${TMP_ENHANCED}" <<'PYCODE'
import json,math,sys,xml.etree.ElementTree as ET
from pathlib import Path
p=Path(sys.argv[1]);d=json.loads((p/'TIMING.json').read_text())
required={'setup','hold','recovery','removal','minimum pulse width'}
assert d['accepted'] and required.issubset(d['worst_slack_ns'])
assert all(math.isfinite(v) and v>=0 for v in d['worst_slack_ns'].values())
m=ET.parse(p/'1944-LLAPI-Enhanced.mra')
assert m.findtext('rbf')=='jt1944_llapi_enhanced_v0_2_0' and m.findtext('setname')=='1944'
PYCODE
    copy_file "${TMP_ENHANCED}/jt1944_llapi_enhanced_v0_2_0_20261101.rbf" "${TARGET_DIR}/_LLAPI Enhanced/cores/jt1944_llapi_enhanced_v0_2_0_20261101.rbf"
    # Rename the launcher only; retain the verified RBF and its reference.
    python3 - "${TMP_ENHANCED}/1944-LLAPI-Enhanced.mra" <<'PYCODE'
from pathlib import Path
import sys
p=Path(sys.argv[1]); data=p.read_text()
old='<name>1944: The Loop Master (Europe 000620) — LLAPI Enhanced v0.2.0</name>'
assert data.count(old)==1
p.write_text(data.replace(old,'<name>1944-LLAPI-SNAC</name>',1))
PYCODE
    rm -f "${TARGET_DIR}/_LLAPI Enhanced/_Arcade/1944-LLAPI-Enhanced.mra"
    copy_file "${TMP_ENHANCED}/1944-LLAPI-Enhanced.mra" "${TARGET_DIR}/_LLAPI Enhanced/_Arcade/1944-LLAPI-SNAC.mra"
    for ASSET in README.md TIMING.json LICENSE; do
        copy_file "${TMP_ENHANCED}/${ASSET}" "${TARGET_DIR}/docs/1944-LLAPI-Enhanced/${ASSET}"
    done
    rm -rf "${TMP_ENHANCED}"
}


install_1943_enhanced() {
    local TARGET_DIR="${1}"
    local TMP_1943_ENHANCED
    TMP_1943_ENHANCED="$(mktemp -d)"
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/v0.6.0-1943-enhanced"
    local ASSET
    for ASSET in 1943-LLAPI-SNAC.rbf 1943-LLAPI-SNAC.mra LLAPI-VERSION.json RELEASE-NOTES.md LICENSE; do
        curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_1943_ENHANCED}/${ASSET}"
    done
    python3 - "${TMP_1943_ENHANCED}" <<'PYCODE'
from pathlib import Path
import sys,hashlib,xml.etree.ElementTree as ET
p=Path(sys.argv[1])
expected={'1943-LLAPI-SNAC.rbf':'df50abf76312f34ab62ff3af5d8d5b9397c577167c455e919b7056757398a494','1943-LLAPI-SNAC.mra':'d8c6c2040c8538d8f74e102716ffe916fbf700340a0137b8da7b52eb9e688f69'}
for name,digest in expected.items():
    assert hashlib.sha256((p/name).read_bytes()).hexdigest()==digest,name
m=ET.parse(p/'1943-LLAPI-SNAC.mra')
assert m.findtext('rbf')=='1943-LLAPI-SNAC'
assert m.findtext('name')=='1943-LLAPI-SNAC'
PYCODE
    copy_file "${TMP_1943_ENHANCED}/1943-LLAPI-SNAC.rbf" "${TARGET_DIR}/_LLAPI Enhanced/cores/1943-LLAPI-SNAC.rbf"
    copy_file "${TMP_1943_ENHANCED}/1943-LLAPI-SNAC.mra" "${TARGET_DIR}/_LLAPI Enhanced/_Arcade/1943-LLAPI-SNAC.mra"
    for ASSET in LLAPI-VERSION.json RELEASE-NOTES.md LICENSE; do
        copy_file "${TMP_1943_ENHANCED}/${ASSET}" "${TARGET_DIR}/docs/1943-LLAPI-SNAC/${ASSET}"
    done
    rm -rf "${TMP_1943_ENHANCED}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}" ""
    install_1943_llapi_snac_pilot "${1}"
    install_amiga_experimental "${1}"
    install_psx_experimental "${1}"
    install_psx_single_diagnostic "${1}"
    install_1944_llapi_snac_pilot "${1}"
    install_1944_enhanced "${1}"
    install_1943_enhanced "${1}"
fi











