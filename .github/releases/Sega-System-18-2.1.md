# Sega System 18 Enhanced 2.1

The 30 official game entries include Alien Storm, Shadow Dancer, Michael Jackson’s Moonwalker and D. D. Crew. Update All installs these entries under **SNAC+LLAPI Enhanced → Arcade**. Each links to `jts18_llapi21.rbf` and retains Jotego’s ROM list and controls for that cabinet.

LLAPI 2P uses driver 1.0.0 with Immediate Repoll enabled. Where a cabinet has a third digital player, the original USB P3 path remains available. D. D. Crew’s four-player game entry retains the upstream core’s three input paths. Lightgun and trackball games keep their original input modes.

In a supported SNAC mode, hold an action button, then press and release Start three times to enable its autofire. Repeat to turn it off. Releasing the action stops the pulses. Show Credits on Pause defaults to Off.

Simulation covered the three digital player inputs, both lightguns, both trackball axes, 57/60 Hz selection, the six SNAC modes and the pause credits setting. Controller and gameplay tests on a physical MiSTer are pending.

Quartus Prime Lite 20.1.1 Build 720 accepted seed 1 with setup margin +0.444 ns and hold margin +0.196 ns. The RBF is 3,985,452 bytes. Its SHA-256 is `ce498dba9df40ed8e99fcac64fc8911e11b9bf36d9056ee11c1b7ea6b40f4dbc`. [Compilation and timing reports](https://github.com/MiSTer-LLAPI/jtcores/actions/runs/45507391207) · [Jotego source](https://github.com/jotego/jtcores/tree/8bc8172993b9b9488cb45ee8a913090fc4d9b143/cores/s18)
