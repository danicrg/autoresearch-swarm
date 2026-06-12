#!/bin/bash
# run.sh — Local experiment runner
# Usage: ./run.sh <experiment-name>
# Returns 0 on success, 1 on failure
set -euo pipefail

EXPERIMENT_NAME="${1:?Usage: run.sh <experiment-name>}"

echo "Running experiment: $EXPERIMENT_NAME"
uv run train.py > run.log 2>&1
EXIT_CODE=$?
echo "EXIT_CODE=$EXIT_CODE" >> run.log

if [ $EXIT_CODE -eq 0 ]; then
    echo "Experiment completed successfully"
else
    echo "Experiment failed (exit code: $EXIT_CODE)"
    tail -n 20 run.log
fi

exit $EXIT_CODE
