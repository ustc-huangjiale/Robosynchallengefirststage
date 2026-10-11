#!/usr/bin/env python3
"""Download one or all published task checkpoints from Hugging Face."""
from __future__ import annotations
import argparse, json, shutil
from pathlib import Path
from huggingface_hub import HfApi, hf_hub_download
ROOT = Path(__file__).resolve().parents[1]
MANIFEST = json.loads((ROOT / "models.json").read_text())
MODELS = {item["task"]: item for item in MANIFEST["models"]}

def download(task: str, namespace: str, revision: str | None, force: bool) -> None:
    model = MODELS[task]
    repo_id = f"{namespace}/{model['repo']}"
    destination = ROOT / "tasks" / task / "checkpoint"
    existing = [p for p in destination.iterdir() if p.name != "README.md"]
    if existing and not force:
        raise SystemExit(f"{destination} is not empty; pass --force to replace downloaded files")
    if force:
        for path in existing:
            shutil.rmtree(path) if path.is_dir() else path.unlink()
    files = [name for name in HfApi().list_repo_files(repo_id, revision=revision, repo_type="model") if name.startswith("ckpt/") and not name.endswith("/")]
    if not files:
        raise SystemExit(f"{repo_id} contains no files under ckpt/")
    for name in files:
        cached = Path(hf_hub_download(repo_id, name, revision=revision, repo_type="model"))
        target = destination / Path(name).relative_to("ckpt")
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(cached, target)
    print(f"downloaded {repo_id}@{revision or 'main'} -> {destination}")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("task", nargs="?", choices=sorted(MODELS))
    parser.add_argument("--all", action="store_true", dest="all_tasks")
    parser.add_argument("--namespace", default=MANIFEST["default_namespace"])
    parser.add_argument("--revision")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    if args.all_tasks == (args.task is not None):
        parser.error("specify exactly one TASK or --all")
    for task in (list(MODELS) if args.all_tasks else [args.task]):
        download(task, args.namespace, args.revision, args.force)
if __name__ == "__main__":
    main()
