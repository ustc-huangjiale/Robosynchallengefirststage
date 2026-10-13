#!/usr/bin/env python3
"""Validate the ten-task publication manifest and retained policy tree."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
models = json.loads((ROOT / "models.json").read_text())["models"]
assert len(models) == 10, f"expected 10 models, got {len(models)}"
assert len({m["task"] for m in models}) == 10, "duplicate task"
assert len({m["repo"] for m in models}) == 10, (
    "duplicate Hugging Face repository name"
)

policy_root = ROOT / "policy"
assert policy_root.is_dir(), "missing retained policy/ tree"
for path in policy_root.rglob("*"):
    assert not path.is_symlink(), (
        f"retained policy tree contains a symlink: {path}"
    )

for model in models:
    task_dir = ROOT / "tasks" / model["task"]
    assert task_dir.is_dir(), task_dir
    for required in (
        "eval.sh",
        "deploy_policy.py",
        "deploy_policy.yml",
        "checkpoint/README.md",
    ):
        assert (task_dir / required).is_file(), f"missing {task_dir / required}"

    package_name = f"firststage_{model['task']}"
    package_dir = policy_root / package_name
    assert package_dir.is_dir(), f"missing {package_dir}"
    for required in (
        "__init__.py",
        "deploy_policy.py",
        "deploy_policy.yml",
        "eval.sh",
        "requirements.txt",
        "CHECKPOINT.md",
    ):
        assert (package_dir / required).is_file(), (
            f"missing {package_dir / required}"
        )

    config = (package_dir / "deploy_policy.yml").read_text()
    assert f"policy_name: {package_name}\n" in config
    assert f"task_name: {model['task']}\n" in config
    checkpoint_doc = (package_dir / "CHECKPOINT.md").read_text()
    assert model["repo"] in checkpoint_doc
    assert str(model["step"]) in checkpoint_doc

for required in (
    "_shared/pi05_adapter.py",
    "_shared/pi05_model.py",
    "_shared/act_adapter.py",
    "_shared/inference_timing.py",
    "_shared/run_eval.sh",
    "_shared/pi05-requirements.txt",
    "_shared/act-requirements.txt",
    "README.md",
    "DEPENDENCIES.md",
):
    assert (policy_root / required).is_file(), f"missing policy/{required}"

for path in policy_root.rglob("*"):
    if not path.is_file() or "__pycache__" in path.parts:
        continue
    if path.suffix in {".py", ".sh", ".yml", ".yaml", ".txt", ".md"}:
        source = path.read_text()
        assert "submission." not in source, (
            f"external submission import in {path}"
        )

for path in ROOT.rglob("*"):
    if path.is_file() and path.stat().st_size > 10 * 1024 * 1024:
        raise AssertionError(f"large file must not be committed: {path}")

print("validated 10 task entries and standalone retained policy tree")
