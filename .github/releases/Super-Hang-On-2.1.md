# Super Hang-On Enhanced 2.1

This package adds six entries for Super Hang-On and Limited Edition Hang-On under **SNAC+LLAPI Enhanced → Arcade**. The upright, sit-down and mini ride-on versions share `jtshanon_llapi21.rbf`. Each game entry retains Jotego’s original ROM list, cabinet settings and button assignments.

On a digital pad, steer with left and right, accelerate with **A**, brake with **B** and operate the supercharger with **X**. The control menu also supports the original analog stick, analog triggers and wheel profiles.

LLAPI 2P uses driver 1.0.0 with Immediate Repoll enabled. On SNAC, hold an action button and press and release Start three times to toggle autofire. Release the action to stop its pulses. Repeat the gesture to restore manual control. Show Credits on Pause defaults to Off.

Simulation checked all 256 steering values, the original control profiles, separate acceleration and braking, the supercharger, Start and Coin, turbo programming and removal, and the credits selector. Controller testing with physical hardware is pending.

Quartus Prime Lite 20.1.1 Build 720 accepted seed 1 with setup margin +0.660 ns and hold margin +0.247 ns. The RBF is 3,317,036 bytes. Its SHA-256 is `310d28030893650a823e85fab1bcbbddf2610cfd76fd6e78e2e8e2fac3eaab55`. [Compilation and timing reports](https://github.com/MiSTer-LLAPI/jtcores/actions/runs/45499404133) · [Jotego source](https://github.com/jotego/jtcores/tree/8bc8172993b9b9488cb45ee8a913090fc4d9b143/cores/shanon)
