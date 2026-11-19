# maestro

Lab controller: a small arm64 board (PoE, USB-C downstream ports) running a bootc image. `software/app` is the Rust workspace, and `software/distro` layers it on `ghcr.io/talhahavadar/dotos-rockpie`.

Enter the dev shell with `nix develop`. Run `just lint` (prek, all hooks) before you finish a change.

## Rules and what enforces them

Add a rule here only together with its enforcement. If a rule has nothing enforcing it, fix that before adding more text.

| Rule                                                 | Enforced by                                               |
| ---------------------------------------------------- | --------------------------------------------------------- |
| `maestro-core` does no I/O (fs, net, process, io)    | ast-grep `core-no-io` (`lint/ast-grep/rules/`)            |
| No `unwrap()` outside tests, no `dbg!`               | clippy workspace lints (`software/app/Cargo.toml`)        |
| No `unsafe` code                                     | `unsafe_code = "forbid"` workspace lint                   |
| Dependencies use allowed licenses and crates.io only | cargo-deny (`software/app/deny.toml`)                     |
| Formatting                                           | rustfmt hook                                              |
| Tests live in `tests/`, not in `src/` (see Testing)  | ast-grep `no-inline-tests`                                |
| Code changes in a PR come with tests (see Testing)   | `tests-accompany-changes` (CI on PRs, `just check-tests`) |

## Testing

A green PR must mean nothing catastrophic broke, so it can be merged. Tests describe what maestro does, not how it does it: drive the system from outside and assert on what a user would see.

### Tiers

| Tier       | What runs                                                                                         | Hardware                 | When                  |
| ---------- | ------------------------------------------------------------------------------------------------- | ------------------------ | --------------------- |
| Functional | Real `maestrod` driven through its public interface (HTTP API), in `software/app/crates/*/tests/` | Emulated with umockdev   | Every PR              |
| System     | The built bootc image booted in QEMU, driven over the network, in `software/distro/tests/`        | None or emulated         | Every PR              |
| HIL        | The functional scenarios against a real board and accessories                                     | Real, self-hosted runner | Scheduled and release |

### When you add or change a feature

1. Cover it with a functional test that goes through the public surface and asserts observable outcomes: API responses and the resulting device state. Do not assert on internal calls.
2. If it touches boot, systemd units, sysusers, image contents or networking, cover it in the system tier as well.
3. If it talks to hardware, write the scenario so it can also run against real hardware in HIL.
4. Treat the HTTP API as a contract. Any change to paths, request or response shape, status codes or semantics needs a functional test that pins the new behaviour. Breaking changes are deliberate and called out in the PR.
5. A bug fix comes with a regression test at the tier where the bug showed up.

`tests-accompany-changes` fails a PR that changes `software/app/crates/*/src/` without touching any crate's `tests/`, or changes `software/distro/` (except docs and `.md`) without touching `software/distro/tests/`. The tests may land in any commit of the PR. A commit that changes no behaviour (refactor, rename, doc comment) carries a trailer with the reason instead, for example `No-Tests: pure rename, covered by existing API tests`. The trailer exempts only that commit's own changes. "The test is hard to write" is not a valid reason; a real but untestable bug (a race umockdev cannot trigger) is, and the reason should say so. Run `just check-tests` before pushing.

### Hardware emulation

Emulate devices with umockdev (as `sdwire-cli` does) at the sysfs, udev, usbdevfs and tty level, so the real driver code in `maestro-hw` and `maestro-mpy` runs. Prefer recorded or stateful device behaviour over mocks that check a function was called. umockdev is Linux-only, so these tests run on Linux (CI or a Linux machine).

### Small tests: discouraged, not banned

Write a test below the public surface only when that surface cannot reasonably cover the behaviour:

- Protocol codecs and parsers (raw REPL framing, USB descriptor parsing), where the input space is too large to reach from outside. Prefer property or table-driven tests over one test per function.
- Safety invariants in `maestro-core`, such as never switching the SD card while the DUT is powered.

The `no-inline-tests` lint rejects tests in `src/`. For an allowed small test, put the suppression on the line above its `#[cfg(test)]` with the reason, for example `// ast-grep-ignore: no-inline-tests -- raw REPL framing has too many inputs for the API`. Do not write tests for constructors, getters, plumbing, or one test per function.

### Keeping green trustworthy

- A flaky test is a bug: fix it or delete it. No automatic retries.
- Never weaken or remove an assertion to make a PR pass without saying so in the PR.
- `cargo-mutants` runs on a schedule (not as a PR gate) to check that the suite catches broken code. When a mutant survives on an important path, strengthen or add a functional test, not a unit test.

Apart from `no-inline-tests`, these are review guidelines, not rules in the table above. Each gets an enforcer as its piece lands: required status checks on `main`, the QEMU boot job, the HIL runner and the scheduled `cargo-mutants` workflow.
