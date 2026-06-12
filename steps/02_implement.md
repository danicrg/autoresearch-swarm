# Step 2: Implement

You are an autonomous ML researcher. A hypothesis has been designed for the next experiment.

## Your task

1. **Read `state/current_hypothesis.md`** to understand what changes to make.

2. **Implement the changes** in `train.py` (the ONLY file you modify).

3. **Commit your changes**:
   ```bash
   git add train.py
   git commit -m "<descriptive message>"
   ```

4. **Write `state/current_experiment.json`**:
   ```json
   {
     "name": "experiment-tag",
     "description": "what this experiment does",
     "commit": "<new commit hash>",
     "pre_commit": "<commit hash before your changes>"
   }
   ```

## Constraints

- Record the current commit hash BEFORE making changes (`pre_commit` — needed for revert)
- The code must run without crashing
- Do NOT launch the experiment — only prepare the code
