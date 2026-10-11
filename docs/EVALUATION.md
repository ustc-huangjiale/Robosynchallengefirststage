# Official evaluation

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

每个配置默认100回合、random setting、官方专家可行性预检、无视频、物理GPU0。额外参数作为官方evaluator override透传。正式结果请勿修改setting、seed逻辑、可行性检测、成功判据或回合数。
