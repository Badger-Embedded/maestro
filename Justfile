image := "localhost/maestro:latest"

# Run every lint and check (the same command runs in CI)
lint:
    prek run --all-files

# Install the git hooks
hooks:
    prek install

test:
    cargo test --manifest-path software/app/Cargo.toml --workspace --locked

# Build the bootc image (on an arm64 host)
image:
    podman build -f software/distro/Containerfile -t {{image}} .

# Check that committed changes since BASE come with tests (CI runs this on PRs)
check-tests base="origin/main":
    prek run --hook-stage manual tests-accompany-changes --from-ref {{base}} --to-ref HEAD
