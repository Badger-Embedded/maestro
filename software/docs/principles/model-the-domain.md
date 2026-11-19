# Model the domain

Encode the domain in a data structure instead of scattering it across conditionals. The right structure makes invalid states unrepresentable and deletes branches.

Reach for a state machine instead of scattered booleans or phase checks, a typed model instead of loose parameters, an enum or a registry instead of branching spread across files, and an index, queue, or map where the access pattern calls for it.

Do not force it. Keep boring code when the shape is clear, local, and unlikely to grow. Distrust an abstraction that adds indirection without removing branches or invalid states.

The sign that you skipped this: a feature that grows an if/else chain by one more branch, or a second boolean that must stay in sync with the first.

## In maestro

DUT power, the SD-card switch position and the USB port state form one state machine in `maestro-core`. The safety invariant "never switch the SD card while the DUT is powered" is a transition that state machine refuses, so the rule lives in one place.

The mistake this prevents: an `is_powered` flag and an `sd_on_host` flag that each HTTP handler checks on its own. The next handler that forgets one check can switch the card under a running DUT.
