# Namco System 1 Enhanced 2.1

This package adds 19 main game entries and 20 alternate entries, including Splatterhouse, Pac-Mania, Galaga ’88 and Dragon Spirit. Update All installs the games under **SNAC+LLAPI Enhanced → Arcade**. Each links to `jtshouse_llapi21.rbf` and retains its official ROM list and cabinet settings.

LLAPI 2P uses driver 1.0.0 with Immediate Repoll enabled. On a supported SNAC pad, hold an action and press and release Start three times to toggle autofire for that button. Releasing the action stops the pulses. Repeat the gesture to restore manual operation. Show Credits on Pause defaults to Off.

Simulation checked the original cabinet modes, including pressure inputs and P1/P2 spinner reads, and the LLAPI and SNAC controller paths. Physical controller and gameplay testing is pending.

Quartus Prime Lite 20.1.1 Build 720 accepted seed 1 with setup margin +0.558 ns and hold margin +0.244 ns. The RBF is 3,754,008 bytes. Its SHA-256 is `840a41705a20b4c522aa0cc9de59a65407e02ad64a63f57a12e4a295cd64f2e8`. [Compilation and timing reports](https://github.com/MiSTer-LLAPI/jtcores/actions/runs/45511465788) · [Jotego source](https://github.com/jotego/jtcores/tree/8bc8172993b9b9488cb45ee8a913090fc4d9b143/cores/shouse)
