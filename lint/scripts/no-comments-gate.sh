#!/usr/bin/env bash
# Commit gate for comment lines added to Rust code under software/.
#
# Claude Code runs this before `git commit` (see .claude/settings.json). Exit
# status 2 blocks the commit while the branch adds comment lines that the
# /no-comments skill has not reviewed. Commits made outside Claude Code are not
# affected.
#
# Usage:
#   no-comments-gate.sh            exit 2 with a message if the review is missing
#   no-comments-gate.sh --list     print the added comment lines as path:line: text
#   no-comments-gate.sh --record   mark the current comment lines as reviewed
#
# "Added" is relative to the merge base with $NO_COMMENTS_BASE, or origin/main,
# or main. It covers commits, staged and unstaged changes, and untracked files.
# The review is keyed on each comment's file and text, not its line number.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

pathspec=':(glob)software/**/*.rs'
comment_re='^[[:space:]]*(//|/[*])'

base() {
    local ref
    for ref in ${NO_COMMENTS_BASE:-} origin/main main; do
        if git rev-parse -q --verify "$ref^{commit}" >/dev/null; then
            git merge-base "$ref" HEAD && return
        fi
    done
    git hash-object -t tree /dev/null
}

added_comments() {
    git -c core.quotePath=false diff --no-color --no-ext-diff --no-renames \
        --unified=0 --src-prefix=a/ --dst-prefix=b/ "$(base)" -- "$pathspec" |
        awk -v re="$comment_re" '
            /^diff --git / { header = 1; next }
            header && /^\+\+\+ / { file = substr($0, 7); next }
            /^@@/ { header = 0; split($3, start, ","); line = substr(start[1], 2) + 0; next }
            !header && /^\+/ {
                text = substr($0, 2)
                if (text ~ re) print file ":" line ": " text
                line++
            }
        '
    git -c core.quotePath=false ls-files --others --exclude-standard -- "$pathspec" |
        while IFS= read -r file; do
            awk -v re="$comment_re" -v file="$file" '$0 ~ re { print file ":" FNR ": " $0 }' "$file"
        done
}

list=$(added_comments)
marker=$(git rev-parse --git-path no-comments-reviewed)

fingerprint() {
    printf '%s\n' "$list" | sed -E 's/^([^:]*):[0-9]+: /\1: /' | LC_ALL=C sort | git hash-object --stdin
}

case ${1:-check} in
--list)
    if [[ -n $list ]]; then printf '%s\n' "$list"; fi
    ;;
--record)
    fingerprint >"$marker"
    ;;
check)
    if [[ -z $list ]]; then exit 0; fi
    if [[ -f $marker && $(<"$marker") == "$(fingerprint)" ]]; then exit 0; fi
    count=$(printf '%s\n' "$list" | wc -l | tr -d ' ')
    {
        echo "Commit blocked: this branch adds $count comment line(s) under software/ that have not been reviewed."
        echo "Run the /no-comments skill. It reviews them, applies the findings and records the review. Then commit again."
    } >&2
    exit 2
    ;;
*)
    echo "usage: $0 [--list | --record]" >&2
    exit 64
    ;;
esac
