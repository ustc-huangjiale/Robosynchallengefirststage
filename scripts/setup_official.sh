#!/usr/bin/env bash
set -euo pipefail
repo="${ROBOSYN_ROOT:?set ROBOSYN_ROOT to the official RoboSynChallenge checkout}"
expected=8818c82df5fa2522809b8105e7018950dcc9a9a8
actual="$(git -C "$repo" rev-parse HEAD)"
[[ "$actual" == "$expected" ]] || { echo "expected official commit $expected, got $actual" >&2; exit 2; }
target="$repo/robosynchallenge/tasks/manipulate_pipette/action_bank.py"
python3 - "$target" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
source = path.read_text()
old = "return ret.positions[0].numpy().T"
new = "return ret.positions[0].detach().cpu().numpy().T"
if new in source:
    print("compatibility fix already present")
elif source.count(old) == 1:
    path.write_text(source.replace(old, new))
    print("applied minimal CUDA tensor-to-NumPy compatibility fix")
else:
    raise SystemExit("official source differs; refusing to modify it")
PY
