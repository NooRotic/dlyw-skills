---
name: startup
license: MIT
description: >-
  Use this skill the moment someone wants to get their bearings on a project they're returning to. Fire it whenever they ask to be caught up, reoriented, or reminded what they were doing — "catch me up," "orient me," "what was I working on," "where did we leave off," "morning, what's the status and what do I pick back up," "I'm back after a few days off," or any return-from-a-break / start-of-session check-in. Treat even a faint "been a while, remind me" as a trigger. It builds one briefing — recent commits and current branch, uncommitted work, every unmerged branch, open handoff/plan docs and TODOs, plus (only if a persistent-memory recall plugin such as Hindsight is installed) whether that recall is actually live this session. Skip it for launching software (dev server, a CLI that won't start), reviewing specific commits, or checking if a daemon is running — those are tasks, not reorientation.
---

# Startup briefing

Reconstruct, in one pass, the state a returning developer needs: what was last
done, what it was building toward, what's left open, and (optionally) whether
cross-session memory recall is feeding anything in. The point is to replace the
"wait, what was I doing?" archaeology with a single legible briefing.

Gather the sources below **in parallel** (one batch of tool calls), then
synthesize. Don't narrate each step — collect, then present the briefing.

## 1. Optional: persistent-memory recall check (+ staleness)

**Skip this whole section, and the matching output heading, if the user has no
memory-recall plugin.** It exists for setups that use the `hindsight-memory`
plugin, whose recall hook fires on every prompt, recalls from a memory bank, and
injects a `<hindsight_memories>` block as silent `additionalContext`. That is easy
to miss because it's fused into the prompt. Run:

```bash
python3 "$HOME/.claude/skills/startup/scripts/hindsight_context.py"
```

(On Windows use the full path: `python3 "C:/Users/<you>/.claude/skills/startup/scripts/hindsight_context.py"`. If `python3` isn't found, try `python`.)

If the script reports that it found no recall file at all, the user probably
doesn't use the plugin: say nothing about memory and move on.

Otherwise it reports the bank, memory count, and a **freshness verdict**. This is
the load-bearing part: the hook rewrites its state file on *every* prompt, so a
**stale** result (saved many minutes/hours ago) means the hook didn't fire this
turn — almost always because the memory server isn't running. When it's stale,
tell the user plainly: the memory context they may be relying on is NOT live right
now, and they likely need to start the memory daemon. When it's fresh, surface the
1–2 recalled memories most relevant to the current project so the injected
context becomes visible rather than buried.

## 2. Git state — what was last done

Use the normal tools (not a script) so output stays current:
- Current branch and working-tree status (staged/untracked/dirty).
- The last ~8 commits, oneline.
- **Every branch, with its date and tip subject** — see below. Do not skip
  this.

```bash
git branch -a --format="%(refname:short) | %(committerdate:short) | %(contents:subject)"
```

Read the commit subjects as a story: what was the recent arc of work, and does
the branch name reveal the in-flight feature? Uncommitted changes are a strong
"this is where I stopped mid-thought" signal — call them out specifically.

### Why the branch sweep is not optional

**Work on an unmerged branch is simultaneously the most relevant thing in the
repo and the most invisible.** It is not in `git log` for the current branch,
not in `git status`, and **not on disk** — so every other check in this skill
misses it completely. Checking out a different branch makes the previous
branch's files vanish from the working tree, which is exactly the trap: a spec
or plan written last session can be wholly absent from a filesystem scan.

Observed failure: a 338-line approved design spec had been committed to a
feature branch nine hours earlier. The briefing listed `docs/specs/` from
`main`, saw four older specs, and reported the feature as "approved but no spec
written." The session then nearly rewrote it from scratch — and did reset the
branch past the real commit before recovering it by SHA. One `git branch -a`
line would have caught it.

So, for any branch that is **not merged into the main branch**:

- Name it in the briefing with its date and tip subject.
- If its tip touches docs/specs/plans, **read that file before concluding
  anything is unwritten or unstarted.** Use `git show <branch>:<path>` to read
  it without checking the branch out.
- Flag branches whose tip is newer than the last commit on the current branch
  — that is very likely where the user actually stopped.

```bash
# branches with unmerged work, and what files they touch
git branch --no-merged main --format="%(refname:short)"
git show --stat <branch>          # what changed, without checking out
git show <branch>:path/to/spec.md # read a file from another branch
```

## 3. Open threads — handoffs, notes, backlog

Scan the repo for work that's parked or pending:
- Handoff/notes/plan docs: look in `docs/`, the repo root, and any `notes/` or
  `handoff*` paths for markdown. Surface each one's `Status:` line if present
  (e.g. "Proposed, not started", "In progress").
- **Docs on unmerged branches too** — a filesystem scan only sees the checked-out
  branch. Cross-check the branch list from step 2; read any spec or plan a
  branch tip adds with `git show <branch>:<path>`. A doc that exists only on a
  branch still counts as an open thread, and is usually the freshest one.
- Open PRs, with age and CI state (`gh pr list`). An old PR is not necessarily
  dead — check whether it still rebases before describing it as stale.
- In-code backlog markers near the active work: `TODO`, `FIXME`, hardcoded
  placeholders (e.g. a field stubbed `null` with a "see backlog" comment).

Prefer the project's own conventions if `CLAUDE.md` documents where plans,
specs, or backlogs live — read it when present and follow its pointers.

## Output format

Present a tight briefing under these headings (skip any section with nothing to
report rather than padding it):

```
## Caught up
[2-4 sentences: the recent arc from commits + branch, and anything uncommitted.]

## Working toward
[The apparent goal in flight — from the branch, latest commits, and any plan/spec
the repo points to, INCLUDING specs that exist only on an unmerged branch.]

## Open threads
[Handoff docs with their Status, parked backlog items, notable TODOs, open PRs
with age and CI state, and every unmerged branch with its date and tip subject.]

## Memory recall   (only if a recall plugin is installed)
[Fresh: the most relevant injected memories, briefly. Stale: a clear warning
that recall isn't live and a nudge to start the memory server.]
```

Keep it scannable — the user is reorienting, not reading a report. Lead with the
single most important thing (often "you stopped mid-change on X" or "memory recall
isn't running"). End by offering the obvious next action, not a menu.
