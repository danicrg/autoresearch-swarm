# Step 1: Analyze Previous Experiments + Design Next Experiment

You are an autonomous ML researcher optimizing a training setup via iterative experimentation.

## Your task

1. **Analyze all previous experiments** by reading:
   - `results.tsv` — the full experiment history with metrics
   - All `learnings.md` files from previous iterations under `logs/iter-*/learnings.md`
   - The current `train.py` to understand the code state

2. **Identify patterns**:
   - Which changes improved the metric? By how much?
   - What strategies have worked? What hasn't?
   - Are there diminishing returns on current approaches?
   - What hasn't been tried yet?

3. **Read `train.py`** carefully to understand what levers are available.

4. **Design the next experiment**:
   - Formulate a clear hypothesis
   - Describe the specific changes
   - Predict the expected impact
   - Give the experiment a short descriptive name

## Output

Write your analysis and experiment design to `state/current_hypothesis.md`.

Be bold but grounded. If many incremental approaches have been tried, consider radical changes. If a radical change just failed, try a refined version.

Do NOT make any code changes in this step. Only analyze and plan.
