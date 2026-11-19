# Test behavior, not implementation

A test is a claim about what users of the code can observe through its interface: return values, errors, state they can read back, and effects on outside systems. Private helpers, internal call order and intermediate data are implementation.

Judge each test against two imagined edits:

- **Break the behavior**: a wrong value, a skipped or doubled effect. If the test still passes, it proves nothing. The usual causes are a loose assertion, an expected value computed by the code under test, and an assertion on data the test built itself.
- **Change the internals** and keep every observable result. If the test fails, it is pinned to the implementation.

Keep a test that catches the first edit and survives the second. Rewrite or delete the rest. Drive the code through its public interface with a concrete input, and derive the expected value from the requirement. Pair "this never happens" with a case where it does happen. Assert the error that callers branch on (the HTTP status and error kind), not the message text.

## In maestro

The tiers and where tests live are in `.claude/rules/testing.md`. This principle is the check for each single test.

The mistake this prevents: a test that asserts `maestro-hw` wrote to a particular sysfs path. Read the port state back through the API, or from the umockdev device, instead.
