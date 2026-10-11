# Installation

本仓库是官方RoboSynChallenge的轻量submission overlay，不替代官方模拟器代码。

1. 安装NVIDIA驱动、Vulkan、Git LFS和uv。
2. 按EmbodiChain官方文档安装EmbodiChain。
3. 克隆RoboSynChallenge并固定到已验证提交`8818c82df5fa2522809b8105e7018950dcc9a9a8`。
4. 在RoboSynChallenge根目录运行`uv sync`，并分别在`policy/pi05`和`policy/act`运行`uv sync`。
5. 设置`ROBOSYN_ROOT`和`EMBODICHAIN_ROOT`绝对路径。
6. 运行`bash scripts/setup_official.sh`应用固定官方提交所需的一行CUDA/NumPy兼容补丁。\n7. 将各模型权重放入本仓库`tasks/<task>/checkpoint/`。

```bash
test -f "$ROBOSYN_ROOT/scripts/eval_policy.py"
test -d "$EMBODICHAIN_ROOT/embodichain"
nvidia-smi -i 0
bash tasks/click_bell/eval.sh --max_episodes 1
```
