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

Each configuration defaults to 100 episodes, the `random` setting, the official expert feasibility pre-check, no video recording, and physical GPU 0. If GPU 0 is occupied, select another physical GPU with `ROBOSYN_GPU_ID=3 bash tasks/<task>/eval.sh`. If lower-numbered GPUs are fully occupied and Warp device enumeration fails, additionally set `ROBOSYN_CUDA_VISIBLE_DEVICES` while ensuring that the target physical GPU retains the same logical index as `ROBOSYN_GPU_ID` within that list (for example, use `ROBOSYN_CUDA_VISIBLE_DEVICES=3,6,2 ROBOSYN_GPU_ID=2` for physical GPU 2). The simulator, PyTorch, and JAX still allocate memory only on the target GPU. Additional arguments are passed through as official evaluator overrides. For official results, do not change the setting, seed logic, feasibility check, success criteria, or episode count.
