# Autoresearch-Scalable Configuration

## Execution backend

### Local mode (default)
Files live in the current directory. Commands run directly.

### Kubernetes mode
Set `AR_BACKEND=k8s`. Files live on a workspace pod.
```bash
kubectl exec ar-workspace -- bash -c "cd /workspace/autoresearch-swarm && <command>"
```

## In-scope source files

- `train.py` — model architecture, optimizer, training loop. **This is the only file the agent edits.**
- `prepare.py` — fixed constants, data prep, tokenizer, dataloader, evaluation. **Do not modify.**

## Experiment launch

### Local mode
```bash
./run.sh <experiment-name>
```

### Kubernetes mode
```bash
kubectl exec ar-workspace -- bash -c "cd /workspace/autoresearch-swarm && ./k8s/submit-job.sh <experiment-name>"
```

Training runs for a fixed 5-minute time budget (wall clock, excluding startup/compilation).

## Metric

`val_bpb` (validation bits per byte) — lower is better, vocab-size-independent.

## Results TSV schema

File: `results.tsv` (tab-separated, NOT comma-separated)

```
commit	val_bpb	memory_gb	status	description
```

- commit: git short hash (7 chars)
- val_bpb: achieved metric (0.000000 for crashes)
- memory_gb: peak VRAM in GB, round to .1f (0.0 for crashes)
- status: `keep`, `discard`, or `crash`
- description: short text of what was tried

## State file schemas

### state/current_hypothesis.md

Free-form markdown with:
- Hypothesis: what you expect to happen and why
- Planned changes: specific code modifications
- Expected impact: predicted metric change direction and magnitude
- Experiment name: short tag

### state/current_experiment.json

```json
{
  "name": "experiment-tag",
  "description": "what this experiment does",
  "commit": "abc1234",
  "pre_commit": "def5678"
}
```

### state/last_result.json

```json
{
  "name": "experiment-tag",
  "keep": true,
  "revert_to_commit": "def5678",
  "val_bpb": 0.997900,
  "memory_gb": 44.0,
  "best_previous_bpb": 0.999000
}
```

## Simplicity criterion

All else being equal, simpler is better. A small improvement that adds ugly complexity is not worth it. Removing something and getting equal or better results is a great outcome.

## Goal

Minimize `val_bpb`. The only constraint is that the code runs without crashing and finishes within the time budget.
