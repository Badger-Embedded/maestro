# maestro

Lab controller: a small arm64 board (PoE, USB-C downstream ports) running a bootc image. `software/app` is the Rust workspace, and `software/distro` layers it on `ghcr.io/talhahavadar/dotos-rockpie`.

Enter the dev shell with `nix develop`. Run `just lint` (prek, all hooks) before you finish a change.

## Rules and what enforces them

Add a rule here only together with its enforcement. If a rule has nothing enforcing it, fix that before adding more text.

| Rule                                                 | Enforced by                                        |
| ---------------------------------------------------- | -------------------------------------------------- |
| `maestro-core` does no I/O (fs, net, process, io)    | ast-grep `core-no-io` (`lint/ast-grep/rules/`)     |
| No `unwrap()` outside tests, no `dbg!`               | clippy workspace lints (`software/app/Cargo.toml`) |
| No `unsafe` code                                     | `unsafe_code = "forbid"` workspace lint            |
| Dependencies use allowed licenses and crates.io only | cargo-deny (`software/app/deny.toml`)              |
| Formatting                                           | rustfmt hook                                       |
