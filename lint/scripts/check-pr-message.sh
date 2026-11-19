#!/usr/bin/env bash
# Check a pull request's title and description against CONTRIBUTING.md. The
# squash merge makes them the commit message on main.
#
# Usage: PR_TITLE=... PR_BODY=... check-pr-message.sh BASE_REF [HEAD_REF]
#
# The first area in the title must be a directory or file name, without its
# extension, on the path of a file the PR changes between BASE_REF and
# HEAD_REF. `ci` matches .github/, `nix` matches flake.nix and flake.lock, and
# `treewide` matches a PR that changes more than one top-level directory.
set -euo pipefail

base=${1:?usage: PR_TITLE=... PR_BODY=... $0 BASE_REF [HEAD_REF]}
head=${2:-HEAD}
title=${PR_TITLE:?PR_TITLE is not set}
body=${PR_BODY:-}
body=${body//$'\r'/}

max_title=64
errors=()

lower() { tr '[:upper:]' '[:lower:]'; }

touched_areas() {
    local file part
    local -a parts
    git diff --name-only "$base...$head" | while IFS= read -r file; do
        IFS=/ read -ra parts <<<"$file"
        for part in "${parts[@]}"; do
            part=${part#.}
            echo "${part%%.*}"
        done
        case $file in
        .github/*) echo ci ;;
        flake.nix | flake.lock) echo nix ;;
        esac
    done | lower | sort -u
    if (($(git diff --name-only "$base...$head" | cut -d/ -f1 | sort -u | wc -l) > 1)); then
        echo treewide
    fi
}

# section <name>: print the non-blank lines under `## <name>` up to the next `## ` heading.
section() {
    printf '%s\n' "$body" | awk -v name="$1" '
        /^## / {
            heading = $0
            sub(/^## +/, "", heading)
            sub(/[[:space:]]+$/, "", heading)
            inside = (tolower(heading) == tolower(name))
            next
        }
        inside && /[^[:space:]]/ { print }
    '
}

if ((${#title} > max_title)); then
    errors+=("The title has ${#title} characters. The limit is $max_title, so the ' (#123)' suffix that GitHub adds still fits in 72.")
fi
title_re='^([a-z0-9][a-z0-9._-]*: )+[^ ]'
if [[ ! $title =~ $title_re ]]; then
    errors+=("The title must look like 'area: summary', for example 'maestro-hw: sdwire: retry on EBUSY'.")
else
    area=${title%%: *}
    areas=$(touched_areas)
    if ! grep -qxF "$area" <<<"$areas"; then
        errors+=("The title's area '$area' is not a directory or file this PR changes. Use one of: $(tr '\n' ' ' <<<"$areas")")
    fi
fi
if [[ $title == *. ]]; then
    errors+=("The title must not end with a period.")
fi

for name in Why Docs Verification; do
    if [[ -z $(section "$name") ]]; then
        errors+=("The description needs a '## $name' section with text in it.")
    fi
done

if [[ $body == *'<!--'* ]]; then
    errors+=("The description contains an HTML comment. Delete it, because the description becomes the commit message on main.")
fi

fixes_re='^Fixes: [0-9a-f]{12,40}( \(".+"\))?$'
closes_re='^Closes: (#[0-9]+|https://github\.com/[^/ ]+/[^/ ]+/issues/[0-9]+)$'
while IFS= read -r line; do
    case $line in
    Fixes:*)
        [[ $line =~ $fixes_re ]] || errors+=("Bad trailer '$line'. Use 'Fixes: <12-character sha> (\"<subject>\")'.")
        ;;
    Closes:*)
        [[ $line =~ $closes_re ]] || errors+=("Bad trailer '$line'. Use 'Closes: #<issue>'.")
        ;;
    esac
done <<<"$body"

if grep -qiE '^co-authored-by: .*(claude|anthropic)|generated with \[?claude' <<<"$body"; then
    errors+=("The description credits an AI tool. Remove the line.")
fi

if ((${#errors[@]})); then
    printf '%s\n' "${errors[@]}"
    echo "See CONTRIBUTING.md."
    exit 1
fi
