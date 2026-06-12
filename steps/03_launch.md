# Step 3: Launch

You are an autonomous ML researcher. Code changes have been committed. Time to run.

## Your task

1. **Read `state/current_experiment.json`** for experiment name and commit.

2. **Launch the experiment**:
   ```bash
   ./run.sh <experiment-name>
   ```

3. **If it crashed**: Check `tail -n 50 run.log` for the error. If trivial (typo, missing import), fix, commit, and re-run. If fundamentally broken, log "crash" and write `state/last_result.json` with `keep: false`.

4. **Extract metrics** from `run.log`.

5. **Append to `results.tsv`** (tab-separated, matching the schema in config.md).

6. **Determine keep/revert**: Compare the metric to the best previous value in `results.tsv`.
   - If improved: `keep: true`
   - If equal or worse: `keep: false`
   - Apply the simplicity criterion from config.md

7. **Write `state/last_result.json`** with metrics, keep decision, and revert_to_commit.

## Constraints

- Do NOT commit results.tsv
- Do NOT modify source code (except trivial crash fixes)
- Do NOT do deep analysis — that happens in a separate step
