#!/bin/bash
# orchestrator.sh — Multi-agent autonomous experiment loop
# Supports local execution and k8s backends
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND="${AR_BACKEND:-local}"  # "local" or "k8s"
AGENT_CMD="${AR_AGENT_CMD:-claude}"  # agent CLI command (e.g. "claude", "aider", etc.)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$DIR/orchestrator.log"; }

# --- Backend abstraction ---
if [ "$BACKEND" = "k8s" ]; then
    WORKSPACE_POD="${AR_WORKSPACE_POD:-ar-workspace}"
    REMOTE_DIR="${AR_REMOTE_DIR:-/workspace/autoresearch-swarm}"
    run_cmd() { kubectl exec "$WORKSPACE_POD" -- bash -c "cd $REMOTE_DIR && $*"; }

    if ! kubectl get pod "$WORKSPACE_POD" -o jsonpath='{.status.phase}' 2>/dev/null | grep -q Running; then
        echo "ERROR: Workspace pod '$WORKSPACE_POD' is not running."
        echo "Run: kubectl apply -f k8s/workspace-pod.yaml"
        exit 1
    fi
else
    run_cmd() { bash -c "cd $DIR && $*"; }
fi

# --- Resumability ---
determine_start_step() {
    local has_experiment has_result has_hypothesis
    has_experiment=$(run_cmd "test -f state/current_experiment.json && echo yes || echo no")
    has_result=$(run_cmd "test -f state/last_result.json && echo yes || echo no")
    has_hypothesis=$(run_cmd "test -f state/current_hypothesis.md && echo yes || echo no")

    if [ "$has_experiment" = "yes" ] && [ "$has_result" = "no" ]; then
        echo "launch"
    elif [ "$has_hypothesis" = "yes" ] && [ "$has_experiment" = "no" ]; then
        echo "implement"
    else
        echo "analyze"
    fi
}

ITERATION=$(run_cmd "ls -d logs/iter-* 2>/dev/null | sed 's/.*iter-//' | sort -n | tail -1 || echo 0")
ITERATION=${ITERATION:-0}

START_STEP=$(determine_start_step)
[ "$START_STEP" != "analyze" ] && log "Resuming from step: $START_STEP (iteration $ITERATION)"

run_step() {
    local step_file="$1" prompt="$2" step_name="$3"
    run_cmd "mkdir -p logs/iter-$ITERATION"
    log "Running step: $step_name (iter $ITERATION)"

    cd "$DIR"
    $AGENT_CMD --print -p "$(cat steps/$step_file)" \
        > "$DIR/logs-local/iter-${ITERATION}-${step_name}.log" 2>&1
    local exit_code=$?
    log "Step $step_name finished (exit=$exit_code)"
    return $exit_code
}

mkdir -p "$DIR/logs-local"

while true; do
    ITERATION=$((ITERATION + 1))
    log "=== Iteration $ITERATION ==="
    run_cmd "mkdir -p logs/iter-$ITERATION state"

    # Step 1: Analyze + Design
    if [ "$START_STEP" = "analyze" ]; then
        run_cmd "rm -f state/current_hypothesis.md state/current_experiment.json state/last_result.json"
        run_step "01_analyze.md" \
            "Run the analyze+design step. Read all previous experiment learnings from logs/iter-*/learnings.md and results.tsv. Analyze trends and design the next experiment. Write state/current_hypothesis.md." \
            "01-analyze"
        run_cmd "cp state/current_hypothesis.md logs/iter-$ITERATION/hypothesis.md 2>/dev/null || true"
    fi

    # Step 2: Implement
    if [ "$START_STEP" = "analyze" ] || [ "$START_STEP" = "implement" ]; then
        run_step "02_implement.md" \
            "Run the implement step. Read state/current_hypothesis.md and make the planned changes to train.py. Commit and write state/current_experiment.json." \
            "02-implement"
        run_cmd "cp state/current_experiment.json logs/iter-$ITERATION/experiment.json 2>/dev/null || true"
    fi

    # Step 3: Launch + Extract Metrics
    run_step "03_launch.md" \
        "Run the launch step. Launch the experiment, extract metrics, append to results.tsv, and write state/last_result.json." \
        "03-launch"
    run_cmd "cp state/last_result.json logs/iter-$ITERATION/result.json 2>/dev/null || true"

    # Step 4: Generate Learnings
    run_step "04_learnings.md" \
        "Run the learnings step. Read state/last_result.json and run.log. Do deep analysis of training dynamics. Write learnings to logs/iter-$ITERATION/learnings.md." \
        "04-learnings"

    START_STEP="analyze"

    # Tag experiment
    EXPERIMENT_NAME=$(run_cmd "python3 -c \"import json; print(json.load(open('state/current_experiment.json'))['name'])\"" 2>/dev/null || echo "iter-$ITERATION")
    run_cmd "git tag autoresearch/$EXPERIMENT_NAME 2>/dev/null || true"

    # Revert logic
    KEEP=$(run_cmd "python3 -c \"import json; print(json.load(open('state/last_result.json'))['keep'])\"" 2>/dev/null || echo "true")
    if [ "$KEEP" = "False" ] || [ "$KEEP" = "false" ]; then
        REVERT_TO=$(run_cmd "python3 -c \"import json; print(json.load(open('state/last_result.json'))['revert_to_commit'])\"")
        log "Experiment did not improve. Reverting to $REVERT_TO"
        run_cmd "git checkout $REVERT_TO -- train.py && git commit -m 'revert: discard experiment, restore train.py to $REVERT_TO'"
    else
        log "Experiment improved! Keeping changes."
    fi

    log "=== Iteration $ITERATION complete ==="

    [ "${ONCE:-}" = "1" ] && { log "Single iteration mode. Stopping."; break; }
done
