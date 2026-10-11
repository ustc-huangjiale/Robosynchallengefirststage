#!/usr/bin/env python3
"""Validate the ten-task publication manifest and lightweight repository layout."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
models = json.loads((ROOT / "models.json").read_text())["models"]
assert len(models) == 10, f"expected 10 models, got {len(models)}"
assert len({m["task"] for m in models}) == 10, "duplicate task"
assert len({m["repo"] for m in models}) == 10, "duplicate Hugging Face repository name"
for model in models:
    task_dir = ROOT / "tasks" / model["task"]
    assert task_dir.is_dir(), task_dir
    for required in ("eval.sh", "deploy_policy.py", "deploy_policy.yml", "checkpoint/README.md"):
        assert (task_dir / required).is_file(), f"missing {task_dir / required}"
for path in ROOT.rglob("*"):
    if path.is_file() and path.stat().st_size > 10 * 1024 * 1024:
        raise AssertionError(f"large file must not be committed: {path}")
print("validated 10 task entries; no repository file exceeds 10 MiB")
