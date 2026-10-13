# Installation

The organizer retains only this repository's `policy/` directory and supplies
the official RoboSynChallenge evaluation code. Do not replace the official
simulator, evaluator, task implementations, or success predicates.

The submitted policies target these source revisions:

- RoboSynChallenge: `8818c82df5fa2522809b8105e7018950dcc9a9a8`
- EmbodiChain: `89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd`

Install the retained tree as an overlay and use the official locked PI0.5 and
ACT environments:

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

The submitted adapters select `policy/pi05/.venv/bin/python` or
`policy/act/.venv/bin/python` automatically. Direct dependency constraints and
source revisions are recorded in
[`policy/DEPENDENCIES.md`](../policy/DEPENDENCIES.md).

Checkpoints are intentionally excluded from Git. Download a model's public
Hugging Face repository and pass its `ckpt/` directory to the selected policy's
`eval.sh`.
