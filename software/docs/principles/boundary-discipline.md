# Boundary discipline

Validate, narrow types, and handle errors where data crosses a system boundary. Inside, trust the types: no re-validation and no redundant checks. Parse raw data into domain types at the boundary, and keep transport and framework types out of the public interface. Business logic lives in pure functions with no framework dependencies. The shell that calls them is thin.

Two tests. Is this data crossing a boundary right now? If not, the validation is redundant. Can this be a pure function the shell just calls? If yes, extract it.

## In maestro

The boundaries are the HTTP API in `maestrod` and the devices in `maestro-hw` and `maestro-mpy`: sysfs attributes, udev events, usbdevfs and tty output. Parse there into `maestro-core` types. `maestro-core` holds the logic as pure functions and trusts what it receives.

The mistake this prevents: reading a sysfs attribute as a `String`, passing it into `maestro-core`, and parsing or checking it again in several places there.
