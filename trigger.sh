#!/bin/bash

# 실행 및 로그 기록
bash run_batch.sh 2>&1 | tee error.log
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "[ERROR] Abnormality escape has been detected. Called Malkuth for validation."
  
  # Calling GPT
  bash call_malkuth.sh

  DECISION=$(cat .decision.tmp | xargs)

  if [ "$DECISION" == "YES" ]; then
    bash solution_1.sh
    if [ $? -eq 0 ]; then
      echo "✅ Issue resolved automatically." > .resolution_status.tmp
      echo "SUCCESS" > .retry_result.tmp
    else
      echo "❌ Retry failed." > .resolution_status.tmp
      echo "FAILED" > .retry_result.tmp
    fi
  elif [ "$DECISION" == "NO" ]; then
    echo "⚠️ Retry not attempted per GPT judgment." > .resolution_status.tmp
    echo "SKIPPED" > .retry_result.tmp
  else
    echo "❌ GPT returned unclear result. Manual validation required." > .resolution_status.tmp
    echo "N/A" > .retry_result.tmp
  fi

  # if failed, alert
  bash trumpet.sh

else
  echo "[INFO] Batch completed successfully."

  # if success, set default values
  echo "NO ERROR" > .summary.tmp
  echo "N/A" > .decision.tmp
  echo "N/A" > .retry_result.tmp
  echo "0" > .occurrence.tmp
  echo "✅ Batch completed successfully without errors." > .resolution_status.tmp

  bash trumpet.sh
fi
