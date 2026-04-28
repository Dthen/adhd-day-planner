---
name: adhd-day-planner
description: Generate ADHD-friendly daily plans with warm coaching voice for Obsidian vaults.
trigger: plan my day, daily plan, what's the plan for today, make me a plan
---

# ADHD Day Planner

Generate warm, structured daily plans optimized for ADHD brains. Interactive - will ask for clarification on vague tasks.

## Architecture
- **prepare.sh** outputs JSON with tasks, weather, context, counts
 - **Modes:**
   - `fresh` — new daily plan from yesterday's deferred + inbox
   - `continue` — existing daily note, add more tasks
   - `replan` — daily note exists, completed tasks preserved in `### ✅ Completed Tasks` section
 - Pulls **up to 30 tasks** total: 10 fresh from inbox + yesterday's deferred/icebox
 - Creates daily note SKELETON with icebox pre-populated at bottom
 - In `replan` mode, completed tasks from morning are extracted and added to skeleton
 - Tasks beyond 30 go to icebox for tomorrow
- **Hermes generates** warm British-English coaching plan
- **Interactive phase** - ask about vague tasks, break them down together
- **cleanup.sh** removes processed inbox tasks
- **icebox preserved** - unscheduled tasks from today's batch + rolling deferred

## Workflow

### Phase 1: Run Preparation
```bash
~/.hermes/skills/productivity/adhd-day-planner/scripts/prepare.sh
```
Outputs JSON with tasks, weather, context, counts.

Creates daily note skeleton with icebox at bottom.

The script uses these environment variables:
- `VAULT_PATH` — path to Obsidian vault (default: `$HOME/notes`)
- `INBOX_FILE` — path to inbox.md (default: `$VAULT_PATH/inbox.md`)
- `DAILY_FOLDER` — daily notes folder (default: `$VAULT_PATH/daily`)
- `LOCATION` — lat,lon for weather (default: 55.4586,-4.6292)

### Phase 2: Interactive Clarification
**Detect vague tasks** (large, undefined, unclear):
- "Fix the thing with the stuff"
- "Do the project"
- "Sort out that mess"

**Pause and ask user:** *"Task X seems vague - what's the actual first step here?"*

**Break down together:**
- User explains what they meant
- I suggest subtasks
- User confirms or adjusts
- We replace vague task with concrete steps

**Skip if:** User says "just mark it 🧠" or "I'll do it tomorrow"

### Phase 3: Priority Clarification

After prepare.sh buckets tasks by priority, review for **ambiguous priorities**:

**Auto-handle (no need to ask):**
- Tasks with 🔺 (high), ⏫ (med), 🔽 (low) already set
- Today: e.g., "📅 2026-04-27" 
- Overdue: past dates

**Pause and ask when unclear:**
- *Two similar-urgency tasks in conflict*: "I've got 'find microsoldering list' and 'research home automation' — which matters more to you right now?"
- *Missing priority context*: "You said 'fix the fence' — is that urgent or can it wait a few days?"
- *Cluster of medium-priority items*: "You've got 5 things that all feel 'should do soon' — any of these actually blocking other stuff?"
- *New vs existing*: "This new 'install SwiftShelf' just came in — bump it over the existing tasks today or keep it for later?"

**When uncertain which to prioritise:** Ask rather than guess. User knows their actual urgency; I only see dates and keywords.

**Skip if:** User says "just decide" or "whatever order is fine" — defer to script's default bucketing.

### Phase 4: Generate Plan
Generate warm, British-English coaching voice plan following the sophisticated ADHD scheduling logic.

**Generation Buffer Start Time:**
- Current time + 15 minutes buffer
- Round to nearest 5 or 10-minute mark
- Example: 20:56 + 15 = 21:11 → round to `21:10` or `21:15`

**The ADHD Tax (Lookup Table):** Estimate base time, round UP:
- 15 min base ➡️ Schedule 20 mins
- 30 min base ➡️ Schedule 40 mins
- 45 min base ➡️ Schedule 60 mins
- 60 min base ➡️ Schedule 75 mins
- 90 min base ➡️ Schedule 115 mins (Max focus block)

**Create Timeline:**
- Start at the rounded Generation Buffer Start Time
- Use exact minutes from lookup table for task blocks
- Insert 10-minute `☕ Break (Transition)` buffer between EVERY transition

**Momentum Starter:**
- First scheduled block = easiest/quickest win from context
- Scan for: simple habits, 15-min base tasks, low-friction items
- Never invent tasks not in input

**Anti-Waiting-Room Protocol (Fixed Appointments):**
- Lock appointments at EXACT time (e.g., `14:00 Dentist`)
- Insert mandatory 10-min `☕ Break (Prep/Transition)` immediately BEFORE
- Bridge 45-60 min gap before prep: ONLY habits/low-friction tasks
- NO 45+ min base tasks in that gap — prevents hyperfocus before appointments

**Biological Anchors (Meals):**
- Timeline crosses meal times → mandatory 60-min break
- `🥪 Lunch Break` (≈12:30-13:30) or `🍽️ Dinner Break` (≈18:30-19:30)
- NEVER schedule over these anchors
- 10-min transition buffer surrounding meals

**Vague Tasks:** When you encounter vague/undecidable tasks during generation:
- Prepend `🧠` emoji to task name
- Schedule 20 min for breakdown if energy permits
- If low energy (late night), place directly into Deferred
- `🧠` task REPLACES original — don't duplicate across sections

Apply active clarifications from Phase 2.

## Output Format

**NO PRE-CHATTER:** Start response EXACTLY with first heading. No conversational greetings.

**Tone:**
- Warm, encouraging, conversational British English coaching voice
- NOT deficit-focused, no clinical ADHD buzzwords
- Frame low energy positively
- Focus on capability and empowerment
- Vary vocabulary dynamically — avoid repetitive "cosy" / "You've got this"
- Keep every paragraph to 1-2 short sentences max
- Use paragraph breaks generously

**Output Sections:**
- ### 🌤️ Today's Weather *(2-3 engaging sentences, practical spin based on forecast)*
- ### 📊 Today at a Glance *(2-3 airy paragraphs on strategy, adjust tone for time of day)*
- ### 📋 The Plan *(timeline with scheduled tasks)*
- ### 🌟 Stretch Goals *(untimed tasks if any)*
- ### ⚡ Energy Notes *(1-3 breezy sentences: identify obvious hurdle, practical tip)*
- ### ⏩ Deferred Tasks *(untimed tasks that didn't fit)*

**OMIT SECTIONS ENTIRELY** if they have no items. Don't show empty headers.

**MONOSPACE TIMELINE FORMAT:** Scheduled times in backticks: `HH:MM - HH:MM`

**Correct Plan Format:**
```
- [ ] `09:00 - 09:40` 🔺 Renew home insurance 📅 2026-02-21 ➕ 2026-02-10
- [ ] `09:40 - 09:50` ☕ Break (Transition)
- [ ] `09:50 - 10:10` ✨ Habit: [Name from Context]
- [ ] `10:10 - 10:20` ☕ Break (Transition)
- [ ] `10:20 - 10:40` 🔽 🧠 [Original Vague Task Name] 📅 2026-02-22 ➕ 2026-02-20
- [ ] `10:40 - 10:50` ☕ Break (Transition)
```

**Zero-Drop Policy:** EVERY task from prepare.sh MUST appear in output — either in Timeline, Stretch Goals, or Deferred.

## Recurrence & Due Date Format (Obsidian Tasks)

**Due Date NLP:**
- Extract implied deadlines from natural language, add `📅 YYYY-MM-DD`:
  - "Submit report before Friday" → `📅` **Thursday** (day prior to deadline)
  - "Cancel Adobe before Tuesday" → `📅` **Monday** (day prior)
  - "Apply for thing by March 15" → `📅 2026-03-15`
- **Anchor to `➕` date, NEVER current date**
- Strip natural language from task name after extraction
- Example: "Cancel Adobe before Tuesday ➕ 2026-02-20" → `- [ ] Cancel Adobe 📅 2026-02-23 ➕ 2026-02-20`

**Recurrence NLP:**
- `every 2 days` → `🔁 every 2 days` (not "every two days")
- `every week on Thursday` → `🔁 every week on Thursday` (not "weekly")
- `every week on Friday` → `🔁 every week on Friday`
- Reference: https://publish.obsidian.md/tasks/Getting+Started/Recurring+Tasks

**Metadata Placement:**
- **Priority emoji FIRST** after checkbox: `- [ ] 🔺 Task name` 
- **Other metadata at VERY END:** `- [ ] 🔺 Task name 📅 2026-04-29 🔁 every 2 days ➕ 2026-04-28`

Generate warm, British-English coaching voice plan following the sophisticated ADHD scheduling logic.

**Generation Buffer Start Time:**
- Current time + 15 minutes buffer
- Round to nearest 5 or 10-minute mark
- Example: 20:56 + 15 = 21:11 → round to `21:10` or `21:15`

**Momentum Starter:**
- First scheduled block = easiest/quickest win from context
- Scan for: simple habits, 15-min base tasks, low-friction items
- Never invent tasks not in input

**Anti-Waiting-Room Protocol (Fixed Appointments):**
- Lock appointments at EXACT time (e.g., `14:00 Dentist`)
- Insert mandatory 10-min `☕ Break (Prep/Transition)` immediately BEFORE
- Bridge 45-60 min gap before prep: ONLY habits/low-friction tasks
- NO 45+ min base tasks in that gap — prevents hyperfocus before appointments

**Biological Anchors (Meals):**
- Timeline crosses meal times → mandatory 60-min break
- `🥪 Lunch Break` (≈12:30-13:30) or `🍽️ Dinner Break` (≈18:30-19:30)
- NEVER schedule over these anchors
- 10-min transition buffer surrounding meals

Apply active clarifications from Phase 2.

### Phase 4: Write Note
Insert generated plan after header. Keep icebox at bottom.

**Formatting Requirements:**
- **NO PRE-CHATTER:** Response starts EXACTLY with first heading (`### 🌤️ Today's Weather`)
- **British English:** prioritise, categorise, etc (not prioritize, categorize)
- **1-2 sentence paragraphs max** — ADHD-friendly, generous paragraph breaks
- **Omit empty headers:** Don't show section heading if section has no items
- **Time blocks:** Wrap in backticks: `HH:MM - HH:MM`

**Icebox = tasks NOT scheduled from today's 30-task pool:**
- Defer some of today's 30, schedule others — that's the decision
- Unscheduled tasks from today's batch
- Overflow beyond 30 tasks
- These roll into tomorrow's planning pool

### Phase 5: Cleanup
Run `~/.hermes/skills/productivity/adhd-day-planner/scripts/cleanup.sh`

**What cleanup does:** Removes the 10 tasks pulled from `inbox.md` that entered today's planning pool. Uses `grep -v` (inverse match) to filter out lines matching `/tmp/inbox_pulled.txt`. **Only affects inbox.md** — daily note and deferred tasks are untouched.

**When to run:** Always after writing the daily note, even for replan mode. The pulled tasks need to be removed from inbox so they don't reappear tomorrow.

## Tailoring Modifiers

Natural language modifiers to "plan my day":

**Focus/Filter:** "focusing on Spanish", "skip work stuff", "easy wins only"
→ Selectively schedule matching tasks; others stay in "Upcoming Tasks"

**Time/Energy:** "3 hours max", "low energy day", "momentum mode", "deep focus blocks"
→ Adjust schedule density, break frequency, coaching tone

**Approach:** "gentle", "minimum viable", "power through"
→ Adapt to match user's intent

**Clarification preference:** "don't ask questions", "just get it done"
→ Skip Phase 2 interactive, defer vague tasks to icebox

When uncertain, ASK rather than guess.

## Vague Task Detection

Task is "vague" if:
- No clear action verb ("the thing with stuff")
- Too large to estimate ("fix the kitchen")
- References undefined items ("that email", "those files")
- Duration unclear and likely >2 hours

**When detected:** Pause, ask user "What specifically would the first step be?", break down interactively together.

## Output Requirements
- British English (prioritise, not prioritize)
- 1-2 sentence paragraphs (ADHD-friendly)
- Warm, non-clinical coaching voice
- 10-min ☕ breaks between tasks
- ADHD Tax: 15→20, 30→40, 45→60, 60→75, 90→115 max
- Anti-waiting-room protocol for appointments
- Momentum starter
- Zero-drop policy (nothing lost)

## Files
- Script dir: `~/.hermes/skills/productivity/adhd-day-planner/scripts/`
- Context: `~/.hermes/skills/productivity/adhd-day-planner/scripts/context.md` *(user-configurable)*
- Inbox: `~/notes/inbox.md` *(user's Obsidian vault)*
- Output: `~/notes/daily/YYYY-MM-DD.md` *(user's Obsidian vault)*
- Icebox: Pre-populated in daily note skeleton by prepare.sh — contains yesterday's deferred tasks

## ⚠️ Common Failure Modes (lessons learned)

1. **DO NOT view inbox.md directly** — use prepare.sh's JSON output only
2. **Icebox is future work** — yesterday's deferred passed to prompt as today's task pool
3. **Recurrence NLP is mandatory** — "every 2 days" → add `🔁 every 2 days` tag

See Workflow Adherence section for: writing directly to note, not chatting the plan first.

---

## Troubleshooting & Fixes

### Weather is empty/hourly array missing
**Root cause:** `jq` not installed. Script requires `jq` to parse Open-Meteo JSON.

**Fix:**
```bash
# Ubuntu/Debian
sudo apt-get install jq

# Arch
sudo pacman -S jq
```

**Test it works:**
```bash
curl -s "https://api.open-meteo.com/v1/forecast?latitude=55.4586&longitude=-4.6292&current_weather=true" | jq .current_weather
```

### Weather comes back but looks wrong
- Script uses **Open-Meteo API**, not `wttr.in` or other services
- Don't substitute APIs — the jq filter is specific to Open-Meteo's JSON structure

---

## Workflow Adherence

### CRITICAL: Write the note, don't ask
Skill explicitly says to write to `$VAULT/daily/YYYY-MM-DD.md`. Do **not** ask "want me to write this?" — this breaks the user's flow and adds friction they explicitly set up the system to avoid.

When user says "make a plan" or "plan my day":
1. Run prepare.sh
2. Ask clarifying questions if needed (Phase 2)
3. **Generate and WRITE directly** — no "is this okay?" approval-seeking
4. Run cleanup.sh

Exception: Only ask before writing if the user explicitly specified "draft it first" or asked to review before commit.

---

## Real-Time Inbox Capture

**CRITICAL:** Proactively prompt user to add tasks to inbox during conversation.

When user mentions a task/responsibility in passing:
- "I need to fix the fence"
- "Should really order more flies for Cleopatra"
- "Hmm, need to figure out the gravel situation"
- Any "I should..." or "I need to..." statements

**Response:** "Want me to chuck that in your inbox so it doesn't get lost?"

**Why:** ADHD brains generate tasks constantly but forget them instantly. Catching tasks *as they surface* (before the planning session) prevents "oh that was important" realizations at 2am.

**Add immediately via:**
```bash
echo "- [ ] TASK_NAME ➕ $(date +%Y-%m-%d)" >> ~/notes/inbox.md
```

**Don't wait for planning session.** Don't assume they'll remember. Just add it.