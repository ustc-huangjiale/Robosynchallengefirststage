# Official evaluation

Install the submitted `policy/` tree into the official RoboSynChallenge
checkout as described in [`INSTALL.md`](INSTALL.md). Each task is an independent
policy package named `firststage_<task>`.

For example:

```bash
cd RoboSynChallenge
hf download ustc-huangjiale/robosynchallenge-firststage-pi05-click-bell \
  --include 'ckpt/**' --local-dir checkpoints/click_bell
bash policy/firststage_click_bell/eval.sh \
  "$PWD/checkpoints/click_bell/ckpt"
```

The available packages are:

```text
firststage_items_handover
firststage_table_rearrangement
firststage_mixer_operating
firststage_item_assembly
firststage_manipulate_pipette
firststage_sample_loading
firststage_click_bell
firststage_water_pouring
firststage_handle_basket
firststage_drawer_open_place
```

Every configuration defaults to the `random` setting, 100 valid episodes, the
official expert feasibility pre-check, no video recording, and one physical GPU
(`GPU 0`, exposed to the policy as `cuda:0`). The tested chunk sizes, language
instructions, observation mappings, and model-side action transforms are fixed
in the corresponding `deploy_policy.yml` and shared adapter.

For a smoke test, append official key/value overrides after the checkpoint:

```bash
bash policy/firststage_click_bell/eval.sh \
  "$PWD/checkpoints/click_bell/ckpt" --max_episodes 1
```
