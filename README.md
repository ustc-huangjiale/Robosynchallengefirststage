# RoboSynChallenge Policies

This repository provides complete policy packages for ten RoboSynChallenge tasks. The official evaluator retains only the [`policy/`](policy/) directory.

## Results and checkpoints

The reported results use the `random` setting, the official expert feasibility check, the official success criteria, and 100 valid episodes.

| Task | Policy | Step | Result | Checkpoint |
|---|---|---:|---:|---|
| Click Bell | `policy/click_bell` | 2000 | 96/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-pi05-click-bell) |
| Drawer Open-and-Place | `policy/drawer_open_place` | 2999 | 90/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-pi05-drawer-open-place) |
| Basket Pick-and-Place | `policy/handle_basket` | 800 | 80/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-pi05-handle-basket) |
| Item Assembly | `policy/item_assembly` | 080000 | 78/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-act-item-assembly) |
| Items Handover | `policy/items_handover` | 39999 | 72/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-pi05-items-handover) |
| Manipulate Pipette | `policy/manipulate_pipette` | 2500 | 74/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-pi05-manipulate-pipette) |
| Mixer Operating | `policy/mixer_operating` | 080000 | 83/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-act-mixer-operating) |
| Sample Loading | `policy/sample_loading` | 4900 | 3/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-pi05-sample-loading) |
| Table Rearrangement | `policy/table_rearrangement` | 60000 | 89/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-pi05-table-rearrangement) |
| Dual-Arm Water Pouring | `policy/water_pouring` | 2399 | 95/100 | [Hugging Face](https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-pi05-water-pouring) |

Model files are stored in the `ckpt/` directory of each Hugging Face repository and are not committed to GitHub.

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

Dependency revisions are listed in [`policy/DEPENDENCIES.md`](policy/DEPENDENCIES.md).

## Evaluation

Download the checkpoint into the official repository:

```bash
cd RoboSynChallenge
uvx --from huggingface_hub hf download \
  ustc-huangjiale/robosynchallenge-firststage-pi05-click-bell \
  --include 'ckpt/**' \
  --local-dir checkpoints/click_bell
```

Run the official 100-episode evaluation on GPU 0:

```bash
bash policy/click_bell/eval.sh "$PWD/checkpoints/click_bell/ckpt"
```

Run a one-episode smoke test:

```bash
bash policy/click_bell/eval.sh \
  "$PWD/checkpoints/click_bell/ckpt" \
  --max_episodes 1
```

For another task, use the corresponding policy directory and checkpoint repository from the table above.
