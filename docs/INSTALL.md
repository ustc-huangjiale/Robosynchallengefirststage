# Installation

This repository is a lightweight submission overlay for the official RoboSynChallenge repository; it does not replace the official simulator code.

1. Install the complete NVIDIA driver, including Vulkan and `libnvoptix.so.1`, and Git LFS. Ensure that the evaluation user belongs to the `render` and `video` device groups. Install the verified `uv 0.13.0` release with the command below.
2. Clone EmbodiChain and pin it to the exact commit `89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd` used by the official `v0.2.4.post1` release. Do not use the moving `main` branch.
3. Clone RoboSynChallenge and pin it to commit `8818c82df5fa2522809b8105e7018950dcc9a9a8`.
4. Set `ROBOSYN_ROOT` and `EMBODICHAIN_ROOT`, then run `bash scripts/setup_official.sh` before installing dependencies. The script aligns PI0.5 with dexsim 0.4.3 as required by EmbodiChain, pins a pymeshlab build compatible with Ubuntu 20.04 and glibc 2.31, and lets DexSim establish the single-GPU CUDA context before Torch or JAX. It does not modify any success criteria.
5. Run `uv sync` in the RoboSynChallenge root, then run it separately in `policy/pi05` and `policy/act`.
6. Run `python scripts/download_runtime_assets.py` to download and verify the OpenPI PaliGemma tokenizer over HTTPS. This avoids a direct gcsfs connection to Google Storage during evaluation.
7. Download the models from Hugging Face into `tasks/<task>/checkpoint/`.

```bash
curl -LsSf https://astral.sh/uv/0.13.0/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
git clone https://github.com/DexForce/EmbodiChain.git
git -C EmbodiChain checkout 89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd
git clone https://github.com/EDEM-AI/RoboSynChallenge.git
git -C RoboSynChallenge checkout 8818c82df5fa2522809b8105e7018950dcc9a9a8
git clone https://github.com/ustc-huangjiale/Robosynchallengefirststage.git
export ROBOSYN_ROOT=/absolute/path/to/RoboSynChallenge
export EMBODICHAIN_ROOT=/absolute/path/to/EmbodiChain
cd Robosynchallengefirststage
bash scripts/setup_official.sh
python scripts/download_runtime_assets.py
cd "$ROBOSYN_ROOT"
GIT_LFS_SKIP_SMUDGE=1 uv sync
(cd policy/pi05 && GIT_LFS_SKIP_SMUDGE=1 uv sync)
(cd policy/act && GIT_LFS_SKIP_SMUDGE=1 uv sync)
cd /absolute/path/to/Robosynchallengefirststage
uv run --python 3.11 --with huggingface_hub python scripts/download_checkpoint.py click_bell --namespace ustc-huangjiale
bash tasks/click_bell/eval.sh --max_episodes 1
```

Evaluation uses physical GPU 0 by default. Checkpoints must not be committed to GitHub.
