# Installation

本仓库是官方 RoboSynChallenge 的轻量 submission overlay，不替代官方模拟器代码。

1. 安装 NVIDIA 驱动、Vulkan、Git LFS、`uv` 和 Python 包 `huggingface_hub`。
2. 克隆 EmbodiChain；Sample Loading 的已验证环境为 `0.2.4.post1`，其他任务按官方环境安装。
3. 克隆 RoboSynChallenge 并固定到 `8818c82df5fa2522809b8105e7018950dcc9a9a8`。
4. 在 RoboSynChallenge 根目录运行 `uv sync`，并分别在 `policy/pi05` 和 `policy/act` 运行 `uv sync`。
5. 设置 `ROBOSYN_ROOT` 和 `EMBODICHAIN_ROOT` 绝对路径。
6. 运行 `bash scripts/setup_official.sh`：应用 Pipette CUDA/NumPy 兼容修复、对齐该 checkpoint 的训练语言指令，并取消专家可行 seed 的每回合 100 次上限。
7. 从 Hugging Face 下载模型到 `tasks/<task>/checkpoint/`。

```bash
python -m pip install huggingface_hub
export ROBOSYN_ROOT=/absolute/path/to/RoboSynChallenge
export EMBODICHAIN_ROOT=/absolute/path/to/EmbodiChain
bash scripts/setup_official.sh
python scripts/download_checkpoint.py click_bell --namespace ustc-huangjiale
bash tasks/click_bell/eval.sh --max_episodes 1
```

评测固定使用物理 GPU0。checkpoint 不应提交到 GitHub。
