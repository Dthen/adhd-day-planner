#!/bin/bash
# ADHD Day Planner - Preparation Script
# Gathers tasks, prepares data, writes icebox, outputs focus queue for LLM

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Paths
VAULT_PATH="${VAULT_PATH:-$HOME/notes}"
INBOX_FILE="${INBOX_FILE:-$VAULT_PATH/inbox.md}"
CONTEXT_FILE="${CONTEXT_FILE:-$SCRIPT_DIR/context.md}"
DAILY_FOLDER="${DAILY_FOLDER:-$VAULT_PATH/daily}"

# Location for weather (default: Ayr, Scotland)
LOCATION="${LOCATION:-55.4586,-4.6292}"

TODAY=$(date +"%Y-%m-%d")
CURRENT_TIME=$(date +"%H:%M")

# Ensure daily folder exists
mkdir -p "$DAILY_FOLDER"

TODAY_FILE="$DAILY_FOLDER/$TODAY.md"

# --- GATHER TASKS ---
MAX_INBOX=10
RAW_INBOX_TASKS=""
INBOX_TASKS=""

if [ -f "$INBOX_FILE" ]; then
    ALL_RAW_INBOX=$(grep -E "^\s*-\s*\[ \]" "$INBOX_FILE" 2>/dev/null)
    if [ -n "$ALL_RAW_INBOX" ]; then
        RAW_INBOX_TASKS=$(echo "$ALL_RAW_INBOX" | head -n "$MAX_INBOX")
        INBOX_TASKS=$(echo "$RAW_INBOX_TASKS" | sed 's/[☕✨🥪🍽️]//g' | sed -E 's/ `[0-9]{2}:[0-9]{2} - [0-9]{2}:[0-9]{2}`//')
    fi
fi

# --- SOURCE FILE FOR REPLANNING ---
if [ -f "$TODAY_FILE" ]; then
  SOURCE_FILE="$TODAY_FILE"
  MODE="replan"
else
  MOST_RECENT=$(find "$DAILY_FOLDER" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort -r | head -n 1)
  if [ -n "$MOST_RECENT" ]; then
    SOURCE_FILE="$MOST_RECENT"
    MODE="continue"
  else
    SOURCE_FILE=""
    MODE="fresh"
  fi
fi

# Get tasks from source (strip breaks/habits)
if [ -n "$SOURCE_FILE" ] && [ -f "$SOURCE_FILE" ]; then
  DAILY_TASKS=$(grep -E "^\s*-\s*\[ \]" "$SOURCE_FILE" 2>/dev/null | grep -vE "☕|✨|🥪|🍽️" | sed -E 's/ `[0-9]{2}:[0-9]{2} - [0-9]{2}:[0-9]{2}`//')
  # Extract completed tasks when replanning
  if [ "$MODE" = "replan" ]; then
    COMPLETED_TASKS=$(grep -E "^\s*-\s*\[x\]" "$SOURCE_FILE" 2>/dev/null | grep -vE "☕|✨|🥪|🍽️" | sed -E 's/ `[0-9]{2}:[0-9]{2} - [0-9]{2}:[0-9]{2}`//')
  else
    COMPLETED_TASKS=""
  fi
else
  DAILY_TASKS=""
  COMPLETED_TASKS=""
fi

# --- BUCKET TASKS BY PRIORITY ---
MAX_TASKS=30

PRIO_HIGH_TASKS=""
PRIO_MED_TASKS=""
PRIO_LOW_TASKS=""
OVERDUE_RAW=""
TODAY_TASKS=""
UNTRIAGED_TASKS=""
FUTURE_TASKS=""
ICEBOX_BACKLOG=""

COUNT_PRIO=0
COUNT_OVERDUE=0
COUNT_TODAY=0
COUNT_UNTRIAGED=0

# Parse tasks into buckets
while IFS= read -r task; do
    [ -z "$task" ] && continue
    
    # Future date check
    if [[ "$task" =~ 📅\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        task_date="${BASH_REMATCH[1]}"
        if [[ "$task_date" > "$TODAY" ]]; then
            FUTURE_TASKS+="$task"$'\n'
            continue
        fi
    fi
    
    # High priority
    if [[ "$task" =~ 🔺 ]]; then
        PRIO_HIGH_TASKS+="$task"$'\n'
        ((COUNT_PRIO++))
    # Date-based
    elif [[ "$task" =~ 📅\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        task_date="${BASH_REMATCH[1]}"
        if [[ "$task_date" < "$TODAY" ]]; then
            OVERDUE_RAW+="$task"$'\n'
            ((COUNT_OVERDUE++))
        else
            TODAY_TASKS+="$task"$'\n'
            ((COUNT_TODAY++))
        fi
    # Medium priority
    elif [[ "$task" =~ ⏫ ]]; then
        PRIO_MED_TASKS+="$task"$'\n'
    # Low priority
    elif [[ "$task" =~ 🔽 ]]; then
        PRIO_LOW_TASKS+="$task"$'\n'
    # Untriaged
    else
        UNTRIAGED_TASKS+="$task"$'\n'
        ((COUNT_UNTRIAGED++))
    fi
done <<< "$DAILY_TASKS"

# Sort overdue by date (oldest first)
OVERDUE_SORTED=$(echo -n "$OVERDUE_RAW" | sed -E 's/^(.*)📅 ([0-9]{4}-[0-9]{2}-[0-9]{2})(.*)$/\2|\1📅 \2\3/' | sort | cut -d'|' -f2- 2>/dev/null)

# Build focus queue
FOCUS_QUEUE=$(echo -e "${PRIO_HIGH_TASKS}\n${OVERDUE_SORTED}\n${TODAY_TASKS}\n${INBOX_TASKS}\n${UNTRIAGED_TASKS}\n${PRIO_MED_TASKS}\n${PRIO_LOW_TASKS}" | grep -v '^[[:space:]]*$')

# Handle overflow
FOCUS_QUEUE_COUNT=$(echo "$FOCUS_QUEUE" | grep -c "\- \[ \]")
if [ "$FOCUS_QUEUE_COUNT" -gt "$MAX_TASKS" ]; then
    LLM_TASKS=$(echo "$FOCUS_QUEUE" | head -n "$MAX_TASKS")
    QUEUE_OVERFLOW=$(echo "$FOCUS_QUEUE" | tail -n +$(( MAX_TASKS + 1 )))
    ICEBOX_BACKLOG=$(echo -e "${QUEUE_OVERFLOW}\n${FUTURE_TASKS}" | grep -v '^[[:space:]]*$')
else
    LLM_TASKS="$FOCUS_QUEUE"
    ICEBOX_BACKLOG=$(echo "$FUTURE_TASKS" | grep -v '^[[:space:]]*$')
fi

# --- GATHER WEATHER ---
# Parse LOCATION (format: lat,lon)
LAT="${LOCATION%,*}"
LON="${LOCATION#*,}"

if [ -n "$LAT" ] && [ -n "$LON" ]; then
    WEATHER=$(curl -s --max-time 6 \
        "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current_weather=true&hourly=precipitation_probability&forecast_days=1" \
        | jq -r '.current_weather as $now | .hourly.precipitation_probability[0:6] | max as $rain | "Now: \($now.temperature)°C, Wind \($now.windspeed) km/h. Rain risk next 6h: \($rain)%"' 2>/dev/null)
    if [ -z "$WEATHER" ]; then
        WEATHER="Weather data unavailable"
    fi
else
    WEATHER="Location not set"
fi

# --- READ CONTEXT ---
CONTEXT=$(cat "$CONTEXT_FILE" 2>/dev/null)
[ -z "$CONTEXT" ] && CONTEXT="No context provided."

# --- CREATE DAILY NOTE WITH ICEBOX ---
if [ -n "$(echo "$ICEBOX_BACKLOG" | tr -d '[:space:]')" ] || [ -n "$(echo "$COMPLETED_TASKS" | tr -d '[:space:]')" ]; then
  if [ "$MODE" = "replan" ]; then
    cat > "$TODAY_FILE" << EOF
# 📅 Daily Plan - $TODAY



### 📅 Upcoming Tasks
$ICEBOX_BACKLOG

### ✅ Completed Tasks
$COMPLETED_TASKS
EOF
  else
    cat > "$TODAY_FILE" << EOF
# 📅 Daily Plan - $TODAY



### 📅 Upcoming Tasks
$ICEBOX_BACKLOG
EOF
  fi
else
  cat > "$TODAY_FILE" << EOF
# 📅 Daily Plan - $TODAY


EOF
fi

# Escape context for JSON (multi-line)
context_escaped=$(echo "$CONTEXT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()), end=""' 2>/dev/null || echo '"No context"')

# Build tasks JSON array
tasks_json="["
first=true
while IFS= read -r line; do
    [ -z "$line" ] && continue
    escaped_line=$(echo "$line" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip()), end=""' 2>/dev/null || echo "null")
    if [ "$first" = true ]; then
        first=false
    else
        tasks_json+=","
    fi
    tasks_json+="$escaped_line"
done <<< "$LLM_TASKS"
tasks_json+="]"

# Calculate counts (trim newlines)
inbox_count=$(echo "$INBOX_TASKS" | grep -c "\- \[ \]" 2>/dev/null | tr -d '\n' || echo 0)
focus_count=$(echo "$LLM_TASKS" | grep -c "\- \[ \]" 2>/dev/null | tr -d '\n' || echo 0)
icebox_count=$(echo "$ICEBOX_BACKLOG" | grep -c "\- \[ \]" 2>/dev/null | tr -d '\n' || echo 0)

# Escape inbox processed for JSON
inbox_processed_escaped=$(echo "$INBOX_TASKS" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip()), end=""' 2>/dev/null || echo '""')

# Output JSON for LLM
cat << EOF
{
  "date": "$TODAY",
  "current_time": "$CURRENT_TIME",
  "mode": "$MODE",
  "weather": $(echo "$WEATHER" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip()), end=""' 2>/dev/null || echo '""'),
  "context": $context_escaped,
  "focus_tasks": $tasks_json,
  "task_counts": {
    "high_priority": $COUNT_PRIO,
    "overdue": $COUNT_OVERDUE,
    "due_today": $COUNT_TODAY,
    "untriaged": $COUNT_UNTRIAGED,
    "inbox_pulled": $inbox_count,
    "focus_total": $focus_count,
    "icebox": $icebox_count
  },
  "inbox_processed": $inbox_processed_escaped
}
EOF

# Save pulled inbox tasks for cleanup
if [ -n "$RAW_INBOX_TASKS" ]; then
    echo "$RAW_INBOX_TASKS" | grep -v '^[[:space:]]*$' > /tmp/inbox_pulled.txt
fi
