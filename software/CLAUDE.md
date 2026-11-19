# maestro software

`app` is the Rust workspace (`maestro-core`, `maestro-hw`, `maestro-mpy`, `maestrod`). `distro` layers it on `ghcr.io/talhahavadar/dotos-rockpie` as a bootc image. The testing rules are in `.claude/rules/testing.md` at the repository root.

## Rules and what enforces them

Add a rule here only together with its enforcement. If a rule has nothing enforcing it, fix that before adding more text.

| Rule                                                 | Enforced by                                               |
| ---------------------------------------------------- | --------------------------------------------------------- |
| `maestro-core` does no I/O (fs, net, process, io)    | ast-grep `core-no-io` (`lint/ast-grep/rules/`)            |
| No `unwrap()` outside tests, no `dbg!`               | clippy workspace lints (`app/Cargo.toml`)                 |
| No `unsafe` code                                     | `unsafe_code = "forbid"` workspace lint                   |
| Dependencies use allowed licenses and crates.io only | cargo-deny (`app/deny.toml`)                              |
| Formatting                                           | rustfmt hook                                              |
| Tests live in `tests/`, not in `src/`                | ast-grep `no-inline-tests`                                |
| Code changes in a PR come with tests                 | `tests-accompany-changes` (CI on PRs, `just check-tests`) |

## Principles

These are judgment rules, so they are not in the table above. Each line says when the principle applies. Before you apply one, read its full file in `docs/principles/`. In the PR description, add a `## Principles` section that names each principle you applied and the decision it changed. Name only principles whose file you read.

- **Boundary discipline** (`boundary-discipline.md`). Data enters the system: an HTTP request, sysfs, udev, tty, config. Parse it there into typed values and trust them inside.
- **Type system discipline** (`type-system-discipline.md`). Designing a type or a function signature. Make invalid states and swapped arguments fail to compile.
- **Model the domain** (`model-the-domain.md`). Writing stateful logic, or adding a second flag or another branch for the same concept. Put the domain in one structure, such as a state machine.
- **Make operations idempotent** (`make-operations-idempotent.md`). Writing an API action, systemd unit or provisioning step that can be retried or interrupted. Running it twice must give the same end state.
- **Separate before serializing shared state** (`separate-before-serializing-shared-state.md`). Two actors could write the same device, file or state. Remove the sharing before adding a lock.
- **Fix root causes** (`fix-root-causes.md`). Debugging. Reproduce, then fix the first wrong decision, not the place where the symptom showed up.
- **Prove it works** (`prove-it-works.md`). Before you say a change is done. Run the test tier that covers it and say which tier ran.
- **Test behavior, not implementation** (`test-behavior-not-implementation.md`). Writing, changing or keeping a test. Assert what a user of the interface can observe.
