#!/bin/bash
# ===== ORCAROUTER SIGNAL SCOUT — APPEND WORKFLOW =====
# 
# USAGE:
#   ./merge-signals.sh <new-signals.json>
#
# This script reads the existing signals.json, appends new signals
# (skipping duplicates by company + detail), and writes back.
#
# For the Signal Scout agent:
#   1. Find your signals
#   2. Output to /tmp/scout-new.json
#   3. Run this script: bash /workspace/orca-playbook/merge-signals.sh /tmp/scout-new.json
#   4. Commit & push: git add signals.json && git commit -m "Add [N] new signals" && git push
#
# The signals.json will accumulate forever — never losing historical data.

EXISTING="/workspace/orca-playbook/signals.json"
NEW_FILE="${1:-/tmp/scout-new.json}"

if [ ! -f "$NEW_FILE" ]; then
  echo "❌ No new signals file found at $NEW_FILE"
  echo "Usage: bash $0 <new-signals.json>"
  exit 1
fi

# Check if existing file exists, if not create empty array
if [ ! -f "$EXISTING" ]; then
  echo "[]" > "$EXISTING"
fi

# Use python to merge
python3 << 'PYEOF'
import json, sys

existing_path = "/workspace/orca-playbook/signals.json"
new_path = "/tmp/scout-new.json"

with open(existing_path, 'r') as f:
    existing = json.load(f)

with open(new_path, 'r') as f:
    new_signals = json.load(f)

# Build lookup key from existing (company + first 50 chars of detail)
seen = set()
for s in existing:
    key = (s.get('company',''), s.get('detail','')[:50])
    seen.add(key)

imported = 0
for s in new_signals:
    key = (s.get('company',''), s.get('detail','')[:50])
    if key not in seen:
        existing.append(s)
        seen.add(key)
        imported += 1

with open(existing_path, 'w') as f:
    json.dump(existing, f, indent=2)

print(f"✅ Merged: {imported} new signals added to signals.json")
print(f"📊 Total: {len(existing)} signals now in archive")
PYEOF
