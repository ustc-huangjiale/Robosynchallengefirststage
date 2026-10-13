# RoboSynChallenge First Stage

Model configurations, model downloads, and complete retained policy packages for the ten tasks in Phase 1. Each task corresponds to a dedicated Hugging Face model repository, with model weights consistently located in the repository's `ckpt/` subdirectory.

The submission artifact is the complete [`policy/`](policy/) tree. It contains the adapters, model-side transforms, dependency manifests, `eval.sh`, `deploy_policy.py`, and `deploy_policy.yml` required after the organizer discards every other repository directory.

## Results

The results were obtained using the `random` setting, the official expert feasibility pre-check, the official success criteria, and 100 valid episodes.

| Task   | Result |
|---|---:|
| Items Handover  | 72/100 (72%) |
| Table Rearrangement  | 89/100 (89%) |
| Mixer Operating | 83/100 (83%) |
| Item Assembly  | 78/100 (78%) |
| Manipulate Pipette  | 74/100 (74%) |
| Sample Loading  | 3/100 (3%) |
| Click Bell | 96/100 (96%) |
| Dual-Arm Water Pouring  | 95/100 (95%) |
| Basket Pick-and-Place | 80/100 (80%) |
| Drawer Open-and-Place | 90/100 (90%) |

## Hugging Face checkpoints

Standardized format: `<namespace>/robosynchallenge-firststage-<policy>-<task>`. The complete list is managed in [`models.json`](models.json).

Download a checkpoint for a single task:

```bash
uv run --python 3.11 --with huggingface_hub python scripts/download_checkpoint.py click_bell \
  --namespace ustc-huangjiale
```

Download checkpoints for all tasks:

```bash
uv run --python 3.11 --with huggingface_hub python scripts/download_checkpoint.py --all \
  --namespace ustc-huangjiale
```

For local legacy launchers, downloaded content is written to `tasks/<task>/checkpoint/`. For the retained official submission flow, download a model directly and pass its `ckpt/` directory to `policy/firststage_<task>/eval.sh` as shown below.

## Installation

```bash
curl -LsSf https://astral.sh/uv/0.13.0/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
git clone https://github.com/DexForce/EmbodiChain.git
git -C EmbodiChain checkout 89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd
git clone https://github.com/EDEM-AI/RoboSynChallenge.git
git -C RoboSynChallenge checkout 8818c82df5fa2522809b8105e7018950dcc9a9a8
git clone https://github.com/ustc-huangjiale/Robosynchallengefirststage.git
cp -a Robosynchallengefirststage/policy/. RoboSynChallenge/policy/
cd RoboSynChallenge
GIT_LFS_SKIP_SMUDGE=1 uv sync
(cd policy/pi05 && GIT_LFS_SKIP_SMUDGE=1 uv sync)
(cd policy/act && GIT_LFS_SKIP_SMUDGE=1 uv sync)
```

For the exact retained-tree contract and dependency revisions, see [`policy/README.md`](policy/README.md) and [`policy/DEPENDENCIES.md`](policy/DEPENDENCIES.md).

## Inference

```bash
hf download ustc-huangjiale/robosynchallenge-firststage-pi05-click-bell \
  --include 'ckpt/**' --local-dir checkpoints/click_bell
bash policy/firststage_click_bell/eval.sh "$PWD/checkpoints/click_bell/ckpt"
```

Replace `click_bell` with the selected task. See [`policy/README.md`](policy/README.md) for the retained-tree installation contract and all evaluation details.
