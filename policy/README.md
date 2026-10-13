# Policy tree

This directory is the complete artifact retained for official evaluation. Each task directory is an independently selectable policy package and contains `__init__.py`, `deploy_policy.py`, `deploy_policy.yml`, `eval.sh`, `requirements.txt`, and checkpoint metadata.

The `_shared/` directory contains the PI0.5 and ACT adapters, model transforms, inference timing, dependency manifests, and the common launcher.

## Installation

Copy this tree into the official RoboSynChallenge checkout:

```bash
cp -a Robosynchallengefirststage/policy/. RoboSynChallenge/policy/
cd RoboSynChallenge
GIT_LFS_SKIP_SMUDGE=1 uv sync
(cd policy/pi05 && GIT_LFS_SKIP_SMUDGE=1 uv sync)
(cd policy/act && GIT_LFS_SKIP_SMUDGE=1 uv sync)
```

The target revisions are RoboSynChallenge `8818c82df5fa2522809b8105e7018950dcc9a9a8` and EmbodiChain `89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd`. The complete dependency record is in [`DEPENDENCIES.md`](DEPENDENCIES.md).

## Evaluation

Pass the downloaded `ckpt/` directory to the matching task launcher:

```bash
bash policy/click_bell/eval.sh "$PWD/checkpoints/click_bell/ckpt"
```

Every configuration defaults to the official `random` evaluation, 100 valid episodes, the official expert feasibility check, and GPU 0. Official key/value overrides may follow the checkpoint path:

```bash
bash policy/click_bell/eval.sh \
  "$PWD/checkpoints/click_bell/ckpt" \
  --max_episodes 1
```
