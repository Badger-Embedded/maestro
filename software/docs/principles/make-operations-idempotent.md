# Make operations idempotent

Design every state-changing operation to converge to the correct state however many times it runs and wherever the previous run stopped.

Derive each step from the state that exists, not from what the previous run meant to do. Read the current state, compare it to the goal, and apply only the difference.

Anything a run leaves behind (a lock, a temporary file, a half-written record) must be recognizable as stale by the next run, wherever the previous run could have stopped. Write to a temporary path and rename it into place.

The test: what happens if this runs twice? What if the previous run crashed at every possible point? If the answer depends on what was left behind, add a reconciliation step.

## In maestro

This covers API actions that a client may retry, and the systemd units, sysusers entries and first-boot steps in `software/distro` that run again after a crash, a power cut or an image update.

The mistake this prevents: an endpoint that toggles port power instead of setting it. A client that retries after a timeout turns the DUT back off.
