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
if [[ ! -e "$checkpoint/params" && ! -e "$checkpoint/model.safetensors" && ! -e "$checkpoint/config.json" && ! -e "$checkpoint/pretrained_model/config.json" ]]; then echo "checkpoint is empty: $checkpoint" >&2; exit 2; fi
policy_name="$(sed -n 's/^policy_name:[[:space:]]*//p' "$config")"
[[ -n "$policy_name" ]] || { echo "policy_name is missing from $config" >&2; exit 2; }
adapter_dir="$robosyn_root/policy/$policy_name"
source_dir="$submission_root/submission/policy_packages/$policy_name"
[[ ! -e "$adapter_dir" || -L "$adapter_dir" ]] || { echo "refusing to overwrite $adapter_dir" >&2; exit 2; }
ln -sfn "$source_dir" "$adapter_dir"
mkdir -p "$result_dir"
if [[ "$policy_name" == firststage_act ]]; then python_bin="${ACT_PYTHON:-$robosyn_root/policy/act/.venv/bin/python}"; else python_bin="${PI05_PYTHON:-$robosyn_root/policy/pi05/.venv/bin/python}"; fi
[[ -x "$python_bin" ]] || { echo "policy Python not found: $python_bin" >&2; exit 2; }
if ! "$python_bin" -c 'import ctypes; ctypes.CDLL("libnvoptix.so.1")' >/dev/null 2>&1; then
  echo "NVIDIA OptiX runtime not found: libnvoptix.so.1 (install the complete NVIDIA userspace driver)" >&2
  exit 2
fi
render_nodes=(/dev/dri/renderD*)
if [[ -e "${render_nodes[0]}" ]]; then
  render_access=false
  for node in "${render_nodes[@]}"; do
    if [[ -r "$node" && -w "$node" ]]; then
      render_access=true
      break
    fi
  done
  if [[ "$render_access" != true ]]; then
    echo "no read/write access to /dev/dri/renderD* (add the user to the render group and start a new login session)" >&2
    exit 2
  fi
fi
cd "$robosyn_root"
gpu_id="${ROBOSYN_GPU_ID:-0}"
policy_gpu_id="${ROBOSYN_POLICY_GPU_ID:-$gpu_id}"
[[ "$gpu_id" =~ ^[0-9]+$ ]] || { echo "ROBOSYN_GPU_ID must be a non-negative integer" >&2; exit 2; }
[[ "$policy_gpu_id" =~ ^[0-9]+$ ]] || { echo "ROBOSYN_POLICY_GPU_ID must be a non-negative integer" >&2; exit 2; }
if [[ -n "${ROBOSYN_CUDA_VISIBLE_DEVICES:-}" ]]; then
  export CUDA_VISIBLE_DEVICES="$ROBOSYN_CUDA_VISIBLE_DEVICES"
else
  unset CUDA_VISIBLE_DEVICES
fi
export PI05_JAX_VISIBLE_DEVICES="$policy_gpu_id" EMBODICHAIN_ROOT="$embodichain_root"
# JAX preallocates 75% of a GPU by default, which starves DexSim/Vulkan when
# policy and simulator intentionally share one card. Grow the JAX pool on demand.
export XLA_PYTHON_CLIENT_PREALLOCATE="${XLA_PYTHON_CLIENT_PREALLOCATE:-false}"
export PYTHONPATH="$submission_root:$robosyn_root:$robosyn_root/policy${PYTHONPATH:+:$PYTHONPATH}"
exec "$python_bin" -u scripts/eval_policy.py --config "$config" --overrides --checkpoint_path "$checkpoint" --gpu_id "$gpu_id" --pytorch_device "cuda:$policy_gpu_id" --eval_result_dir "$result_dir" "$@"
