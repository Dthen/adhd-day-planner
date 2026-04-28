#!/bin/bash
# ADHD Day Planner - Cleanup Script
# Removes processed inbox tasks

INBOX_FILE="${INBOX_FILE:-$HOME/notes/inbox.md}"
PULLED_FILE="/tmp/inbox_pulled.txt"

if [ -f "$PULLED_FILE" ] && [ -f "$INBOX_FILE" ]; then
    # Remove the pulled lines from inbox
    grep -v -F -f "$PULLED_FILE" "$INBOX_FILE" > "$INBOX_FILE.tmp"
    mv "$INBOX_FILE.tmp" "$INBOX_FILE"
    rm -f "$PULLED_FILE"
    
    # Report remaining
    REMAINING=$(grep -c "^\s*-\s*\[ \]" "$INBOX_FILE" 2>/dev/null || echo 0)
    if [ "$REMAINING" -gt 0 ]; then
        echo "📥 $REMAINING tasks remain in inbox for tomorrow"
    else
        echo "📥 Inbox cleared"
    fi
fi
