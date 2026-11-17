# dlyw-skills

**Don't Lose Your Way.**

Every project has a moment where you look up and can't tell where you are, what
got finished, or what comes next. These skills are for that moment.

I learned the lesson from a fight where the hero was lost, got reminded of her
own way, and stood back up anyway. If you know, you know.

They are small, read-only skills for Claude Code and other agents that support
the `SKILL.md` format. They look at the real state of your work, tell you the
truth about it, and hand the next move back to you.

| Skill | Ask it | You get |
|---|---|---|
| [`pulse`](skills/pulse/SKILL.md) | "Where am I, and what's next?" | A short state briefing and a ranked next-items chart, with the payoff of each item |
| [`closeout`](skills/closeout/SKILL.md) | "Can I stop? What am I about to lose?" | What was finished, what is still open, an archive verdict (SAFE / SAFE WITH NOTES / NOT YET), and ranked next steps with a payoff for each |

Both skills only read and report. They never commit, push, delete, or archive
anything, and you stay in control of every action.

## Install

```bash
npx skills add NooRotic/dlyw-skills
```

Or copy a folder from `skills/` into `~/.claude/skills/` (user-level) or
`.claude/skills/` (per project).

## License

MIT. See [LICENSE](LICENSE).
