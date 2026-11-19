#!/usr/bin/env bash
# Self-test for tests-accompany-changes.sh: builds throwaway repos for each
# scenario and checks the exit status.
set -euo pipefail

# Keep the user's git config (signing, hooks, templates) out of the throwaway repos.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

script=$(cd "$(dirname "$0")" && pwd)/tests-accompany-changes.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0

# new_repo: fresh repo in $work/<name> with one base commit tagged `base`.
new_repo() {
    repo=$work/$1
    git init -q "$repo"
    git -C "$repo" config user.name test
    git -C "$repo" config user.email test@example.invalid
    git -C "$repo" commit -q --allow-empty -m base
    git -C "$repo" tag base
}

# change <message> <file>...: commit edits to the given files.
change() {
    local msg=$1
    shift
    for f in "$@"; do
        mkdir -p "$repo/$(dirname "$f")"
        echo "$RANDOM" >>"$repo/$f"
        git -C "$repo" add "$f"
    done
    git -C "$repo" commit -q -m "$msg"
}

# expect <pass|fail> <description>
expect() {
    local want=$1 desc=$2 got
    if (cd "$repo" && "$script" base HEAD >/dev/null); then got=pass; else got=fail; fi
    if [[ $got == "$want" ]]; then
        echo "ok    $desc"
    else
        echo "FAIL  $desc (expected $want, got $got)"
        failures=$((failures + 1))
    fi
}

app=software/app/crates/maestro-hw/src/lib.rs
app_test=software/app/crates/maestrod/tests/api.rs
distro=software/distro/Containerfile
distro_test=software/distro/tests/boot.sh

new_repo no-range
if (cd "$repo" && "$script" >/dev/null); then
    echo "ok    skips without a ref range"
else
    echo "FAIL  skips without a ref range"
    failures=$((failures + 1))
fi

new_repo app-no-test
change feature "$app"
expect fail "app change without tests"

new_repo app-same-commit
change feature "$app" "$app_test"
expect pass "app change with tests in the same commit"

new_repo app-later-commit
change feature "$app"
change tests "$app_test"
expect pass "app change with tests in a later commit"

new_repo exempt
change $'refactor\n\nNo-Tests: pure rename' "$app"
expect pass "app change in a No-Tests commit"

new_repo exempt-does-not-leak
change $'refactor\n\nNo-Tests: pure rename' "$app"
change feature software/app/crates/maestrod/src/main.rs
expect fail "No-Tests on one commit does not cover another"

new_repo exempt-same-file
change $'refactor\n\nNo-Tests: pure rename' "$app"
change feature "$app"
expect fail "later change to the same file is not exempt"

new_repo empty-trailer
change $'refactor\n\nNo-Tests:' "$app"
expect fail "empty No-Tests trailer does not exempt"

new_repo distro-no-test
change image "$distro"
expect fail "distro change without system tests"

new_repo distro-with-test
change image "$distro" "$distro_test"
expect pass "distro change with system tests"

new_repo distro-app-test-only
change image "$distro" "$app_test"
expect fail "functional tests do not cover distro changes"

new_repo distro-docs
change docs software/distro/README.md software/distro/docs/notes.txt software/distro/rootfs/.gitkeep
expect pass "distro docs and .gitkeep need no tests"

new_repo unrelated
change misc README.md software/app/Cargo.toml lint/ast-grep/rules/x.yml
expect pass "changes outside src and distro need no tests"

((failures == 0)) || { echo "$failures scenario(s) failed"; exit 1; }
