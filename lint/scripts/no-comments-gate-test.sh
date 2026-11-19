#!/usr/bin/env bash
# Self-test for no-comments-gate.sh: builds throwaway repos for each scenario
# and checks whether the gate passes or blocks.
set -euo pipefail

# Keep the user's git config (signing, hooks, templates) out of the throwaway repos.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
unset NO_COMMENTS_BASE

script=$(cd "$(dirname "$0")" && pwd)/no-comments-gate.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0

lib=software/app/crates/maestro-hw/src/lib.rs

# new_repo <name>: repo with a main commit that already has a comment in $lib,
# checked out on a feature branch.
new_repo() {
    repo=$work/$1
    git init -q -b main "$repo"
    git -C "$repo" config user.name test
    git -C "$repo" config user.email test@example.invalid
    mkdir -p "$repo/$(dirname "$lib")"
    printf 'fn a() {}\n// on main already\nfn b() {}\n' >"$repo/$lib"
    git -C "$repo" add .
    git -C "$repo" commit -q -m base
    git -C "$repo" checkout -q -b feature
}

# append <file> <line>: add a line to a file without staging it.
append() {
    mkdir -p "$repo/$(dirname "$1")"
    printf '%s\n' "$2" >>"$repo/$1"
}

commit_all() {
    git -C "$repo" add -A
    git -C "$repo" commit -q -m change
}

# expect <pass|block> <description> [dir]: run the gate from $repo/<dir>.
expect() {
    local want=$1 desc=$2 dir=${3:-} rc got
    rc=0
    (cd "$repo/$dir" && "$script" >/dev/null 2>&1) || rc=$?
    case $rc in
    0) got=pass ;;
    2) got=block ;;
    *) got="exit $rc" ;;
    esac
    if [[ $got == "$want" ]]; then
        echo "ok    $desc"
    else
        echo "FAIL  $desc (expected $want, got $got)"
        failures=$((failures + 1))
    fi
}

new_repo code-only
append "$lib" 'fn c() {}'
commit_all
expect pass "code without comments, and a comment already on main"

new_repo committed
append "$lib" '// why c exists'
commit_all
expect block "comment in a branch commit"

new_repo staged
append "$lib" '    // staged'
git -C "$repo" add -A
expect block "staged comment"

new_repo unstaged
append "$lib" '// unstaged'
expect block "unstaged comment"

new_repo untracked
append software/app/crates/maestro-hw/src/new.rs '// in a new file'
expect block "comment in an untracked file"

new_repo doc
append "$lib" '/// Returns the port.'
expect block "doc comment"

new_repo block-comment
append "$lib" '/* block */'
expect block "block comment"

new_repo subdir
append "$lib" '// from a subdirectory'
expect block "gate runs from a subdirectory" software/app

new_repo string
append "$lib" 'const URL: &str = "http://example.invalid";'
expect pass "// inside a string"

new_repo outside
append tools/gen.rs '// not under software/'
expect pass "comment outside software/"

new_repo removed
printf 'fn a() {}\nfn b() {}\n' >"$repo/$lib"
expect pass "removing a comment"

new_repo recorded
append "$lib" '// reviewed'
(cd "$repo" && "$script" --record)
expect pass "recorded review"
printf 'fn z() {}\n' | cat - "$repo/$lib" >"$repo/tmp" && mv "$repo/tmp" "$repo/$lib"
expect pass "code added above a reviewed comment"
append "$lib" '// new after review'
expect block "comment added after the review"

new_repo list
append "$lib" '// listed'
got=$(cd "$repo" && "$script" --list)
want="$lib:4: // listed"
if [[ $got == "$want" ]]; then
    echo "ok    --list prints path:line: text"
else
    echo "FAIL  --list prints path:line: text (got '$got')"
    failures=$((failures + 1))
fi

((failures == 0)) || { echo "$failures scenario(s) failed"; exit 1; }
