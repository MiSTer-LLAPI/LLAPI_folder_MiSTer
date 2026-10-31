# PSX LLAPI rumble — experimental
This build requires Dual SDRAM hardware and uses normal CPU speed. Do not use it on Single SDRAM hardware. The MiSTer menu filename is PSX_LLAPI_DS; DS means Dual SDRAM, matching the Saturn naming convention.
Rumble is OFF by default (OSD LLAPI rumble test). Combined finite jolts only; independent motor intensity is not supported. OSD disconnects LLAPI; effect expiry depends on adapter firmware. Physical testing remains pending.
Quartus compilation and five timing categories passed. Setup margin is only +0.007 ns.
Compiled source: c16632f952811a60b66c6cbf1b54a23bd14bd112 plus ONLY the attached QSF SEED 2 to 3 patch. No RTL/clocks/SDC/features changed.
Release, source, patch, license, checksums and reports: https://github.com/MiSTer-LLAPI/PSX_MiSTer/releases/tag/v2026.10.31-llapi-rumble-normal-dual-experimental
Other normal/2xCPU and Single/Dual variants will be included only after compilation and all timing checks pass. No BIOS or game data is included.
