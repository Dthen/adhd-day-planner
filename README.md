# 🧠 ADHD Day Planner

A warm, structured daily planner optimised for ADHD brains. Built for **Obsidian** using shell scripts for the mechanical work and LLMs for narrative generation.

## What It Does

Drop tasks into an `inbox.md`, run one command, and get a warm, coaching-voiced daily schedule written directly into your Obsidian vault — complete with weather, energy-aware timing, and a zero-drop policy that ensures nothing gets lost.

## Workflow

```
inbox.md ──▶ prepare.sh ──▶ LLM generates plan ──▶ cleanup.sh
                                    │
                                    ▼
                          ~/notes/to-do/YYYY-MM-DD.md
```

### 1. Prepare (`prepare.sh`)
Gathers up to **30 tasks** from:
- Your **inbox** (first 10 unchecked items)
- **Yesterday's deferred/icebox** tasks (from the previous daily note)
- Priority-based bucketing: 🔺 high, ⏫ medium, 🔽 low, overdue, untriaged

Outputs a JSON blob with tasks, weather, context, and task counts.

### 2. Generate Plan
The LLM produces a warm, British-English coaching plan with:
- **ADHD Tax**: base estimates rounded up (15→20, 30→40, 60→75)
- **10-min transition breaks** between every task
- **Momentum starter**: easiest win first
- **Biological anchors**: 60-min meal breaks (lunch ~12:30, dinner ~18:30)
- **Anti-waiting-room protocol**: gentle prep before fixed appointments
- **Zero-drop policy**: every task lands in the timeline, stretch goals, or deferred icebox

### 3. Cleanup (`cleanup.sh`)
Removes the inbox tasks that were pulled into today's plan, so they don't reappear tomorrow.

## Key Features

| Feature | Description |
|---------|-------------|
| **Interactive clarification** | Catches vague tasks and breaks them down with you first |
| **Replanning support** | Already started today? Replan preserves completed tasks |
| **Rolling icebox** | Deferred tasks from yesterday auto-appear in tomorrow's pool |
| **Weather-aware** | Fetches local weather to add practical spin to the plan |
| **Context-aware** | Reads `context.md` for your habits, energy patterns, and goals |
| **Obsidian Tasks compatible** | Supports priority emojis, due dates, recurrence, and metadata |

## Setup

### Prerequisites

- `bash`
- `jq` (for weather JSON parsing)
- `curl`
- Python 3 (for JSON string escaping)
- An Obsidian vault
- An LLM agent that can run the scripts (e.g. Hermes, Claude Code, etc.)

### Configuration

Set these environment variables (or accept the defaults):

| Variable | Default | Description |
|----------|---------|-------------|
| `VAULT_PATH` | `$HOME/notes` | Path to your Obsidian vault |
| `INBOX_FILE` | `$VAULT_PATH/inbox.md` | Your task capture file |
| `DAILY_FOLDER` | `$VAULT_PATH/to-do` | Where daily plans are written |
| `LOCATION` | `55.4586,-4.6292` | `lat,lon` for weather (default: Ayr, Scotland) |

Copy `scripts/context.md.example` to `scripts/context.md` and fill in your habits, goals, and constraints.

## Installation

```bash
git clone https://github.com/Dthen/adhd-day-planner.git
cd adhd-day-planner

# Optional: add to PATH or symlink the scripts directory
```

## Usage

### Manual run

```bash
# Phase 1: gather tasks
./scripts/prepare.sh

# Phase 2: feed output to your LLM agent, generate plan
# Phase 3: clean up inbox
./scripts/cleanup.sh
```

### With an agent

If your agent supports skills/plugins, point it at the `SKILL.md`. It will:
1. Auto-run `prepare.sh` when you say "plan my day"
2. Ask clarifying questions about vague tasks
3. Write the plan directly to your Obsidian vault
4. Auto-run `cleanup.sh`

## File Structure

```
adhd-day-planner/
├── README.md
├── SKILL.md                    # Full agent instructions (for LLM)
├── .gitignore                  # Ignores personal context.md
├── scripts/
│   ├── prepare.sh              # Gathers tasks, outputs JSON, writes note skeleton
│   ├── cleanup.sh              # Removes processed inbox tasks
│   └── context.md.example      # Template for your personal context
```

## Task Format

Tasks follow the [Obsidian Tasks](https://publish.obsidian.md/tasks/Getting+Started/Getting+Started) convention:

```markdown
- [ ] 🔺 Renew home insurance 📅 2026-02-21 ➕ 2026-02-10
- [ ] ⏫ Call dentist 🔁 every week on Thursday
- [ ] Clean out garage
```

| Symbol | Meaning |
|--------|---------|
| `- [ ]` | Unchecked task |
| `- [x]` | Completed (used in replanning) |
| 🔺 | High priority |
| ⏫ | Medium priority |
| 🔽 | Low priority |
| 📅 | Due date |
| 🔁 | Recurrence |
| ➕ | Created date |
| ✨ | Habit (auto-scheduled around tasks) |
| 🧠 | Vague/needs breakdown |

## Context File

`scripts/context.md` lets you tell the planner about your life so it can make better decisions:

- **Long-term goals** (fluency targets, career aims)
- **Habit blocks** (short, flexible habits to slot into gaps)
- **Energy patterns** (morning person? crash at 3pm?)
- **Constraints** (fixed appointments, hard limits)
- **Biological anchors** (medication times, meal routines)

## Output Example

```markdown
# 📅 Daily Plan - 2026-05-07

### 🌤️ Today's Weather
Now: 14°C, Wind 12 km/h. Rain risk next 6h: 0%. Lovely day for a wander once the jobs are done.

### 📊 Today at a Glance
You've got a tidy batch today — nothing screaming down the wire.

Priority is your overdue insurance task. Get that sorted first while your brain is fresh.

### 📋 The Plan
- [ ] `09:00 - 09:40` 🔺 Renew home insurance 📅 2026-02-21 ➕ 2026-02-10
- [ ] `09:40 - 09:50` ☕ Break (Transition)
- [ ] `09:50 - 10:10` ✨ Spanish input (20 mins)
- [ ] ...

### ⏩ Deferred Tasks
- [ ] Research home automation
- [ ] Fix the fence
```

## Tailoring Modifiers

When asking the agent to plan, add natural language modifiers:

- **Focus**: "focusing on Spanish", "skip work stuff"
- **Energy**: "low energy day", "3 hours max", "momentum mode"
- **Approach**: "gentle", "minimum viable", "power through"
- **No questions**: "just get it done" → skips interactive clarification

## Troubleshooting

**Weather is empty?**
`jq` might not be installed: `sudo apt-get install jq`

**Inbox tasks keep reappearing?**
Make sure `cleanup.sh` runs after planning. It removes pulled tasks from `inbox.md`.

## Licence

[0BSD](https://opensource.org/licenses/0BSD) — zero conditions. Use it, fork it, sell it, whatever.