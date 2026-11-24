# Out Run and Turbo Out Run Enhanced 2.1

Out Run and Turbo Out Run share `jtoutrun_llapi21.rbf`. The package contains the 10 official Out Run entries and six Turbo Out Run entries, including upright, sit-down, Japanese and cockpit variants. Update All installs the games under **SNAC+LLAPI Enhanced → Arcade**. Each game entry retains Jotego’s ROM list, cabinet settings and button labels.

On a digital controller the default actions are **A** to accelerate, **B** to brake and **X** to change gear. In Turbo Out Run, **Y** activates Nitro. The control menu retains the original analog stick, triggers and steering wheel modes. The game’s gear option supports both a held input and a toggle.

LLAPI 2P uses driver 1.0.0 with Immediate Repoll on. In a supported SNAC mode, hold an action button, then press and release Start three times to toggle autofire for that button. Release the action to stop the pulses. Repeat the same gesture to return it to manual operation. The pause credits option defaults to Off.

Simulation checked steering, both pedals, the three analog configurations, both gear modes, Nitro, separate Start and Coin inputs, the SNAC gesture, and pause credits. Gameplay and controller response on physical MiSTer hardware remain to be confirmed.

Quartus Prime Lite 20.1.1 Build 720 accepted seed 1 with setup margin +0.411 ns and hold margin +0.181 ns. The RBF is 3,487,416 bytes. Its SHA-256 is `9e7008433208efb27e494c44896139e31dab815e011ce601785f5ecfe8fed955`. [Compilation and timing reports](https://github.com/MiSTer-LLAPI/jtcores/actions/runs/45494464894) · [Jotego source](https://github.com/jotego/jtcores/tree/8bc8172993b9b9488cb45ee8a913090fc4d9b143/cores/outrun)
