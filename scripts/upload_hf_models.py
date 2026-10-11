#!/usr/bin/env python3
"""Create and upload the ten model repositories declared in models.json."""
from __future__ import annotations
import argparse, json, os
from pathlib import Path
from huggingface_hub import HfApi
ROOT = Path(__file__).resolve().parents[1]
MODELS = json.loads((ROOT / "models.json").read_text())["models"]

def model_card(model: dict, repo_id: str) -> str:
    policy = "π0.5" if model["policy"] == "pi05" else "ACT"
    return f'''---
tags:
- robotics
- robosynchallenge
- imitation-learning
---

# {model["title"]} — RoboSynChallenge First Stage

- Task: `{model["task"]}`
- Policy: {policy}
- Checkpoint: `{model["step"]}`
- Recorded evaluation: {model["result"]}
- Code and evaluation commands: https://github.com/ustc-huangjiale/Robosynchallengefirststage

The complete inference checkpoint is stored under `ckpt/`.
Repository ID: `{repo_id}`.
'''

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--namespace", required=True)
    parser.add_argument("--sources", type=Path, required=True, help="local JSON mapping task names to checkpoint directories")
    parser.add_argument("--private", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    sources = json.loads(args.sources.read_text())
    api = HfApi(token=os.environ.get("HF_TOKEN"))
    for model in MODELS:
        task = model["task"]
        source = Path(sources[task]).expanduser().resolve()
        if not source.is_dir():
            raise SystemExit(f"missing checkpoint directory for {task}: {source}")
        repo_id = f"{args.namespace}/{model['repo']}"
        print(f"{task}: {source} -> {repo_id}/ckpt")
        if args.dry_run:
            continue
        api.create_repo(repo_id, repo_type="model", private=args.private, exist_ok=True)
        api.upload_folder(repo_id=repo_id, repo_type="model", folder_path=str(source), path_in_repo="ckpt", ignore_patterns=["train_state/**", "optimizer.pt", "optimizer/**", "*.tmp", "**/__pycache__/**", "*.pyc"], commit_message=f"Upload {task} checkpoint {model['step']}")
        api.upload_file(repo_id=repo_id, repo_type="model", path_or_fileobj=model_card(model, repo_id).encode(), path_in_repo="README.md", commit_message="Add model card")
if __name__ == "__main__":
    main()
