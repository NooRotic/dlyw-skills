# Agent skills

Small, read-only skills for Claude Code and other agents that support the
`SKILL.md` format.

| Skill | Use it when | What you get |
|---|---|---|
| [`closeout`](skills/closeout/SKILL.md) | You're about to archive, close, or walk away from a project, branch, or session | What was completed, what's still open (blockers vs. nice-to-haves), an archive verdict (SAFE / SAFE WITH NOTES / NOT YET), and ranked next steps with a payoff for each |
| [`pulse`](skills/pulse/SKILL.md) | You want to know where a project stands and what to do next | A short state briefing and a prioritized next-items chart, with the payoff of each item |

Both skills only read and report. They never commit, push, delete, or archive
anything, and the user stays in control of every action.

## Install

```bash
npx skills add <owner>/<repo>
```

Or copy a folder from `skills/` into `~/.claude/skills/` (user-level) or
`.claude/skills/` (per project).

## License

MIT. See [LICENSE](LICENSE).
