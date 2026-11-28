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
    cat > "${TMP_PILOT}/accepted-assets.sha256" <<'SUMS'
f7786e16354f6fe90a632f8ad822807e4f956890ca99fbc0786a86c46cb37f18  jt1943_llapi_snac_20261030_freebuttons.rbf
2fbd5ec30285cb10f0d2f406731fab379aff8d8b321c024fa5149310ab214f8c  1943-LLAPI-SNAC-Test.mra
8cce28aa8b1116a6ef0dff2de48ba84bc0381f5034288d99cce564d34e22b26e  timing-acceptance.json
SUMS
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
    cat > "${TMP_PILOT}/accepted-assets.sha256" <<'SUMS'
729ce0307dd6a9f885c666ae7efa95b70f5133fe74f4ab7252551bc77a67db24  jt1944_llapi_snac_20261030_freebuttons.rbf
bc5578a0f426508b57e7702fdc9e1c194c0cf68363f2a2d7d78172b27790387a  1944-LLAPI-Test.mra
5feb489fe2fdf20eca856f12452466bc459e8e8c6c02c7452b4c4f734d9e476c  timing-acceptance.json
SUMS
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
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/v0.9.0-1943-enhanced"
    local ASSET
    for ASSET in 1943-LLAPI-SNAC.rbf 1943-LLAPI-SNAC.mra LLAPI-VERSION.json RELEASE-NOTES.md LICENSE; do
        curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_1943_ENHANCED}/${ASSET}"
    done
    python3 - "${TMP_1943_ENHANCED}" <<'PYCODE'
from pathlib import Path
import sys,hashlib,xml.etree.ElementTree as ET
p=Path(sys.argv[1])
expected={'1943-LLAPI-SNAC.rbf':'d63834d448bbc8f03a4cf0fcad3614e7de461e7b5012dfa41bbcfd8cb2ed3a21','1943-LLAPI-SNAC.mra':'d8c6c2040c8538d8f74e102716ffe916fbf700340a0137b8da7b52eb9e688f69'}
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

install_goldenaxe_enhanced() (
    set -e
    local target="$1" tmp url
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    url="https://github.com/MiSTer-LLAPI/jtcores/releases/download/v1.0.0-goldenaxe-enhanced"
    curl -fsSL "$url/Golden.Axe.-.LLAPI.Enhanced.1.0.mra" -o "$tmp/game"
    (cd "$tmp" && sha256sum -c <<'SUMS'
79eb951f47e4d3af047906b3dcf505a04f447df5e4be75a251512e11f9faec5a  game
SUMS
    )
    printf '%s  %s\n' '77622f19e872190ba502c184a6ca7b4dae65ac2e1fdf0f9e66e9b8cb59e8bcd7' '.github/arcade/jtgoldnaxe_llapi21.rbf' | sha256sum -c - || exit 1
    copy_file '.github/arcade/jtgoldnaxe_llapi21.rbf' "$target/_LLAPI Enhanced/cores/jtgoldnaxe_llapi21.rbf"
    rm -f "$target/_LLAPI Enhanced/cores/jtgoldnaxe_llapi10.rbf"
    sed -e 's|<name>Golden Axe (set 6, US) (8751 317-123A)</name>|<name>Golden Axe</name>|' -e 's|<rbf>jtgoldnaxe_llapi10</rbf>|<rbf>jtgoldnaxe_llapi21</rbf>|' "$tmp/game" > "$tmp/Golden Axe.mra"
    copy_file "$tmp/Golden Axe.mra" "$target/_LLAPI Enhanced/_Arcade/Golden Axe.mra"
    rm -f "$target/_LLAPI Enhanced/_Arcade/Golden Axe - LLAPI Enhanced 1.0.mra"
)

install_contra_enhanced() {
    local TARGET_DIR="${1}"
    local TMP_CONTRA_ENHANCED
    TMP_CONTRA_ENHANCED="$(mktemp -d)"
    local RELEASE_URL="https://github.com/MiSTer-LLAPI/jtcores/releases/download/v0.8.0-contra-enhanced"
    local ASSET
    for ASSET in Contra-LLAPI-SNAC.rbf Contra-LLAPI-SNAC.mra LLAPI-VERSION.json RELEASE-NOTES.md LICENSE; do
        curl -fsSL "${RELEASE_URL}/${ASSET}" -o "${TMP_CONTRA_ENHANCED}/${ASSET}"
    done
    python3 - "${TMP_CONTRA_ENHANCED}" <<'PYCODE'
from pathlib import Path
import sys,hashlib,xml.etree.ElementTree as ET
p=Path(sys.argv[1])
expected={'Contra-LLAPI-SNAC.rbf':'0c260adf68641fbb2e11bafb8c236350848d24b4b47472bd7e6439d47208d130','Contra-LLAPI-SNAC.mra':'98c43101af8c3e8a4e7446d0bbd87edf27ce5b92cc223f2da3e3b41987f77864'}
for name,digest in expected.items():
    assert hashlib.sha256((p/name).read_bytes()).hexdigest()==digest,name
m=ET.parse(p/'Contra-LLAPI-SNAC.mra')
assert m.findtext('rbf')=='Contra-LLAPI-SNAC'
assert m.findtext('name')=='Contra-LLAPI-SNAC'
PYCODE
    copy_file "${TMP_CONTRA_ENHANCED}/Contra-LLAPI-SNAC.rbf" "${TARGET_DIR}/_LLAPI Enhanced/cores/Contra-LLAPI-SNAC.rbf"
    copy_file "${TMP_CONTRA_ENHANCED}/Contra-LLAPI-SNAC.mra" "${TARGET_DIR}/_LLAPI Enhanced/_Arcade/Contra-LLAPI-SNAC.mra"
    for ASSET in LLAPI-VERSION.json RELEASE-NOTES.md LICENSE; do
        copy_file "${TMP_CONTRA_ENHANCED}/${ASSET}" "${TARGET_DIR}/docs/Contra-LLAPI-SNAC/${ASSET}"
    done
    rm -rf "${TMP_CONTRA_ENHANCED}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update_distribution "${1}" ""
    install_1943_llapi_snac_pilot "${1}"
    install_amiga_experimental "${1}"
    install_psx_experimental "${1}"
    install_psx_single_diagnostic "${1}"
    install_1943_enhanced "${1}"
    install_contra_enhanced "${1}"
    install_goldenaxe_enhanced "${1}"
    # Install the separate P1 timing build from its verified CI archive.
    python3 - "${1}" <<'P1TIMING'
import hashlib, io, sys, zipfile
from pathlib import Path
root = Path(sys.argv[1])
archive = Path('.github/Contra-P1-Timing.zip').read_bytes()
if hashlib.sha256(archive).hexdigest() != 'cb6c8ce7afec9bb12f55284997b9416ed22fa9c8f36cdc072d2aa531c5da1253':
    raise SystemExit('Unexpected Contra P1 Timing archive')
with zipfile.ZipFile(io.BytesIO(archive)) as package:
    with zipfile.ZipFile(io.BytesIO(package.read('MiSTer-install.zip'))) as install:
        for name in ('_LLAPI Enhanced/cores/Contra-LLAPI-Diag.rbf', '_LLAPI Enhanced/_Arcade/Contra-LLAPI-Diag.mra'):
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(install.read(name))
    docs = root / 'docs/Contra-LLAPI-Diag'
    docs.mkdir(parents=True, exist_ok=True)
    for name in ('README.txt', 'LICENSE', 'LLAPI-LICENSE.txt', 'build.json'):
        (docs / name).write_bytes(package.read(name))
P1TIMING
    python3 - "${1}/_LLAPI Enhanced/_Arcade" <<'TITLES'
from pathlib import Path
import re
import sys

arcade = Path(sys.argv[1])
for original, title in {
    "1943-LLAPI-SNAC": "1943",
    "Contra-LLAPI-SNAC": "Contra",
    "Contra-LLAPI-Diag": "Contra (P1 Timing)",
}.items():
    source = arcade / (original + ".mra")
    data = source.read_bytes()
    pattern = rb"<name>[^<]*</name>"
    assert len(re.findall(pattern, data)) == 1, source
    (arcade / (title + ".mra")).write_bytes(re.sub(pattern, ("<name>" + title + "</name>").encode(), data))
    source.unlink()
TITLES
    # 1942 Enhanced: CI run 44629022165.
    # Verified CI builds: 1944 44560972333, Final Fight 44583668429,
    # The Punisher 44588490334, Darius (rmonic79) 44593996218.
    # Source and workflow history: https://github.com/MiSTer-LLAPI/jtcores/actions
    python3 - "${1}/_LLAPI Enhanced" <<'ENHANCED'
from pathlib import Path
import hashlib, sys, zipfile
archive = Path('.github/Enhanced-Arcade-1.0.zip')
if hashlib.sha256(archive.read_bytes()).hexdigest() != '3420d8555917600f4de105294cd823e9e909ac31d16c32cee9909370367a4e86':
    raise SystemExit('Enhanced archive checksum mismatch')
with zipfile.ZipFile(archive) as package:
    package.extractall(sys.argv[1])
ENHANCED
    python3 - "${1}/_LLAPI Enhanced" <<'JOTEGO_ENHANCED'
from pathlib import Path
import hashlib, sys, zipfile
target = Path(sys.argv[1])
packages = {
    'Enhanced-Jotego-2.0.zip': '1e1711dbdf77dc1fcb1ba6aefd867d418b59344bd9471ec3c51f623f35677f6d',
    'Enhanced-Jotego-2.1.zip': '873a808cb89765ec914d52e42116f67b4d6953a19ae666084e8e55de623a873d',
}
for name, expected in packages.items():
    archive = Path('.github') / name
    if hashlib.sha256(archive.read_bytes()).hexdigest() != expected:
        raise SystemExit(f'Checksum mismatch: {name}')
    with zipfile.ZipFile(archive) as package:
        if any((target / member).exists() for member in package.namelist()):
            raise SystemExit(f'Duplicate Jotego Enhanced file in {name}')
        package.extractall(target)
JOTEGO_ENHANCED
    printf '%s  %s\n' '8ad6df2d8341090e8db40a03d60c8bccf77d65732ccf898158117e5395ca8f6e' .github/arcade/Toki.mra | sha256sum -c - || exit 1
    copy_file .github/arcade/Toki.mra "${1}/_LLAPI Enhanced/_Arcade/Toki.mra" || exit 1
    printf '%s  %s\n' 'b25f38edd9a4bd0854f15f4e1c015f3cd05368b6aa67b9d6e0f1bf4526fffffb' .github/arcade/jttoki_llapi21.rbf | sha256sum -c - || exit 1
    copy_file .github/arcade/jttoki_llapi21.rbf "${1}/_LLAPI Enhanced/cores/jttoki_llapi21.rbf" || exit 1
    printf '%s  %s\n' '6d955e47cf2081232cae0f6891e1e9c9cfcc6cd6865cacbd744cb144c4063b75' '.github/arcade/Final Fight.mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Final Fight.mra' "${1}/_LLAPI Enhanced/_Arcade/Final Fight.mra" || exit 1
    printf '%s  %s\n' '0d1911d731b2e440065925e3b79ccc36dbf11cdfdab916dc803f0150fe4233e9' .github/arcade/jtcps1_llapi21.rbf | sha256sum -c - || exit 1
    copy_file .github/arcade/jtcps1_llapi21.rbf "${1}/_LLAPI Enhanced/cores/jtcps1_llapi21.rbf" || exit 1
    printf '%s  %s\n' 'ed1b545982a258dd9527c87271c4718f66c65222537b1bc55554e7d262b7897e' '.github/arcade/Teenage Mutant Ninja Turtles (World 4 Players, version X).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Teenage Mutant Ninja Turtles (World 4 Players, version X).mra' "${1}/_LLAPI Enhanced/_Arcade/Teenage Mutant Ninja Turtles (World 4 Players, version X).mra" || exit 1
    printf '%s  %s\n' '3814d7013f975b23917d60449c20c425b80b8e9d292917ce599a0e5055459092' .github/arcade/jttmnt_llapi21.rbf | sha256sum -c - || exit 1
    copy_file .github/arcade/jttmnt_llapi21.rbf "${1}/_LLAPI Enhanced/cores/jttmnt_llapi21.rbf" || exit 1
    # Gaiden 2.1 / LLAPI 1.2: replace the shared family core and add the
    # verified World set. The old llapi10 core still serves Ninja Gaiden (US).
    printf '%s  %s\n' '4b1d032c529a7486e807dbaa1cb95e98e0ed69ee3d8ff1e87c9f6551c3f36a3c' '.github/arcade/jtgaiden_llapi21.rbf' | sha256sum -c - || exit 1
    printf '%s  %s\n' '05d7e7484fff0571d138ee1bf8904524e64c09092281754ebe45f732a5344595' '.github/arcade/Shadow Warriors (World, set 1).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/jtgaiden_llapi21.rbf' "${1}/_LLAPI Enhanced/cores/jtgaiden_llapi21.rbf"
    copy_file '.github/arcade/Shadow Warriors (World, set 1).mra' "${1}/_LLAPI Enhanced/_Arcade/Shadow Warriors (World, set 1).mra"
    # Road Fighter / Hyper Sports 2.1 with LLAPI 1.2. The existing Hyper Sports
    # MRA is byte-identical to the CI artifact and already targets this core.
    printf '%s  %s\n' '2d810bea18211d3321e3dc95f86f35a71c27b63e1dac4d4291f6c12b02fba134' '.github/arcade/jtroadf_llapi21.rbf' | sha256sum -c - || exit 1
    copy_file '.github/arcade/jtroadf_llapi21.rbf' "${1}/_LLAPI Enhanced/cores/jtroadf_llapi21.rbf"
    # Kiwi Enhanced 2.1 / LLAPI 1.2: six new official games. Preserve TNZS 1.0.
    printf '%s  %s\n' '1934d2335a28cfa34ef3cd5bb1a667a8b4424a5e60de824fe8b90d6571e159f1' '.github/arcade/jtkiwi_llapi21.rbf' | sha256sum -c - || exit 1
    copy_file '.github/arcade/jtkiwi_llapi21.rbf' "${1}/_LLAPI Enhanced/cores/jtkiwi_llapi21.rbf" || exit 1
    printf '%s  %s\n' 'e6d45a2ec6c866bb4d1a36d15f7d227ec9ba67f6da53535e58d04f7d669389fd' '.github/arcade/Arkanoid - Revenge of DOH (World).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Arkanoid - Revenge of DOH (World).mra' "${1}/_LLAPI Enhanced/_Arcade/Arkanoid - Revenge of DOH (World).mra" || exit 1
    printf '%s  %s\n' '0589ec68ef06b415f3ab084d14a23c98dbf91ca610e6aa59f4772ebe4cf0e7e6' '.github/arcade/Chuka Taisen (World) (P0-028-A PCB).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Chuka Taisen (World) (P0-028-A PCB).mra' "${1}/_LLAPI Enhanced/_Arcade/Chuka Taisen (World) (P0-028-A PCB).mra" || exit 1
    printf '%s  %s\n' '4662fe4dd18740bb6d0f4064cbf633653c6b79c30799802a8c5bfa1621f8472e' ".github/arcade/Dr. Toppel's Adventure (World).mra" | sha256sum -c - || exit 1
    copy_file ".github/arcade/Dr. Toppel's Adventure (World).mra" "${1}/_LLAPI Enhanced/_Arcade/Dr. Toppel's Adventure (World).mra" || exit 1
    printf '%s  %s\n' '407ee5bc1f95956bd99d9ea18dbb1365e65b820cb9fcfd5bd42b8d734dfcff0e' '.github/arcade/Extermination (World).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Extermination (World).mra' "${1}/_LLAPI Enhanced/_Arcade/Extermination (World).mra" || exit 1
    printf '%s  %s\n' 'a5275a51af46f254e910ec23bb6a8cb29418bae3f5fc0222e66584cbb1869c5c' '.github/arcade/Insector X (World).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Insector X (World).mra' "${1}/_LLAPI Enhanced/_Arcade/Insector X (World).mra" || exit 1
    printf '%s  %s\n' 'd2d58f355b3338080496c66dd1459eaafa565a248ea842a5e5e56ed8e3fcebc9' '.github/arcade/Kageki (World).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Kageki (World).mra' "${1}/_LLAPI Enhanced/_Arcade/Kageki (World).mra" || exit 1
    # Rastan family 2.1 / LLAPI 1.2: three new games, preserving Rastan 1.0.
    printf '%s  %s\n' '0c7b19f282fbc0b980c333af0e06ed50eebac20a3c9b4725ba816e9cf0f38121' '.github/arcade/Golfing Greats (World, version L).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Golfing Greats (World, version L).mra' "${1}/_LLAPI Enhanced/_Arcade/Golfing Greats (World, version L).mra" || exit 1
    printf '%s  %s\n' 'e5009a9419b8fa5ac9b118fe9ccd2ea1912f76578b18741bd896d582d8224952' '.github/arcade/Lightning Fighters (World).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Lightning Fighters (World).mra' "${1}/_LLAPI Enhanced/_Arcade/Lightning Fighters (World).mra" || exit 1
    printf '%s  %s\n' '5b7167e136d290ada1c7ff6b6f7093ba4b0107751dfb05005b1eddf85ca3f6f5' '.github/arcade/Teenage Mutant Ninja Turtles Turtles in Time (4 Players ver UAA).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Teenage Mutant Ninja Turtles Turtles in Time (4 Players ver UAA).mra' "${1}/_LLAPI Enhanced/_Arcade/Teenage Mutant Ninja Turtles Turtles in Time (4 Players ver UAA).mra" || exit 1
    printf '%s  %s\n' 'a5fc958f4ce961991f2d92ca79eeb3714d38e9cd3adf2a59e3fbda20fa5cc084' .github/arcade/jtriders_llapi21.rbf | sha256sum -c - || exit 1
    copy_file .github/arcade/jtriders_llapi21.rbf "${1}/_LLAPI Enhanced/cores/jtriders_llapi21.rbf" || exit 1
    printf '%s  %s\n' '50996f4de1be9e3ca01567c1c385b65bf469cf70acd194f514fc726670a57bb5' .github/arcade/jtrastan_llapi21.rbf | sha256sum -c - || exit 1
    copy_file .github/arcade/jtrastan_llapi21.rbf "${1}/_LLAPI Enhanced/cores/jtrastan_llapi21.rbf" || exit 1
    printf '%s  %s\n' '53303e0b40e3973f36cb58b39e481edddd0af399b5feaa999c44a1c53dec7f82' '.github/arcade/Operation Wolf (World, rev 2, set 1).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Operation Wolf (World, rev 2, set 1).mra' "${1}/_LLAPI Enhanced/_Arcade/Operation Wolf (World, rev 2, set 1).mra" || exit 1
    printf '%s  %s\n' 'c5405b46fd5dea4766efef50fe29d67725fc78ff8aa785139eed1d9c7f9fdad9' '.github/arcade/Rainbow Islands (rev 1).mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Rainbow Islands (rev 1).mra' "${1}/_LLAPI Enhanced/_Arcade/Rainbow Islands (rev 1).mra" || exit 1
    printf '%s  %s\n' '838fbcf8463414b8fc4ce0797bc22438cff924f777a20d565dbea6954f2086cf' '.github/arcade/Rainbow Islands - Extra Version.mra' | sha256sum -c - || exit 1
    copy_file '.github/arcade/Rainbow Islands - Extra Version.mra' "${1}/_LLAPI Enhanced/_Arcade/Rainbow Islands - Extra Version.mra" || exit 1
    # Keep the public 1944 MRA and its RBF path when updating the LLAPI driver.
    printf '%s  %s\n' '08575ee5683bef6a90959bb9077f826060f55c83bc669ff24695f8f9710086f9' '.github/arcade/jt1944ll12t1.rbf' | sha256sum -c - || exit 1
    copy_file '.github/arcade/jt1944ll12t1.rbf' "${1}/_LLAPI Enhanced/cores/jt1944_llapi050.rbf" || exit 1
    printf '%s  %s\n' '253363c3f855ac61eb441c3ea3146c310d2d90598c21fce13fa1ac611eef1bc9' '.github/consoles/SNES_20261124.rbf' | sha256sum -c - || exit 1
    copy_file '.github/consoles/SNES_20261124.rbf' "${1}/_LLAPI Enhanced/_Console/SNES_20261124.rbf" || exit 1
    printf '%s  %s\n' 'd79c6f723cc6445743eee52ef3f2cc45d2b534166459507bcb9b8e07e0e5da85' '.github/consoles/NeoGeo_Turbo_20261127.rbf' | sha256sum -c - || exit 1
    copy_file '.github/consoles/NeoGeo_Turbo_20261127.rbf' "${1}/_LLAPI Enhanced/_Console/NeoGeo_Turbo_20261127.rbf" || exit 1
    # Rename the assembled directory before generating the Update All index.
    if [[ -e "${1}/_SNAC+LLAPI Enhanced" ]]; then
        echo "Enhanced catalog destination already exists" >&2
        exit 1
    fi
    mv -- "${1}/_LLAPI Enhanced" "${1}/_SNAC+LLAPI Enhanced" || exit 1
fi











