# Submitted policy tree

This directory is the complete retained artifact for official evaluation. It is
self-contained with respect to submission code: no module under `policy/`
imports `submission/`, `tasks/`, or a repository-level helper script.

The organizer should overlay the contents of this directory onto the `policy/`
directory of the official RoboSynChallenge evaluation checkout. The official
simulator, task implementations, success predicates, evaluator, PI0.5 runtime,
and ACT runtime remain unchanged.

## Layout

- `_shared/`: the submitted PI0.5 and ACT adapters, the PI0.5 task transforms,
  inference timing, dependency manifests, and the common official-evaluator
  launcher.
- `firststage_<task>/`: one independently selectable policy package per task.
  Every package contains `__init__.py`, `deploy_policy.py`,
  `deploy_policy.yml`, `eval.sh`, `requirements.txt`, and checkpoint metadata.

## Installation into the official evaluator

The retained tree targets RoboSynChallenge commit
`8818c82df5fa2522809b8105e7018950dcc9a9a8` and EmbodiChain commit
`89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd`.

```bash
git clone https://github.com/EDEM-AI/RoboSynChallenge.git
git -C RoboSynChallenge checkout 8818c82df5fa2522809b8105e7018950dcc9a9a8
git clone https://github.com/DexForce/EmbodiChain.git
git -C EmbodiChain checkout 89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd
git clone https://github.com/ustc-huangjiale/Robosynchallengefirststage.git
cp -a Robosynchallengefirststage/policy/. RoboSynChallenge/policy/

cd RoboSynChallenge
GIT_LFS_SKIP_SMUDGE=1 uv sync
(cd policy/pi05 && GIT_LFS_SKIP_SMUDGE=1 uv sync)
(cd policy/act && GIT_LFS_SKIP_SMUDGE=1 uv sync)
```

The exact backend dependency sources and versions are recorded in
[`DEPENDENCIES.md`](DEPENDENCIES.md) and `_shared/*-requirements.txt`.

## Checkpoint placement and evaluation

Download the selected public Hugging Face model repository. Its model files are
under `ckpt/`. Pass that directory to the corresponding launcher:

```bash
hf download ustc-huangjiale/robosynchallenge-firststage-pi05-click-bell \
  --include 'ckpt/**' --local-dir checkpoints/click_bell

bash policy/firststage_click_bell/eval.sh \
  "$PWD/checkpoints/click_bell/ckpt"
```

Every launcher defaults to the official random evaluation, 100 valid episodes,
the official expert feasibility check, and a single GPU (`cuda:0`). Extra
official configuration overrides can follow the checkpoint path, for example:

```bash
bash policy/firststage_click_bell/eval.sh \
  "$PWD/checkpoints/click_bell/ckpt" --max_episodes 1
```

No checkpoint or simulator file is stored in this Git repository.
