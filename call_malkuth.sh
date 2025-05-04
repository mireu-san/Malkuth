#!/bin/bash
source .env

LOG_FILE="error.log"
LOG_CONTENT=$(grep "\[ERROR\]" "$LOG_FILE" | tail -n 1)

# Generate a hash of the log content to track unique errors
ERROR_HASH=$(echo "$LOG_CONTENT" | md5sum | awk '{print $1}')
OCCURRENCE=1
HISTORY_FILE="history.log"
RESOLVED_FILE="resolved.log"

# Update or initialize occurrence count for this error hash
if ! grep -q "$ERROR_HASH" "$HISTORY_FILE" 2>/dev/null; then
  echo "$ERROR_HASH,1" >> "$HISTORY_FILE"
else
  OCCURRENCE=$(grep "$ERROR_HASH" "$HISTORY_FILE" | cut -d',' -f2)
  OCCURRENCE=$((OCCURRENCE + 1))
  sed -i "s/^$ERROR_HASH.*/$ERROR_HASH,$OCCURRENCE/" "$HISTORY_FILE"
fi

# Save the occurrence count
echo "$OCCURRENCE" > .occurrence.tmp

# Check if a human previously resolved it
if grep -q "$ERROR_HASH" "$RESOLVED_FILE" 2>/dev/null; then
  HUMAN_FEEDBACK="✅ This error was previously marked as resolved by a human (via Discord: 'y')."
else
  HUMAN_FEEDBACK="No manual resolution record found."
fi

# === GPT Prompt ===
PROMPT="$LOG_CONTENT"

# === Call OpenAI GPT API ===
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "system",
      "content": "You will be given a log. If it contains the phrase 'Abnormality escape has been detected', reply only with: NO. Otherwise, reply YES. Do not include any explanation, punctuation, or extra words."
    },
    {
      "role": "user",
      "content": "$PROMPT"
    }
  ],
  "temperature": 0
}
EOF
)

# Save raw JSON for debugging
echo "$RESPONSE" > raw_gpt_response.json

# If empty, exit with error
if [ -z "$RESPONSE" ] || [ "$RESPONSE" == "null" ]; then
  echo "[ERROR] GPT API call failed or returned null." >&2
  echo "N/A" > .summary.tmp
  echo "N/A" > .decision.tmp
  exit 1
fi

# Extract GPT content and trim whitespace
GPT_CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | xargs)
echo "$GPT_CONTENT" > .summary.tmp

# Extract YES or NO (case-insensitive)
DECISION=$(echo "$GPT_CONTENT" | grep -Eio 'YES|NO' | head -n1 | xargs)
if [ -z "$DECISION" ]; then
  DECISION="N/A"
fi
echo "$DECISION" > .decision.tmp
