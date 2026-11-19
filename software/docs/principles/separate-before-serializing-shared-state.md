# Separate before serializing shared state

When concurrent actors might write the same file, key, device or object, first ask whether they need one shared object or are publishing independent facts. Default to giving each actor its own file, key or state, and merge only where the state is read. Two workers writing their own field into one shared struct is still shared mutation.

Only when one shared write target is a real invariant, serialize access structurally: a single writer, sequential phases, or compare-and-swap. Instructions and comments are not concurrency control, and "we need a lock" is a smell to check first.

## In maestro

`maestrod` handles requests concurrently, and two clients can act on the same DUT at once. A physical device has one real state, so it is a legitimate shared target: give each device one owner that applies commands in order. Different devices share nothing, so they must not wait on each other.

The mistake this prevents: one global `Mutex` around the state of every port. A slow serial read on one DUT then blocks power control on all the others.
