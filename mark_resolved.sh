#!/bin/bash
HASH=$(tail -n 100 error.log | md5sum | awk '{print $1}')
echo "$HASH" >> resolved.log
echo "✅ Marked $HASH as manually resolved."
