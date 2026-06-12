#!/bin/bash
# submit-job.sh — Submit a single autoresearch training job to k8s
# Usage: ./k8s/submit-job.sh <experiment-name>
# Returns 0 on success, 1 on failure/timeout
set -euo pipefail

EXPERIMENT_NAME="${1:?Usage: submit-job.sh <experiment-name>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMEOUT="${AR_JOB_TIMEOUT:-600}"  # 10 minutes default, override with AR_JOB_TIMEOUT

# k8s job names: lowercase, alphanumeric + hyphens, max 63 chars
JOB_NAME=$(echo "ar-${EXPERIMENT_NAME}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | sed 's/-*$//' | head -c 63)

# Generate job YAML from template
TMPFILE=$(mktemp /tmp/ar-job-XXXXXX.yaml)
sed "s/JOB_NAME_PLACEHOLDER/$JOB_NAME/" "$SCRIPT_DIR/job-template.yaml" > "$TMPFILE"

# Clean up any previous job with same name
kubectl delete job "$JOB_NAME" --ignore-not-found=true 2>/dev/null

echo "Submitting job: $JOB_NAME"
kubectl apply -f "$TMPFILE"
rm -f "$TMPFILE"

echo "Waiting for job to complete (timeout: ${TIMEOUT}s)..."
START=$(date +%s)
while true; do
    STATUS=$(kubectl get job "$JOB_NAME" -o jsonpath='{.status.conditions[0].type}' 2>/dev/null || echo "Pending")
    ELAPSED=$(( $(date +%s) - START ))

    if [ "$STATUS" = "Complete" ]; then
        echo "Job completed in ${ELAPSED}s"
        kubectl delete job "$JOB_NAME" --ignore-not-found=true 2>/dev/null
        exit 0
    elif [ "$STATUS" = "Failed" ]; then
        echo "Job failed after ${ELAPSED}s"
        POD=$(kubectl get pods -l job-name="$JOB_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
        [ -n "$POD" ] && kubectl logs "$POD" --tail=50 2>/dev/null || true
        kubectl delete job "$JOB_NAME" --ignore-not-found=true 2>/dev/null
        exit 1
    elif [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "Job timed out after ${TIMEOUT}s"
        kubectl delete job "$JOB_NAME" --ignore-not-found=true 2>/dev/null
        exit 1
    fi

    sleep 10
done
