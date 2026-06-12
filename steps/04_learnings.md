# Step 4: Learnings

You are an autonomous ML researcher. An experiment has been run and metrics extracted. Time for deep analysis.

## Your task

1. **Read `state/last_result.json`** to get the experiment metrics and keep decision.

2. **Read `run.log`** for the full training output — look at loss curves, throughput, training dynamics.

3. **Deep analysis** — do NOT just report numbers:
   - How did the loss curve behave? Fast initial drop? Plateau? Instability?
   - Was throughput reasonable? Did the change affect it?
   - How does this compare to the best previous result?
   - WHY did this change help or hurt? Reason about the mechanism.

4. **Write learnings** to `logs/iter-N/learnings.md`:
   - What worked and what didn't
   - Training dynamics observations
   - Hypotheses for why the result was what it was
   - Concrete suggestions for next experiments

## Constraints

- Do NOT modify source code
- Do NOT modify results.tsv or state files
- This step is purely analytical
