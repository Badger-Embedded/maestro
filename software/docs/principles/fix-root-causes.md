# Fix root causes

Fix the fault, not the place where it surfaced. The root cause is the first place the system did something it should not do, or failed to handle a state it should handle.

- Reproduce first. Ask "why" until the answer is a wrong decision in the code. When stuck, instrument and read the actual state.
- Ask whether the state that triggered the symptom is legitimate. If it is, handle it where the code broke. If it should never exist, a check there hides the bug, so find what produced it. Guards, retries, sleeps, swallowed errors and clamped values are the usual ways to hide a bug.
- Fix the pattern, not the instance. Find every place with the same fault.
- If finding the deciding fact took a deep dig, propose the cheap, always-on signal (a log line, a metric, a state endpoint) that would have shown it at first look.

## In maestro

Reproduce at the tier where the bug showed up, and keep that reproduction as the regression test (see `.claude/rules/testing.md`).

The mistake this prevents: wrapping a device read that fails now and then in a retry loop, when the real fault is that `maestro-hw` handles a udev unplug event before it finishes the previous command.
