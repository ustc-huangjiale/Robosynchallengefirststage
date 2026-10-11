# RoboSynChallenge First Stage

第一阶段十个任务的模型适配器、评测配置、模型下载与复现说明。GitHub 仓库不包含 checkpoint 大文件；每个任务对应一个独立 Hugging Face 模型仓库，权重统一位于仓库的 `ckpt/` 子目录。

## 评测结果

除特别注明外，结果使用 `random` setting、官方专家可行性预检、官方成功判据和 100 个有效回合。

| 任务 | 策略 | Checkpoint | 结果 |
|---|---|---:|---:|
| Items Handover | π0.5 | 39999 | 72/100 (72%) |
| Table Rearrangement | π0.5 | 70000 | 89/100 (89%) |
| Mixer Operating | ACT | 080000 | 83/100 (83%) |
| Item Assembly | ACT | 080000 | 78/100 (78%) |
| Manipulate Pipette | π0.5 | 2500 | 74/100 (74%) |
| Sample Loading | π0.5 | 4900 | 3/100 (3%) |
| Click Bell | π0.5 | 2000 | 96/100 (96%) |
| Dual-Arm Water Pouring | π0.5 | 2399 | 95/100 (95%) |
| Basket Pick-and-Place | π0.5 | 800 | 80/100 (80%) |
| Drawer Open-and-Place | π0.5 | 2999 | 90/100 (90%) |

## Hugging Face 模型命名

统一格式：`<namespace>/robosynchallenge-firststage-<policy>-<task>`。完整列表由 [`models.json`](models.json) 管理。

下载单个任务：

```bash
python scripts/download_checkpoint.py click_bell \
  --namespace ustc-huangjiale
```

下载全部任务：

```bash
python scripts/download_checkpoint.py --all \
  --namespace ustc-huangjiale
```

下载内容会写入 `tasks/<task>/checkpoint/`，不会加入 Git。

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

详细安装说明见 [`docs/INSTALL.md`](docs/INSTALL.md)，评测约定见 [`docs/EVALUATION.md`](docs/EVALUATION.md)。

## 官方测试命令

所有命令默认使用单卡 GPU0：

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

每个配置默认 100 回合、`random` setting、官方专家可行性预检、无视频。额外参数会作为官方 evaluator override 透传。正式复现请勿修改 setting、seed 流、成功判据或回合数。
