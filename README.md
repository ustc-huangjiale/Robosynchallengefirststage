# RoboSynChallenge First Stage

第一阶段十个任务的模型适配器、评测配置与复现说明。

## 官方100回合结果

以下结果使用`random` setting、官方专家可行性预检、官方成功判据和100个有效回合。

| 任务 | 成功率 |
|---|---|---:|---:|
| Items Handover | 72% (72/100) |
| Table Rearrangement | 44% (44/100) |
| Mixer Operating | 83% (83/100) |
| Item Assembly | 78% (78/100) |
| Manipulate Pipette | 待补充 |
| Sample Loading| 待补充 |
| Click Bell| 96% (96/100)|
| Dual-Arm Water Pouring | 95% (95/100) |
| Basket Pick-and-Place | 待补充 |
| Drawer Open-and-Place | 待补充 |

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

## 测试

```bash
bash tasks/click_bell/eval.sh
bash tasks/click_bell/eval.sh --max_episodes 1
```

