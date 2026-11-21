---
name: open-pr
description: Open a pull request that follows CONTRIBUTING.md, with one change per pull request, a kernel-style title and a Why, Docs and Verification description. Use before running gh pr create, or when asked to open, prepare or submit a pull request.
model: haiku
---

# Open a pull request

Pull requests land by squash merge, so the title and description become the commit message on `main`. Read `CONTRIBUTING.md` first. This skill lists the steps, and `CONTRIBUTING.md` has the rules.

1. **Scope.** List what the branch changes with `git diff --stat origin/main...HEAD`. It must be one feature or one fix. If it also holds an unrelated fix, or a large refactor the change depends on, split it. Put each part on its own branch, open the refactor first, and tell the user the order.
2. **Tests and docs.** The branch carries the tests for its behavior change and updates the docs it makes wrong. Check `README.md` files, `software/docs/`, `CLAUDE.md` and `.claude/` for text the change contradicts.
3. **Checks.** Run `just lint` and `just check-tests`. Then run the test tier that covers the change and note which tier it was for the Verification section.
4. **Title and description.** Load the `unslop` skill. Write the title as `area: summary`, using the most specific directory the change touches. Write the description to a file in your scratchpad with `## Why`, `## Docs` and `## Verification`, plus `## Principles` when `software/CLAUDE.md` asks for it. Trailers go last, ending with `Signed-off-by:` and the name and email from `git config user.name` and `git config user.email`. "Why" explains the problem and the reason for this solution, not a list of edits. Never add `Co-authored-by` or "Generated with" lines for an AI tool, in commits or in the description. Run `just check-pr "<title>" <file>` and fix what it reports.
5. **Open.** Push with `git push -u origin HEAD`, then run `gh pr create --base main --title "<title>" --body-file <file>`. Report the pull request URL.
