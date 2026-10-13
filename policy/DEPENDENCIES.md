# Dependency lock

The policy adapters run in the two environments shipped by the official
RoboSynChallenge repository. This avoids replacing simulator packages from a
second Python environment.

## Source revisions

| Component | Revision |
|---|---|
| RoboSynChallenge | `8818c82df5fa2522809b8105e7018950dcc9a9a8` |
| EmbodiChain | `89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd` |
| LeRobot used by PI0.5 | `0cf864870cf29f4738d3ade893e6fd13fbd7cdb5` |
| LeRobot used by ACT | `b883328e6c95681ca90a18b102e4ae5e1f91e2bf` |

## Runtime selection

- PI0.5 packages use `policy/pi05/.venv/bin/python` and the official
  `policy/pi05/uv.lock`.
- ACT packages use `policy/act/.venv/bin/python` and the official
  `policy/act/uv.lock`.
- `_shared/pi05-requirements.txt` and `_shared/act-requirements.txt` expose the
  direct runtime constraints inside the retained submission tree.

The PI0.5 checkpoints contain their normalization statistics under `ckpt/assets`
and parameters under `ckpt/params`. ACT checkpoints contain their LeRobot
configuration and model weights either directly under `ckpt/` or under
`ckpt/pretrained_model/`; the adapter supports both layouts.
