#!/usr/bin/env bash
# Fail when a change range modifies product code without touching tests.
#
#   software/app/crates/*/src/   needs a change under software/app/crates/*/tests/
#   software/distro/ (not docs)  needs a change under software/distro/tests/
#
# Tests may come from any commit in the range. A commit whose message has a
# `No-Tests: <reason>` trailer exempts that commit's own changes only.
#
# Usage: tests-accompany-changes.sh [FROM_REF [TO_REF]]
# Without arguments it reads PRE_COMMIT_FROM_REF / PRE_COMMIT_TO_REF, which
# prek sets for `prek run --from-ref X --to-ref Y`. With no range it skips.
set -euo pipefail

from=${1:-${PRE_COMMIT_FROM_REF:-}}
to=${2:-${PRE_COMMIT_TO_REF:-HEAD}}

if [[ -z $from ]]; then
    echo "tests-accompany-changes: no ref range given, skipping"
    exit 0
fi

app_re='^software/app/crates/[^/]+/src/'
app_tests_re='^software/app/crates/[^/]+/tests/'
distro_re='^software/distro/'
distro_tests_re='^software/distro/tests/'
distro_skip_re='^software/distro/docs/|\.md$|(^|/)\.gitkeep$'

app_tests=0
distro_tests=0
uncovered_app=()
uncovered_distro=()

while read -r commit; do
    # --no-show-signature: with log.showSignature set, gpg output would land in
    # $reason and make every signed commit look exempt.
    reason=$(git log -1 --no-show-signature --format='%(trailers:key=No-Tests,valueonly)' "$commit")
    exempt=0
    [[ -n ${reason//[[:space:]]/} ]] && exempt=1
    short=$(git rev-parse --short "$commit")

    while read -r file; do
        [[ -z $file ]] && continue
        if [[ $file =~ $app_tests_re ]]; then
            app_tests=1
        elif [[ $file =~ $distro_tests_re ]]; then
            distro_tests=1
        elif ((exempt)); then
            continue
        elif [[ $file =~ $app_re ]]; then
            uncovered_app+=("$short $file")
        elif [[ $file =~ $distro_re && ! $file =~ $distro_skip_re ]]; then
            uncovered_distro+=("$short $file")
        fi
    done < <(git diff-tree --no-commit-id --name-only -r "$commit")
done < <(git rev-list --no-merges "$from..$to")

status=0

if ((${#uncovered_app[@]})) && ((!app_tests)); then
    status=1
    echo "App code changed without a functional test:"
    printf '  %s\n' "${uncovered_app[@]}" | sort -u
    echo "Add or update a functional test under software/app/crates/*/tests/."
    echo
fi

if ((${#uncovered_distro[@]})) && ((!distro_tests)); then
    status=1
    echo "Image contents changed without a system test:"
    printf '  %s\n' "${uncovered_distro[@]}" | sort -u
    echo "Add or update a system test under software/distro/tests/."
    echo
fi

if ((status)); then
    echo "If a commit above changes no behaviour (refactor, rename, doc comment),"
    echo "add a trailer with the reason to that commit's message instead:"
    echo "  No-Tests: <why no test is needed>"
    echo "See .claude/rules/testing.md."
fi

exit "$status"
