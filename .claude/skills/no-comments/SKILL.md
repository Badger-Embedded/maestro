---
name: no-comments
description: Review the comment lines this branch adds under software/ with the comment-reviewer subagent, apply its findings, and record the review for the commit gate. Use when the no-comments gate blocks a git commit, or before opening a PR.
---

# No comments

`lint/scripts/no-comments-gate.sh` blocks `git commit` in Claude Code while the branch adds comment lines under `software/` that have not been reviewed. This skill runs that review. The `comment-reviewer` subagent judges the comments because it did not write them. Run `no-comments-gate.sh --record` only as the last step of this skill.

1. Run `lint/scripts/no-comments-gate.sh --list`. If it prints nothing, stop. There is nothing to review.
2. Spawn the `comment-reviewer` subagent and pass it the list and nothing else. Leave out why the comments were written, so the reviewer judges the code and not the author's reasons.
3. Check the report. Each line must name a listed comment and start with KEEP, DELETE, RESHAPE or ENCODE. Each KEEP must name a keep-list item. Change a KEEP for an external constraint to DELETE if the code next to it does not use the external thing it names. If the report breaks these rules, spawn the reviewer once more and name the problem. If the second report breaks them too, stop and tell the user.
4. Delete each comment the report marks DELETE.
5. Do each RESHAPE that fits in this change. If one needs a design change, add it to the open work in your report. The comment stays deleted either way.
6. For each ENCODE, ask the user whether to add the lint, type or test. An ast-grep rule goes in `lint/ast-grep/rules/` with a test in `lint/ast-grep/rule-tests/`. In a run with nobody to ask, add it to the open work instead.
7. Run `cargo clippy --manifest-path software/app/Cargo.toml --workspace --all-targets --locked -- -D warnings`.
8. Run `--list` again. If your fixes added comment lines, repeat steps 2 to 7 for them once. Then run `lint/scripts/no-comments-gate.sh --record`.
9. Report the number of comments deleted and kept, the reshapes and encodings you made, and the open work.
