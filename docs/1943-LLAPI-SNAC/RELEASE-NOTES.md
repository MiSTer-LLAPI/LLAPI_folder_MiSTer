# 1943 Enhanced v0.9.0 — MiSTer test release

Controller Guide now shows P1/P2 controller names, contextual controls and BlisSTer port-reset guidance. Confirmed controller IDs use readable names, including PSX Digital and PSX DualShock; unassigned or ambiguous IDs show Unknown. Core and LLAPI versions appear below Reset. Autofire remains separately configurable and Off by default.

Both previously connected LLAPI ports are monitored. A continuous one-second loss pauses gameplay; the three-second Ready Player One/Two countdown waits for valid controller data from all affected ports and cancels if communication is lost again. A never-connected P2 does not block play. Manual pause and OSD pause remain independent. The bridge now uses the existing STATUS_VALID signal; the LLAPI driver remains v0.2.1-dev, not v0.3.0. Physical hot-swap testing is still required.

Saturn LLAPI: R inserts a coin and START starts the player belonging to that port. Existing USB/SNAC behavior is preserved. The 30-frame fade and JT logo are retained. No custom MiSTer Main is required.

Build: 41691401752; commit b49f35768d25f33cb9817402261a509f53cb4afb.
Compiler: Quartus Prime Lite 20.1.1 Build 720 (11/11/2020).
Container: jotego/jtcore20@sha256:a0397645aeac483f90718c89e5fd491c4889db6e4202bcba7f7f7770e14beb6b.

Whole-core resources: 17,476 / 41,910 ALMs (41.70%), 21,516 registers, 2,727 / 4,191 LABs, 177 RAM blocks / 969,076 bits, 48 DSP blocks. Compared with v0.7: +148 ALMs, +55 registers, +28 LABs; RAM and DSP unchanged.
Worst-case timing slack (ns): setup 0.347; hold 0.247; recovery 3.516; removal 0.949; minimum pulse width 0.694. All five pass, with zero total negative slack.

Local and remote simulation checks passed, including controller routing, real protocol simulations for both ports, reconnection/countdown, HPS menu ROM, names, video/rotation, audio and fade. This is not proof of physical hardware behavior; please test on MiSTer.

Core/JTFRAME: Jotego and credited contributors. Original LLAPI: Jamie Dickson (Kitrinx). Enhanced integration: UltimateMiSTer.com (RickDangerous). GPL, MIT and dependency notices are retained in the source archive. The reproduction workflow is included; bit-identical rebuilds are not asserted.
