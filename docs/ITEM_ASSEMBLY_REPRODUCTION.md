# Item Assembly reproduction investigation — 2026-10-12

The initial reproduction achieved **49/100**, compared with the historical **78/100**. The historical total is supported by episode logs, but the two runs used different environment and expert-planning workflows. We have not established a single cause for the 29-point difference.

## Historical result verified

The historical source is `eval_colleague_act_official100_ownenv` on the original evaluation server. Reconstructing completed episodes gives:

| Source | Episodes | Successes |
|---|---:|---:|
| `item_assembly.log` | 1–96 | 75 |
| `item_ep97_retry_seed1937714069.log` | 97 | 1 |
| `item_ep98_100_resume_offset148.log` | 98–100 | 2 |
| Total | 100 | 78 |

The main log ends during episode 97. The resumed run uses seed 1937714069 for that episode; episodes 98–100 use seeds 1027629257, 85846399 and 168310272. Reconstructed mean action steps are 309.60, matching `FINAL_OFFICIAL100_SUMMARY.json`. The separate `item_assembly_old361.log` is an abandoned 361-step run and is excluded.

The summary identifies ACT checkpoint `080000`; the logged `last` symlink currently resolves to that checkpoint. The downloaded checkpoint configuration is identical to the historical configuration. The original weight file is not readable by the account used for this audit, so byte-for-byte weight equivalence remains unverified. The local published weight SHA-256 is `0b843b467fe70bab69658ff1b4eb03844f021e4e43190a1e95822384670db317`.

## What differs

| Item | Historical run | Initial reproduction |
|---|---|---|
| Successes | 78/100 | 49/100 |
| Effective action limit | 500 | 500 |
| ACT predicted/executed chunk | 50 / 50 | 50 / 50 |
| Adapter call limit | 10 | 10 |
| Observation | Three RGB cameras and 14 joint positions; no text input | Same |
| Expert plan length in logs | 272 | 318 |
| Candidate seeds to accept 100 | 151 | 131 |
| Post-precheck reset | Reuse expert scene and cached reset observation | Reset again before policy rollout |
| Environment construction seed | Log: no seed set | Seed 0 |
| EmbodiChain checkout found during audit | `99999b7e9b073778ad1d29eed570a46c61cdbccd`, with local patches | `89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd` |
| GPU | RTX 3090 | RTX 4090 |

The retrieved historical workspace has local modifications; its Git HEAD alone is not a description of the evaluated code. The evaluator file was modified after the historical run. Its cached-observation behavior is also corroborated by the historical log: the first accepted episode starts policy actions after the feasibility check without a second reset, and retains the expert attachment schedule at step 237.

The historical `action_config.json` differs substantially from the pinned official configuration. The old `L_splice_to_align` schedule is present in historical logs; current runs report that this edge is missing. This changes feasibility filtering and potentially the state carried from expert planning. Expert planned actions are not executed as policy actions.

EmbodiChain commit `89c14da8` adds per-event seed derivation and scoped random states. Consequently, using the same top-level seed does not reconstruct the same visual and physical scene across these versions. Only 66 accepted seeds overlap. Among them:

| Historical → current | Count |
|---|---:|
| Success → success | 25 |
| Success → failure | 25 |
| Failure → success | 6 |
| Failure → failure | 10 |

This rules out explaining the whole gap solely by the 34 non-overlapping accepted seeds. It does not isolate randomization from other runtime differences.

## Success criteria and observed failures

The task implementation retrieved from the historical server is byte-identical to the current official Item Assembly implementation (SHA-256 `9c5ace8eb0a3680db73027d7d2548cc1316298becd61ccf86a588b2509ed382a`). The retrieved random gym configuration is also identical and its modification time precedes the historical main run (2026-10-08 17:42). An earlier comparison against an unrelated old checkout on the reproduction server found an obsolete angle-only criterion; that checkout was not evidence for the 78% run and must not be used to explain this result.

With the configured contact sensor, current success requires valid poses, at least five steps, X-axis angle at most 15 degrees, inter-object contact distance at most 3 mm, and lateral offset at most 20 mm. We have not loosened these criteria.

In the initial 100 episodes, all 51 failures reached the 500-step limit. The 49 successes took 258–281 steps (mean 270.73). Logs show no attachment in 47 failures and attachment without final success in four failures. All successful episodes also used the logged fallback for rigid-constraint creation, so that warning by itself does not explain the lower score.

A separate four-episode diagnostic reproduced the initial success/failure sequence (failure, failure, failure, success). For seed 209652396, at step 265 the measured angle was 8.38 degrees and contact distance 1.41 mm, but lateral offset was 20.65 mm: contact and angle passed while lateral alignment failed. Later sampled states did not recover. These traces locate a failure mode; they do not explain all 51 failures or prove that increasing the step limit would help.

## Controlled diagnostic runs

These runs use the same local published weight and the current simulator on physical GPU 6. The diagnostic adapter call limit is 50 (the initial run used 10); the persistent ACT queue still executes 50 predicted actions before a new inference. Four valid episodes per condition are too few to estimate benchmark success. The accepted seed sets differ, so the rows are not a paired four-seed comparison.

- `reuse_current_plan`: skip the post-precheck reset, preserve its cached observation, and bypass the reset synchronization step, as in the historical reuse path. Result: **0/4**, with the first four accepted seeds matching the initial run. Removing the second reset alone did not restore the historical outcome.
- `reuse_history_plan`: additionally load the historical expert `action_config.json`. Result: **3/4**. Seed 398764591 succeeds in 271 steps, whereas it fails with the current expert plan. The first seed 209652396 now fails the feasibility precheck and is skipped, unlike the historical run.
- `reuse_history_plan_legacy_rng`: additionally bypass the new event-specific RNG scopes, leaving the process-global RNG behavior. This is an isolated diagnostic, not a complete historical environment reconstruction. Result: **3/4**. Seed 209652396 is accepted again and succeeds in 263 steps; seed 441365315 still fails despite succeeding historically. [Diagnostic episode records](results/item_assembly_diagnostics.json) retain all three conditions.

The comparison supports environment randomization, expert feasibility selection, and preserved expert state as material factors. It does not establish their individual contributions to the 29-point aggregate gap. We retain the pinned official evaluation protocol for benchmark results.

## Evidence and limits

[Episode records and source-log hashes](results/item_assembly_history_comparison.json) preserve both 100-episode sequences. [Initial ten-task results](results/reproduction_20261012.json) record the original settings and metrics; later configuration changes and reruns are excluded.

The main unresolved comparison is the historical environment/randomization and reset workflow versus the pinned official workflow. Hardware, runtime patches, assets and unreadable historical weight bytes remain potential confounders. Short diagnostic runs are not replacement benchmark results.
