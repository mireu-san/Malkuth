#!/bin/bash

echo "[INFO] Retrying batch..."
bash run_batch.sh 2>&1 | tee retry.log

if [ "$(cat .decision.tmp)" == "YES" ]; then
  bash solution_1.sh
  if [ $? -eq 0 ]; then
    echo "✅ Issue resolved automatically." > .resolution_status.tmp
    echo "SUCCESS" > .retry_result.tmp
  else
    echo "❌ Retry failed." > .resolution_status.tmp
    echo "FAILED" > .retry_result.tmp
  fi
else
  echo "⚠️ No retry attempted." > .resolution_status.tmp
  echo "SKIPPED" > .retry_result.tmp
fi
