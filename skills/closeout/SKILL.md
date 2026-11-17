---
name: closeout
license: MIT
description: >-
  Use this skill when the user wants to know whether a project, branch, or work session is finished and safe to archive, close, or walk away from. Trigger on "is it safe to archive," "what's left before I close this out," "can I wrap this up," "closeout," "what did we just finish," "anything I'm about to lose," "ready to ship / retire / delete this workspace," or "status plus next steps" at the END of work. It produces ONE briefing: what was just completed, what is still open (split into blockers vs. nice-to-haves), an explicit archive verdict (SAFE / SAFE WITH NOTES / NOT YET), and a ranked next-steps chart where every row states its payoff. It is the end-of-work sibling of a mid-work status snapshot; use it when the question is "can I stop?", not "what should I do next hour?". Read-only: it never commits, pushes, deletes, or archives anything itself.
---

# Closeout — completed, what's left, archive verdict, next steps

Answer one question honestly: **"If I walk away or archive this right now, what do I lose or leave broken?"**
Everything else in the briefing supports that answer. This skill is **read-only**: it
reports and recommends, and the user decides. Never commit, push, delete, stop a
process, or archive as part of running it.

If the user scoped it ("closeout the api branch", "is this folder safe to delete"),
scope the checks to that target but still give the full verdict and chart.

## 1. Identify the target

Decide what "archive" means here, since the checks differ:
- **A repo or project folder** → git state, unpushed work, untracked files, deploy state.
- **A branch / PR** → merge state, CI, review comments, whether it's been merged elsewhere.
- **A chat or coding session** → what was done in it, any promised follow-ups, files only it holds.
- **A scratch or temp workspace** → whether anything in it exists nowhere else.

State the interpretation in one line. If it's genuinely ambiguous and the answer would
change the checks, ask once; otherwise pick the most likely and say so.

## 2. Gather, in one parallel batch

Run these read-only checks together; skip any that don't apply:

**Code / repo**
- `git status --short --branch` — uncommitted and untracked work, ahead/behind.
- `git log --oneline -10` and `git log @{u}..` — recent story; commits not pushed.
  If there is no upstream, `@{u}` errors: treat that as "branch never pushed" (a blocker
  if it has commits) and compare against the default branch instead.
- `git stash list` — forgotten stashes.
- `git branch -vv` / `git branch --no-merged` — local-only or unmerged branches.
- Open PRs and CI for the branch (`gh pr status`, `gh pr checks`) when `gh` is available.
- `git status --short --ignored 2>/dev/null | grep '^!!' | grep -vE 'node_modules|dist/|build/|\.cache'` —
  **ignored files that exist only locally** (`.env`, local config, data dirs, logs). Ignored
  does not mean disposable. Filter out `node_modules` and regenerable build output, which
  otherwise floods the result with warnings. Report names only, never contents.
- Test and build: run the project's own test/build command if one is obvious and cheap;
  otherwise report "not verified" rather than assuming green.

**Live state**
- Running dev servers, watchers, queues, or background jobs tied to the project.
- Deploys, scheduled tasks, or published artifacts that depend on files in this folder.

**Plan and notes**
- TODO / FIXME / HACK near recently changed code, plus any plan, backlog, handoff or
  `CLAUDE.md`/`README` with a `Status:` or unchecked `- [ ]` items.
- The session's own record: files changed, decisions made, promises to "do later".

**Secrets and hygiene (before anything is published or archived)**
- Credentials, tokens, or personal paths in tracked files or in history you're about to share.
  Report the file and kind of finding, never print the secret value.

Reconcile, don't just list: when plan and reality disagree (a plan says done, the tree
has uncommitted edits; a branch looks merged but isn't) say so; that gap is the most
valuable line in the report.

## 3. Output (match this structure)

Lead with a **one-line recap**: the target and what "archive" means for it.

### ✅ Just completed
3–6 bullets, concrete and verifiable (commits, files, features, fixes), converted to
absolute dates. Only what is actually done. Do not count work that is uncommitted, untested,
or unpushed as complete; put it under "What's left."

### 🚧 What's left
Two tables or two grouped lists:

| | Item | Why it matters / evidence |
|---|---|---|
| ⛔ Blocker | e.g. 3 unpushed commits on `feature-x` | Exist only on this machine |
| ⚠️ Should-fix | e.g. failing test in `auth` | Archive is possible but the repo is red |
| 💤 Nice-to-have | e.g. 2 TODOs in `utils` | No data-loss risk |

A **blocker** is anything that causes data loss, breaks a live dependency, or leaves
secrets exposed if the user archives now. Everything else is should-fix or nice-to-have.
Include "not verified" items explicitly (e.g. "tests not run; no test command found").

### 🗄️ Archive verdict
Exactly one of:
- **SAFE**: no blockers, nothing unverified that could hide one.
- **SAFE WITH NOTES**: no blockers, but list the should-fix items the user is accepting.
- **NOT YET**: one or more blockers; name each.

Give the verdict first, then at most two lines of justification. Never say SAFE when a
check was skipped that could have revealed a blocker; downgrade to SAFE WITH NOTES and
say which check was skipped.

### ➡️ Next steps
```
| Priority | Item | Status / action | Payoff — what this gives you |
|---|---|---|---|
| 1 | <clear the top blocker> | <exact command or file> | <what becomes true afterward> |
```
Rules:
- Blockers first, then should-fix, then nice-to-have; fold nothing silently away.
- **Status / action is concrete**: the command, the file, the thing it's blocked on.
- **Payoff is mandatory** and phrased as a result ("archive becomes safe", "work survives a
  disk wipe"), never a restatement of the task.
- Keep to the ~3–7 items that matter. If the verdict is SAFE, the chart may be a single
  row: the archive step itself, plus any optional follow-up.

End with **one recommended next action and an offer to start it**, not a menu. If the
verdict is SAFE, the recommendation is the archive step, but the user performs it.

## Style
Verdict and blockers first; scannable over complete; tables for parallel rows; no padding.
A short honest "NOT YET" beats a long reassuring "probably fine". Report outcomes
faithfully: if a check couldn't run, say so instead of implying it passed.
