# Prove it works

Verify every result by checking the real thing directly: run the feature, read the actual value, inspect the diff. Proxies do not count: a build that passes, a self-report, cached output, or "it compiles". When a check fails, suspect the way you observed it before you suspect the system.

Script the check when you can. A deterministic script that reruns the comparison beats a one-time look.

## In maestro

The proof is the test tier that covers the change, run and passing: a functional test through the HTTP API, a system test that boots the image in QEMU, or a HIL run on a real board. Say which tier ran. If a tier could not run here (umockdev needs Linux, HIL needs the runner), say that it did not run instead of implying it did.

The mistake this prevents: reporting a systemd unit change as done because the Containerfile builds, without booting the image.
