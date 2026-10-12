# Installation

本仓库是官方 RoboSynChallenge 的轻量 submission overlay，不替代官方模拟器代码。

1. 安装 NVIDIA 驱动、Vulkan 和 Git LFS；使用下方命令安装已验证的 `uv 0.13.0` 和 Python 包 `huggingface_hub`。
2. 克隆 EmbodiChain 并固定到官方 `v0.2.4.post1` 的精确提交 `89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd`。不要使用随时间变化的 `main`。
3. 克隆 RoboSynChallenge 并固定到 `8818c82df5fa2522809b8105e7018950dcc9a9a8`。
4. 设置 `ROBOSYN_ROOT` 和 `EMBODICHAIN_ROOT`，然后在安装依赖前运行 `bash scripts/setup_official.sh`。脚本会将 PI0.5 对齐到 EmbodiChain 所需的 dexsim 0.4.3、固定兼容 Ubuntu 20.04/glibc 2.31 的 pymeshlab，并让 DexSim 先于 Torch/JAX 建立单卡 CUDA context；成功判据不会被修改。
5. 在 RoboSynChallenge 根目录运行 `uv sync`，并分别在 `policy/pi05` 和 `policy/act` 运行 `uv sync`。
6. 从 Hugging Face 下载模型到 `tasks/<task>/checkpoint/`。

```bash
curl -LsSf https://astral.sh/uv/0.13.0/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
python -m pip install huggingface_hub
git clone https://github.com/DexForce/EmbodiChain.git
git -C EmbodiChain checkout 89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd
git clone https://github.com/EDEM-AI/RoboSynChallenge.git
git -C RoboSynChallenge checkout 8818c82df5fa2522809b8105e7018950dcc9a9a8
git clone https://github.com/ustc-huangjiale/Robosynchallengefirststage.git
export ROBOSYN_ROOT=/absolute/path/to/RoboSynChallenge
export EMBODICHAIN_ROOT=/absolute/path/to/EmbodiChain
cd Robosynchallengefirststage
bash scripts/setup_official.sh
cd "$ROBOSYN_ROOT"
GIT_LFS_SKIP_SMUDGE=1 uv sync
(cd policy/pi05 && GIT_LFS_SKIP_SMUDGE=1 uv sync)
(cd policy/act && GIT_LFS_SKIP_SMUDGE=1 uv sync)
cd /absolute/path/to/Robosynchallengefirststage
python scripts/download_checkpoint.py click_bell --namespace ustc-huangjiale
bash tasks/click_bell/eval.sh --max_episodes 1
```

评测固定使用物理 GPU0。checkpoint 不应提交到 GitHub。
