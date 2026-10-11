#!/usr/bin/env bash
set -euo pipefail
[[ $# -ge 1 ]] || { echo "usage: $0 TASK_DIR [overrides...]" >&2; exit 2; }
task_dir="$(cd "$1" && pwd)"; shift
submission_root="$(cd "$task_dir/../.." && pwd)"
task="$(basename "$task_dir")"
config="$task_dir/deploy_policy.yml"
checkpoint="$task_dir/checkpoint"
robosyn_root="${ROBOSYN_ROOT:-$(cd "$submission_root/.." && pwd)/RoboSynChallenge}"
embodichain_root="${EMBODICHAIN_ROOT:-$(cd "$robosyn_root/.." && pwd)/EmbodiChain}"
result_dir="$submission_root/eval_results/$task"
[[ -f "$robosyn_root/scripts/eval_policy.py" ]] || { echo "invalid ROBOSYN_ROOT: $robosyn_root" >&2; exit 2; }
[[ -d "$embodichain_root/embodichain" ]] || { echo "invalid EMBODICHAIN_ROOT: $embodichain_root" >&2; exit 2; }
if [[ ! -e "$checkpoint/params" && ! -e "$checkpoint/config.json" && ! -e "$checkpoint/pretrained_model/config.json" ]]; then echo "checkpoint is empty: $checkpoint" >&2; exit 2; fi
policy_name="$(python3 -c 'import sys,yaml; print(yaml.safe_load(open(sys.argv[1]))["policy_name"])' "$config")"
adapter_dir="$robosyn_root/policy/$policy_name"
source_dir="$submission_root/submission/policy_packages/$policy_name"
[[ ! -e "$adapter_dir" || -L "$adapter_dir" ]] || { echo "refusing to overwrite $adapter_dir" >&2; exit 2; }
ln -sfn "$source_dir" "$adapter_dir"
mkdir -p "$result_dir"
if [[ "$policy_name" == firststage_act ]]; then python_bin="${ACT_PYTHON:-$robosyn_root/policy/act/.venv/bin/python}"; else python_bin="${PI05_PYTHON:-$robosyn_root/policy/pi05/.venv/bin/python}"; fi
[[ -x "$python_bin" ]] || { echo "policy Python not found: $python_bin" >&2; exit 2; }
cd "$robosyn_root"
unset CUDA_VISIBLE_DEVICES
export PI05_JAX_VISIBLE_DEVICES=0 EMBODICHAIN_ROOT="$embodichain_root"
export PYTHONPATH="$submission_root:$robosyn_root:$robosyn_root/policy${PYTHONPATH:+:$PYTHONPATH}"
exec "$python_bin" -u scripts/eval_policy.py --config "$config" --overrides --checkpoint_path "$checkpoint" --gpu_id 0 --pytorch_device cuda:0 --eval_result_dir "$result_dir" "$@"
