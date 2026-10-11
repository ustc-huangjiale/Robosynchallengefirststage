# RoboSynChallenge First Stage

第一阶段十个任务的模型适配器、官方评测配置与复现说明。本仓库不包含 checkpoint、数据集、RoboSynChallenge资源文件或第三方源码；checkpoint后续发布到Hugging Face。

## 官方100回合结果

以下结果使用`random` setting、官方专家可行性预检、官方成功判据和100个有效回合。“待补充”表示完整100回合结果尚未确认。

| 任务 | 策略 | step | 成功率 |
|---|---|---:|---:|
| Items Handover | π0.5 | 39999 | 72% (72/100) |
| Table Rearrangement | π0.5 | 70000 | 44% (44/100) |
| Mixer Operating | ACT | last | 83% (83/100) |
| Item Assembly | ACT | last | 78% (78/100) |
| Manipulate Pipette | π0.5 | 待最终选择 | 待补充 |
| Sample Loading | π0.5 | 4900 | 待补充 |
| Click Bell | π0.5 | 2000 | **96% (96/100)** |
| Dual-Arm Water Pouring | π0.5 | 2399 | **95% (95/100)** |
| Basket Pick-and-Place | π0.5 | 800 | 待补充 |
| Drawer Open-and-Place | π0.5 | 2999 | 待补充 |

## 结构

每个`tasks/<task>/`独立包含`eval.sh`、`deploy_policy.yml`、`deploy_policy.py`和空的`checkpoint/`。公共模型实现位于`submission/policy/`，避免十份相同代码发生漂移。

## 安装

```bash
git clone https://github.com/DexForce/EmbodiChain.git
git clone https://github.com/EDEM-AI/RoboSynChallenge.git
git clone https://github.com/ustc-huangjiale/Robosynchallengefirststage.git
cd RoboSynChallenge
git checkout 8818c82df5fa2522809b8105e7018950dcc9a9a8
uv sync
(cd policy/pi05 && uv sync)
(cd policy/act && uv sync)
export ROBOSYN_ROOT=/absolute/path/to/RoboSynChallenge
export EMBODICHAIN_ROOT=/absolute/path/to/EmbodiChain
cd ../Robosynchallengefirststage
bash scripts/setup_official.sh
```

固定官方提交在Manipulate Pipette专家预检中直接对CUDA tensor调用NumPy；setup脚本仅加入一行detach/cpu转换，不改变轨迹、seed或成功判据。

先按[EmbodiChain官方文档](https://dexforce.github.io/EmbodiChain/main/quick_start/install.html)安装模拟器与NVIDIA/Vulkan依赖。完整说明见[docs/INSTALL.md](docs/INSTALL.md)。

## Checkpoint

Git会忽略所有权重。将Hugging Face下载的完整checkpoint放入对应任务的`tasks/<task>/checkpoint/`。每个占位README会在上传后补充URL、revision和SHA256。

## 官方评测

所有任务固定使用物理 **GPU 0**，直接调用官方`$ROBOSYN_ROOT/scripts/eval_policy.py`；seed生成、专家可行性预检、环境最大步数和`is_task_success()`均由官方代码处理，本仓库不重写这些逻辑。

```bash
bash tasks/click_bell/eval.sh
bash tasks/click_bell/eval.sh --max_episodes 1
```

结果默认保存到`eval_results/<task>/`。全部命令见[docs/EVALUATION.md](docs/EVALUATION.md)。

GPU没有通过`CUDA_VISIBLE_DEVICES`逻辑重编号，避免CUDA与DexSim/Vulkan物理设备号不一致。官方evaluator接收`--gpu_id 0 --pytorch_device cuda:0`，JAX通过`PI05_JAX_VISIBLE_DEVICES=0`限定到GPU0。
