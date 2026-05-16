# AGENTS.md — ADHD Day Planner

## What This Project Is

Daily planning pipeline: shell scripts gather tasks and context → LLM generates a warm, structured schedule → plan gets written directly into the Obsidian vault.

## Workflow

```
inbox.md ──▶ prepare.sh ──▶ LLM generates plan ──▶ cleanup.sh
                                    │
                                    ▼
                          ~/notes/daily/YYYY-MM-DD.md
```

1. **prepare.sh** gathers tasks, fetches weather, reads context, outputs JSON + writes a skeleton note with icebox.
2. **LLM** reads the JSON, asks clarifying questions about vague tasks if needed, generates the schedule, and writes it directly into the note.
3. **cleanup.sh** removes the inbox tasks that were pulled into today's plan.

---

## Key Files

| File | Purpose |
|------|---------|
| `scripts/prepare.sh` | Gathers tasks, outputs JSON, writes note skeleton |
| `scripts/cleanup.sh` | Removes processed inbox tasks |
| `scripts/context.md` | Your habits, goals, energy patterns (user-editable) |
| `SKILL.md` | Full generation rules for the LLM |
| `~/notes/inbox.md` | Task capture file |
| `~/notes/daily/YYYY-MM-DD.md` | Daily plan output |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VAULT_PATH` | `$HOME/notes` | Path to Obsidian vault |
| `INBOX_FILE` | `$VAULT_PATH/inbox.md` | Task capture file |
| `DAILY_FOLDER` | `$VAULT_PATH/daily` | Where plans are written |
| `LOCATION` | `55.4586,-4.6292` | `lat,lon` for weather |
| `CONTEXT_FILE` | `scripts/context.md` | Personal context |

---

## When the User Says "Plan my day"

1. Run `prepare.sh`
2. Parse JSON output
3. Ask clarifying questions about vague tasks if needed (Phase 2 in SKILL.md)
4. Generate schedule per SKILL.md rules (ADHD Tax, breaks, meals, momentum starter, etc.)
5. **Write directly to `$DAILY_FOLDER/YYYY-MM-DD.md`** — insert after header, keep icebox at bottom
6. Run `cleanup.sh`

**Do NOT ask "is this okay?" before writing.**

Exception: user explicitly says "draft it first" or "review before writing."

---

## When the User Says "Replan"

- If today's note exists, prepare.sh sets `mode=replan` and preserves completed tasks (`- [x]`) in a `### ✅ Completed Tasks` section
- Regenerate the schedule portion only, keeping completed tasks intact

---

## Plan Generation Quick Reference

Reference SKILL.md for full detail. Non-negotiables:

- **ADHD Tax:** round estimates UP — 15→20, 30→40, 45→60, 60→75, 90→115 max
- **10-min ☕ breaks** between every transition
- **Biological anchors:** 60-min meal breaks at ~12:30 and ~18:30, never schedule over
- **Anti-waiting-room protocol:** fixed appointments locked at exact time, 10-min prep break before, low-friction tasks only in the gap
- **Momentum starter:** first block is easiest/quickest win
- **Zero-drop policy:** every task appears in timeline, stretch goals, or deferred
- **No pre-chatter:** response starts exactly with `### 🌤️ Today's Weather`
- **British English:** prioritise, categorise, etc.
- **1-2 sentence paragraphs max**
- **Monospace times:** backticks `HH:MM - HH:MM`

---

## Rules

- **Write directly to the note, don't ask.** The system is built for zero-friction generation.
- **Never invent tasks.** Only schedule what came from prepare.sh's JSON.
- **Only inbox.md gets cleaned.** cleanup.sh only touches inbox; daily notes and deferred tasks are untouched.
