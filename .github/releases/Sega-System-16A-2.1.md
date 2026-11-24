# Sega System 16A Enhanced 2.1

This package adds 34 official entries for Sega System 16A, including Shinobi, Fantasy Zone, Alex Kidd, Quartet and Action Fighter. Update All installs them under **SNAC+LLAPI Enhanced → Arcade**. Each links to `jts16_llapi21.rbf` and retains the ROM list, DIP switches and buttons for that specific game.

The Japanese four-player Passing Shot entry supplies board identifier 0x02. The cabinet decoder now accepts that identifier along with its previous value. Simulated CPU register reads verified all four independent controllers. Quartet’s extra player inputs, Action Fighter analog controls, the SDI trackball and the Time Scanner DIP settings also passed their cabinet tests.

LLAPI 2P uses driver 1.0.0 with Immediate Repoll enabled. To toggle autofire on SNAC, hold an action button and press and release Start three times. Releasing the action stops the pulses. Repeat the gesture to restore manual input. Show Credits on Pause defaults to Off. Testing on a physical MiSTer is pending.

Quartus Prime Lite 20.1.1 Build 720 accepted seed 1 with setup margin +0.491 ns and hold margin +0.245 ns. The RBF is 3,252,488 bytes. Its SHA-256 is `cb867664f2d9768b527ee02d44b3683de7af1e85370f51a69022adf119c58580`. [Compilation and timing reports](https://github.com/MiSTer-LLAPI/jtcores/actions/runs/45503542660) · [Jotego source](https://github.com/jotego/jtcores/tree/8bc8172993b9b9488cb45ee8a913090fc4d9b143/cores/s16)
