#!/usr/bin/env bash
# Self-test for check-pr-message.sh: runs titles and descriptions against
# throwaway repos and checks whether each passes or fails.
set -euo pipefail

# Keep the user's git config (signing, hooks, templates) out of the throwaway repos.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

script=$(cd "$(dirname "$0")" && pwd)/check-pr-message.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0

# new_repo <name> <file>...: repo with a base commit tagged `base`, then one
# commit that changes the given files.
new_repo() {
    repo=$work/$1
    shift
    git init -q "$repo"
    git -C "$repo" config user.name test
    git -C "$repo" config user.email test@example.invalid
    git -C "$repo" commit -q --allow-empty -m base
    git -C "$repo" tag base
    for f in "$@"; do
        mkdir -p "$repo/$(dirname "$f")"
        echo "$RANDOM" >>"$repo/$f"
    done
    git -C "$repo" add -A
    git -C "$repo" commit -q -m change
}

body=$'## Why\n\nThe SD mux returns EBUSY while the card is mounted.\n\n## Docs\n\nNone: no documented behavior changes.\n\n## Verification\n\nFunctional tier: `just test` passed.\n'

# expect <pass|fail> <description> <title> [body]
expect() {
    local want=$1 desc=$2 title=$3 got
    local text=${4-$body}
    if (cd "$repo" && PR_TITLE=$title PR_BODY=$text "$script" base HEAD >/dev/null); then got=pass; else got=fail; fi
    if [[ $got == "$want" ]]; then
        echo "ok    $desc"
    else
        echo "FAIL  $desc (expected $want, got $got)"
        failures=$((failures + 1))
    fi
}

hw=software/app/crates/maestro-hw/src/sdwire.rs

new_repo crate "$hw"
expect pass "crate area with subarea" "maestro-hw: sdwire: retry on EBUSY"
expect pass "file stem as area" "sdwire: retry on EBUSY"
expect pass "top-level directory as area" "software: retry on EBUSY"
expect fail "area the PR does not touch" "maestrod: retry on EBUSY"
expect fail "treewide with one top-level directory" "treewide: retry on EBUSY"
expect fail "no area" "retry on EBUSY"
expect fail "uppercase area" "Maestro-hw: retry on EBUSY"
expect fail "trailing period" "maestro-hw: retry on EBUSY."
expect fail "title over 64 characters" "maestro-hw: $(printf 'x%.0s' {1..60})"
expect fail "missing Why" "maestro-hw: retry" "${body/\#\# Why/## Reason}"
expect fail "empty Docs" "maestro-hw: retry" $'## Why\n\nx\n\n## Docs\n\n## Verification\n\ny\n'
expect fail "missing Verification" "maestro-hw: retry" $'## Why\n\nx\n\n## Docs\n\ny\n'
expect pass "CRLF line endings" "maestro-hw: retry" "${body//$'\n'/$'\r\n'}"
expect fail "HTML comment left in" "maestro-hw: retry" "$body"$'\n<!-- fill me -->\n'
expect pass "Fixes and Closes trailers" "maestro-hw: retry" "$body"$'\nFixes: 1234567890ab ("maestro-hw: add sdwire")\nCloses: #12\n'
expect fail "Fixes with a short sha" "maestro-hw: retry" "$body"$'\nFixes: 12345\n'
expect fail "Closes without an issue number" "maestro-hw: retry" "$body"$'\nCloses: the bug\n'
expect fail "AI co-author" "maestro-hw: retry" "$body"$'\nCo-authored-by: Claude <noreply@anthropic.com>\n'

new_repo aliases .github/workflows/ci.yml flake.lock .claude/settings.json Justfile
expect pass "ci matches .github/" "ci: cache cargo"
expect pass "nix matches flake.lock" "nix: bump nixpkgs"
expect pass "dot directory without the dot" "claude: allow cargo"
expect pass "file name lowercased" "justfile: add recipe"
expect pass "treewide across top-level directories" "treewide: rename"

((failures == 0)) || { echo "$failures scenario(s) failed"; exit 1; }
