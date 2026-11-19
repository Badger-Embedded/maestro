# Type system discipline

Make the compiler reject impossible states, mismatched primitives, and unhandled variants.

- **Give semantic primitives their own type.** If two values share a primitive type but mean different things, wrap each in a newtype. Validate once, in the constructor.
- **External data is untyped until parsed.** HTTP bodies, sysfs attributes, tty output, config and environment variables go through a parse function at the boundary (`TryFrom`, `FromStr`, serde into a typed struct) that returns the typed model.
- **Match exhaustively.** Do not add a `_ =>` arm on a maestro enum. A new variant must then fail to compile at every place that has to handle it.
- **Derive types from authoritative schemas.** When a schema file owns a shape, derive the type from it instead of writing a parallel one.

## In maestro

A port number, a GPIO line and a USB bus address are all small integers, and power state is a yes or no.

The mistake this prevents: `fn set_power(port: u8, on: bool)`. A call that swaps a hub index for a port index, or passes `true` meaning "off", compiles. Use a `PortId` newtype and a `Power` enum instead.
