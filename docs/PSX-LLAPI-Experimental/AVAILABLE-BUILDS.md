# PSX LLAPI rumble — experimental
This build requires Dual SDRAM hardware and uses normal CPU speed. Do not use it on Single SDRAM hardware. The MiSTer menu filename is PSX_LLAPI_DS; DS means Dual SDRAM, matching the Saturn naming convention.
Rumble is OFF by default (OSD LLAPI rumble test). Combined finite jolts only; independent motor intensity is not supported. OSD disconnects LLAPI; effect expiry depends on adapter firmware. Physical testing remains pending.
Quartus compilation and five timing categories passed. Setup margin is only +0.007 ns.
Compiled source: c16632f952811a60b66c6cbf1b54a23bd14bd112 plus ONLY the attached QSF SEED 2 to 3 patch. No RTL/clocks/SDC/features changed.
Release, source, patch, license, checksums and reports: https://github.com/MiSTer-LLAPI/PSX_MiSTer/releases/tag/v2026.10.31-llapi-rumble-normal-dual-experimental
Except for the explicitly documented Single RAM Diagnostic below, other variants require compilation and all timing checks to pass. No BIOS or game data is included.

## Single RAM Diagnostic — explicit timing exception
PSX_LLAPI_SingleRAM_Diagnostic_20261031.rbf uses normal CPU speed and Single SDRAM hardware. Compilation and fitting completed, but timing FAILED: setup -0.523 ns and hold -0.064 ns. TIMING.json remains accepted=false. This exact artifact is included by explicit maintainer authorization for diagnosis only; it is not stable or timing-approved. Use disposable memory cards/saves and keep backups. Hardware validation is pending. Rumble defaults OFF; finite combined jolts only, no independent motor control.
Source is c16632f952811a60b66c6cbf1b54a23bd14bd112 plus ONLY QSF SEED 2->3 and packing LOW->HIGH. Exact compiled source, patch, license, reports and checksums: https://github.com/MiSTer-LLAPI/PSX_MiSTer/releases/tag/v2026.10.31-llapi-rumble-single-diagnostic
This is existing LLAPI rumble integration, not the new Enhanced driver. Stable PSX and the accepted Dual SDRAM build are preserved. No 2x CPU artifact is included.
