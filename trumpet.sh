#!/bin/bash
source .env

SUMMARY=$(cat .summary.tmp)
DECISION=$(cat .decision.tmp)
RETRY_RESULT=$(cat .retry_result.tmp 2>/dev/null || echo "N/A")
OCCURRENCE=$(cat .occurrence.tmp 2>/dev/null || echo "unknown")
RESOLUTION=$(cat .resolution_status.tmp 2>/dev/null || echo "N/A")

# Plain text style message (no Markdown)
MESSAGE="🛠️ SephirahMalkuth Report
Error Summary:
$SUMMARY

Decision: $DECISION"

if [ "$DECISION" == "YES" ]; then
  MESSAGE+="
Retry Attempted: ✅ Yes"
else
  MESSAGE+="
Retry Attempted: ❌ No"
fi

MESSAGE+="
Retry Result: $RETRY_RESULT
Historical Occurrence: $OCCURRENCE time(s)
Resolution Status: $RESOLUTION"

# JSON escape and send
PAYLOAD=$(jq -Rn --arg content "$MESSAGE" '{content: $content}')

curl -X POST -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$DISCORD_WEBHOOK_URL"
