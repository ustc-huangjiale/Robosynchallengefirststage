# RoboSynChallenge First Stage

Model configurations, model downloads, and detailed specifications for the ten tasks in Phase 1. Each task corresponds to a dedicated Hugging Face model repository, with model weights consistently located in the repository's `ckpt/` subdirectory.

## Results

The results were obtained using the `random` setting, the official expert feasibility pre-check, the official success criteria, and 100 valid episodes.

| Task   | Result |
|---|---:|
| Items Handover  | 32/100 (32%) |
| Table Rearrangement  | 49/100 (49%) |
| Mixer Operating | 43/100 (43%) |
| Item Assembly  | 38/100 (38%) |
| Manipulate Pipette  | 34/100 (34%) |
| Sample Loading  | 3/100 (3%) |
| Click Bell | 56/100 (56%) |
| Dual-Arm Water Pouring  | 55/100 (55%) |
| Basket Pick-and-Place | 40/100 (40%) |
| Drawer Open-and-Place | 50/100 (50%) |

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

Downloaded content will be written to `tasks/<task>/checkpoint/`.

## Installation

```bash
curl -LsSf https://astral.sh/uv/0.13.0/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
git clone https://github.com/DexForce/EmbodiChain.git
git -C EmbodiChain checkout 89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd
git clone https://github.com/EDEM-AI/RoboSynChallenge.git
git clone https://github.com/ustc-huangjiale/Robosynchallengefirststage.git
cd RoboSynChallenge
git checkout 8818c82df5fa2522809b8105e7018950dcc9a9a8
export ROBOSYN_ROOT=/absolute/path/to/RoboSynChallenge
export EMBODICHAIN_ROOT=/absolute/path/to/EmbodiChain
cd ../Robosynchallengefirststage
bash scripts/setup_official.sh
python scripts/download_runtime_assets.py
cd "$ROBOSYN_ROOT"
GIT_LFS_SKIP_SMUDGE=1 uv sync
(cd policy/pi05 && GIT_LFS_SKIP_SMUDGE=1 uv sync)
(cd policy/act && GIT_LFS_SKIP_SMUDGE=1 uv sync)
```

For detailed installation instructions, see [`docs/INSTALL.md`](docs/INSTALL.md); for evaluation conventions, see [`docs/EVALUATION.md`](docs/EVALUATION.md).

## Inference

```bash
bash tasks/items_handover/eval.sh
bash tasks/table_rearrangement/eval.sh
bash tasks/mixer_operating/eval.sh
bash tasks/item_assembly/eval.sh
bash tasks/manipulate_pipette/eval.sh
bash tasks/sample_loading/eval.sh
bash tasks/click_bell/eval.sh
bash tasks/water_pouring/eval.sh
bash tasks/handle_basket/eval.sh
bash tasks/drawer_open_place/eval.sh
```

