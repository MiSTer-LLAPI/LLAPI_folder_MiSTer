# 1944 LLAPI Enhanced v0.2.0 — experimental

## What has improved

- **More controller choices:** Enhanced LLAPI and core-specific SNAC options. Available SNAC protocols depend on the core, compatible controllers and adapters, and the buttons required by the game.
- **Coherent DB15 readings:** both players are published together after a complete serial scan. This is source-domain coherence; physical cross-clock behavior still requires validation.
- **Flexible shooting controls:** optional Hold or Toggle autofire, with autofire **Off by default**.
- **More robust LLAPI input handling:** coherent packet updates and tested timeout/error recovery paths.
- **CPU Turbo ready by default:** Jotego's existing Turbo option starts **On**, with Off still available.

**Experimental:** 13 integration fixtures and Quartus build passed. Physical controller validation remains pending.

This experimental 1944 integration builds on Jotego's game core. Its main benefit is broader controller connectivity and optional shooting controls. It does not claim improved game emulation, graphics, sound or measured physical input latency.

The comparison below refers to the Jotego/JTFRAME source baseline used for this integration (`b222692d4c0c9a26a6cb3c99c6820b1ed4a5d565`), not every later upstream release.

| Area | Benefit in this Enhanced candidate |
| --- | --- |
| LLAPI controllers | Adds the Enhanced LLAPI input path, retaining the existing controller mappings and USB fallback. Packet publication is coherent, with bounded receive timeout/error handling and recovery paths tested in simulation. Physical compatibility still needs validation; the existing 1944 LLAPI port-2 issue remains deferred. |
| SNAC controller choice | Adds selectable Saturn digital, Mega Drive 3/6-button, SNES, PCE 2-button and NES readers alongside the retained original DB15 reader. Player counts depend on the protocol and adapter; see the mapping tables below. |
| Optional autofire | Adds explicit Off/On and Hold/Toggle controls. Autofire starts Off. Spare buttons are used where available; PCE/NES have no spare button, so core autofire is forced Off and its menu controls are unavailable. Start, credits, bomb and menu controls remain mapped. |
| PCE controller turbo | Reads physical turbo pulses through the PCE input path. Actual controller turbo rates and electrical compatibility remain pending hardware tests. This is separate from core autofire. |
| CPU/game Turbo | Retains Jotego's existing Turbo feature and changes the default to On, with Off still selectable. This is a default preference, not a newly invented speed feature. |
| Interface switching | LLAPI and SNAC modes are mutually exclusive, with the connector released during protocol changes. |

Jotego's original DB15 support and CPU Turbo option are not credited as new features here. USB input and the underlying game implementation are retained. Additional controller choices are useful when you own the matching controllers and adapters; they do not establish a universal latency or performance advantage.

**Measured results:** the completed FPGA A/B test compared the previous 1944 LLAPI final with an earlier Enhanced candidate, not with stock Jotego. Both passed the five reported timing categories. Enhanced used 195 more ALMs (about 1.1% more than that LLAPI baseline); no resource saving or physical latency improvement was demonstrated. The new PCE/NES readers, configurable autofire and Turbo default were added afterwards and are included in this separately validated Quartus build; hardware validation remains pending.

## Autofire

Autofire is **Off by default**, with **Hold** selected. Enable it in the menu, then hold the assigned autofire button to shoot repeatedly; release it to stop. You can also select **Toggle**.

| Mode | How it works |
| --- | --- |
| **Hold** | Hold the autofire button to shoot repeatedly. Release it to stop. |
| **Toggle** | Press the autofire button once to start shooting repeatedly. Press it again to stop. |
| **Off** | Disables automatic shooting. Normal manual fire remains available. |

### SNAC buttons in 1944

**SNAC availability varies by core.** The table below applies to this 1944 candidate only. Each mode requires a compatible controller and SNAC adapter, with enough buttons for the game and its Start/credits controls. Support in one core does not imply support in other cores; player counts also depend on the implemented protocol and adapter. Implementation and hardware validation are reported separately below.

| Controller | Autofire button | Supported routing |
| --- | --- | --- |
| SNES | **X** | P1 and P2 with a compatible dual-port adapter |
| Mega Drive, 6-button | **X** | P1; requires a valid 6-button handshake |
| Mega Drive, 3-button | **C** | P1; available because 1944 uses two game buttons |
| Saturn, digital | **A** | P1; available because 1944 uses two game buttons |
| DB15 | **D** | P1 and P2 with a compatible splitter |
| PC Engine, 2-button | Unavailable (forced Off) | P1, direct adapter |
| NES | Unavailable (forced Off) | P1 and P2 with a compatible dual-port adapter |

Each supported player has an independent autofire state. Manual fire, bomb, Start, credits and menu shortcuts remain available. These assignments are specific to 1944: other games may need these buttons for gameplay.

For **LLAPI**, the existing autofire mappings are retained: packet bit 3, plus the existing 1944 bit-2 alias. The physical button depends on the controller and adapter mapping; the SNAC table above does not describe LLAPI button assignments.

Opening the menu, resetting the core, changing the serial interface, disabling autofire or changing its mode clears the Toggle state. Release the autofire button before pressing it again to restart Toggle.

**Validation:** this revision is implemented locally. The new reader and integration fixtures and seven existing controller/autofire regression fixtures passed; see `outputs/1944-pce-nes/results.json` in the development workspace. Quartus compilation and physical controller tests are still pending. The routing tests include modeled or forced inputs; they do not establish hardware compatibility. Toggle behavior on physical unplug/reconnect is not yet validated. No RBF containing these new options has been released.

LLAPI 2P is the default. Other serial modes: SNAC SATURN 1P (digital only), SNAC DB9 1P (Mega Drive), SNAC DB15 2P (Ultimate SNAC DB15), SNAC SNES 2P (compatible dual-port adapter required). Keep DE10-Nano SW1 OFF. No Bliss-Box cable profile, analog Saturn handshake or multitaps. OSD pause is retained. PCE and NES routing is added in this candidate.

New free-button revisions require physical validation. UltimateMiSTer confirmed the previous 1944 autofire, LLAPI P1 and SNAC SNES 2P; the reported 1944 LLAPI port-2 issue is deferred. Previous 1943 controller modes and OSD pause were physically confirmed; its upstream credits page is intentionally static. Automated tests and Quartus timing checks do not establish hardware validation of this revision.

Install matching MRA and RBF together. Supply your own compatible game ROMs. No ROM data is included. Independent experimental MiSTer-LLAPI integration of Jotego's cores; original credits, licenses and source history are preserved. Please support https://patreon.com/jotego.

Mapping references: https://github.com/MiSTer-LLAPI/SNES_MiSTer/blob/master/SNES.sv and https://github.com/MiSTer-LLAPI/Genesis_MiSTer/blob/master/Genesis.sv

## Game speed

**Turbo is On by default** in this Enhanced candidate. This is Jotego’s game/CPU speed option, separate from autofire. Select Off in the menu for normal speed. Saved settings may override the default. This change still requires a new FPGA build and hardware validation.

## PC Engine and NES (experimental)

Select **SNAC PCE 1P** or **SNAC NES 2P** in Serial port. These modes are exclusive with LLAPI and the other SNAC protocols.

| Input | PC Engine | NES |
| --- | --- | --- |
| Fire | I | A |
| Bomb | II | B |
| Credits | Select | Select |
| Start | Run | Start |
| Menu | Down + Run + I | Down + Start + A, either player |

PCE uses a direct two-button adapter and one player. Its second player retains the existing USB fallback. Six-button extensions and TurboTap are not implemented. NES supports standard pads; P2 requires the matching dual-port SNAC wiring. Multitaps, light guns and other peripherals are not implemented. These two-button profiles are only suitable for games whose required controls fit the mapping.

PCE controller **physical turbo switches** are read as button pulses. The reader sends CLR approximately 60 times per second (50 MHz input, default tick settings). Simulation verifies pulse transport, not physical turbo rates or compatibility; real controllers and adapters still require testing. CPU Turbo is a separate game-speed option, On by default. Autofire remains Off by default.

There is no spare game button on these pads. Core autofire is therefore forced Off, regardless of saved settings, and both autofire menu options are unavailable. I/A always remains manual fire; physical PCE turbo pulses remain ordinary input. LLAPI keeps the autofire options available for hotplug controllers, with Off as the default.

Tests exercise all 256 button/direction combinations, distinct NES P1/P2 data, modeled neutral/disconnected lines, reconnection, PCE P2 neutrality, pin release, game routing, menu/credits/Start, Hold/Toggle and menu cancellation. Hardware validation, complete FPGA synthesis/fitting/timing and a new RBF remain pending. The earlier A/B RBF does not contain these additions.

Pin references (upstream source, not hardware validation):
- [MiSTer-devel TurboGrafx16](https://github.com/MiSTer-devel/TurboGrafx16_MiSTer/blob/827d45f45799b8ab3a536510847f2108a92e81bd/TurboGrafx16.sv): USER2 SEL, USER4 CLR; D0..D3 on USER1,0,5,3.
- [MiSTer-devel NES](https://github.com/MiSTer-devel/NES_MiSTer/blob/49a0a662e244469ca77b2155746a066df704ffae/NES.sv): USER0 latch, USER1/3 clocks, USER5/6 data.

Credits: Jotego/JTFRAME and existing SNAC reader authors; Kitrinx for the LLAPI foundation; MiSTer-devel for controller interface references; UltimateMiSTer/MiSTer-LLAPI for this experimental integration and validation work. Existing licenses and credits are retained.

## Release provenance and validation

Workflow commit ea7ed8c1fb50797c6756603c21db17533735f714; run 41326283290. Build sources are clean upstream b222692d4c0c9a26a6cb3c99c6820b1ed4a5d565 plus comparison-provenance/enhanced.patch, with the workflow limiting build-1944.sh to seed 1. The archived source manifest accounts for 422 files. This version labels the core package, not a separately tagged reusable driver.

Quartus 20.1.1 Build 720, Cyclone V 5CSEBA6U23I7. Setup +0.368ns, hold +0.243ns, recovery +0.955ns, removal +0.719ns, minimum pulse +1.041ns. 17888 ALMs and 25057 registers. All five raw timing summaries match the acceptance JSON. No measured resource saving or physical latency improvement is claimed.

Jotego and upstream contributors: game/platform. Kitrinx: original MIT LLAPI driver. UltimateMiSTer: Enhanced integration/tests. Original DB15 author notices and all individual licenses are preserved in source.

Install matching MRA and RBF. Update All destination: _LLAPI Enhanced. Existing final releases remain unchanged. Game ROMs are not included.
