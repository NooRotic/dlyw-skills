---
name: pulse
license: MIT
description: Use this skill whenever the user wants an on-demand snapshot of where a project stands right now AND a prioritized list of what to do next — especially when they ask for a "next-items chart," "what should I work on," "what's next," "where are we," "give me the pulse / the state," "status chart," "what's pending," "lay out my options," or "what to upload / ship / run next." It produces ONE scannable briefing: a one-line recap of their current focus, tight topic sections, color/emoji-tagged panels for the project's key queues/pipelines/schedules, and — the centerpiece — a Master next-items chart (a prioritized action table). It is action-and-state oriented (what to DO next), meant for mid-work use rather than for reorienting after a long break. Reach for it even when the user does not say "pulse" — "what's the plan from here," "make me a chart of next items," "what's our upload order," or "where do I focus" all mean this. Works in any project type (content pipeline, dev repo, research) by auto-detecting that project's currencies.
---

# Pulse — project state + Master next-items chart

Turn the project's *current* state into one legible briefing that ends in a
prioritized **Master next-items chart**. The user is deciding what to do next —
give them the state and the ranked actions, not a wall of prose. The chart is the
payload; everything above it is the context that justifies the ranking.

If the user named a focus (e.g. "pulse the upload side", "what's next on video"),
scope the briefing to it but still end with the full next-items chart.

## 1. Discover the project's "currencies"

A good pulse reflects what *this* project actually trades in. Before gathering,
infer the 1–3 things that matter most right now, then gather evidence for them.
Read `CLAUDE.md` / `MEMORY.md` first if present — they usually name the trackers,
pipelines, and conventions to follow.

Common currencies by project type (pick what fits, don't force all):
- **Content / media pipeline:** upload queues & their planned order, publish
  schedule (e.g. per-platform/per-week), what's staged vs posted, render queues,
  episodes/assets in flight.
- **Dev repo:** branch + uncommitted work, open PRs and their checks, failing
  tests / CI, deploy/release state, TODO/FIXME near active code, backlog/plan docs.
- **Research / writing:** open questions, drafts and their status, sources to
  process, deadlines.

## 2. Gather — in parallel, then synthesize

Collect everything in **one batch** of tool calls (don't narrate each step):
- Git: current branch, working-tree status, last ~8 commits as a story.
- Plan/handoff/backlog/runsheet docs: scan `docs/`, repo root, `notes/`,
  `handoff*`, and any tracker the project names; surface each one's `Status:`.
- Live state: running background jobs/queues, logs with a DONE/summary line,
  publish logs, release dirs, CI/PR status, sprint boards — whatever the
  currencies in step 1 point at. Reconcile the *plan* against *reality* (e.g. a
  planned order vs. what's physically staged vs. what's already shipped).
- Memory index (`MEMORY.md` or equivalent) for parked work and recent decisions.

For a large or multi-domain project, fan out with subagents (one per currency /
subsystem) so coverage is broad and the main thread just synthesizes. Prefer
read-only agents; have each return structured findings, not file dumps.

Reconcile, don't just report: if the plan and the on-disk reality disagree, say
so — that gap is usually the most useful thing in the briefing.

## 3. Output format (match this exactly — it's the format the user wants)

Lead with a **one-line recap of their ask / current focus** (restate what they're
steering toward, so the briefing is visibly anchored to it).

Then tight **`## <Topic>`** sections — one per area that needs context before the
chart. Keep each to a few lines; cut anything that doesn't change a decision.

Then the **"good stuff" panels** — the project's key currencies as compact,
**color/emoji-tagged tables**. Tag each so they're glanceable (e.g. 🔵 for one
queue, 🟣 for another, ✅/⛔/⚠️ for status). Examples that worked well:
- `## 🔵 <Queue> — next N` → a short ordered table (rank, item, key fields, note),
  flagging items to skip/hold (parked, blocked, already done).
- `## 🟣 <Schedule> — shape` → the cadence/shape over time, not every row.
Pick the panels that fit this project; 1–3 is plenty. Every row should earn its place.

Then — **always, this is the centerpiece** — the **Master next-items chart**:

```
## ✅ Master next-items chart
| Priority | Item | Status / action | Payoff — what this gives you |
|---|---|---|---|
| 1 | <highest-leverage next action> | <ready? blocked on? the exact command/step> | <what is unlocked or gained once it's done> |
| 2 | ... | ... | ... |
```

Rules for the chart:
- **Rank by leverage**, not by area. #1 is the single best use of the next hour.
- Make **Status / action concrete**: the command to run, the file to open, the
  thing it's blocked on — never just "do X".
- **Payoff is mandatory on every row.** One short line on the concrete outcome the
  user gets: what it unlocks, what risk it removes, or what it ships. Write it as a
  result ("archive becomes safe", "3 videos go live Thursday"), never a restatement
  of the task ("finish the upload"). If you can't name a payoff, the item probably
  doesn't belong in the chart — and the payoff is what justifies the ranking.
- Fold in parked/blocked items low in the list so nothing is silently dropped.
- Keep it to the ~5–9 items that actually matter.

End with **one recommended next action and an offer to start it** — not a menu.

## Style
Scannable over complete. Lead with the most important thing. Convert relative
dates to absolute. Use tables for anything with >3 parallel rows. Don't pad a
section to look thorough — a skipped section beats a filler one. The whole thing
should be readable in under a minute and leave the user knowing exactly what to
do next.
