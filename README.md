# dlyw-skills

**Don't Lose Your Way.**
## The 46-second version
A short comic about the three moments these skills are for. Sound on.

https://github.com/user-attachments/assets/7d91914f-6ad6-4efe-b383-012a57d49ff9

Every project has a moment where you look up and can't tell where you are, what
got finished, or what comes next. These skills are for that moment.

I learned the lesson from a fight where the hero was lost, got reminded of her
own way, and stood back up anyway. If you know, you know.

They are small, read-only skills for Claude Code and other agents that support
the `SKILL.md` format. They look at the real state of your work, tell you the
truth about it, and hand the next move back to you.

| Skill | Ask it | You get |
|---|---|---|
| [`pulse`](skills/pulse/SKILL.md) | "Where am I, what moved last? and what's next?" | A short state briefing and a ranked next-items chart, with the payoff of each item |
| [`closeout`](skills/closeout/SKILL.md) | "Can I stop? Can I archive this now? What am I about to lose?" | What was finished, what is still open, an archive verdict (SAFE / SAFE WITH NOTES / NOT YET), and ranked next steps with a payoff for each |
| [`startup`](skills/startup/SKILL.md) | "New session, long weekend, catch me up. Where did I leave off?" | A returning-developer briefing: recent commits, uncommitted work, every unmerged branch (where unfinished work hides), open plans and PRs, and an optional memory-recall check |
| [`social-preview`](skills/social-preview/SKILL.md) | "My link preview or avatar looks wrong." | Fixes for cropped avatars, blank or stale link-preview cards, and Open Graph meta, with PowerShell scripts for the image work and a cache-busting playbook |

`pulse`, `closeout` and `startup` only read and report. They never commit, push,
delete, or archive anything, and you stay in control of every action.
`social-preview` writes image files you ask it to generate (its scripts need
Windows PowerShell).

## Install

```bash
npx skills add NooRotic/dlyw-skills
```

Or copy a folder from `skills/` into `~/.claude/skills/` (user-level) or
`.claude/skills/` (per project).

## License

MIT. See [LICENSE](LICENSE).
