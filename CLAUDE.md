# maestro

Lab controller, a small arm64 board (PoE, USB-C downstream ports) running a bootc image. `software/` holds the Rust workspace and the image, and `hardware/` holds the board design.

Enter the dev shell with `nix develop`. Run `just lint` (prek, all hooks) before you finish a change.

Every rule for agents comes with what enforces it. The software rules, their enforcers and the engineering principles are in `software/CLAUDE.md`, which loads when you work under `software/`.

Before you write a commit message, PR description, doc or code comment, load the `unslop` skill and follow it.
