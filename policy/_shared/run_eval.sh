#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "internal usage: run_eval.sh POLICY_DIR BACKEND [CHECKPOINT] [overrides...]" >&2
    exit 2
fi

POLICY_DIR="$(cd "$1" && pwd)"
BACKEND="$2"
shift 2

REPO_ROOT="$(cd "$POLICY_DIR/../.." && pwd)"
WORKSPACE_ROOT="$(cd "$REPO_ROOT/.." && pwd)"
EMBODICHAIN_ROOT="${EMBODICHAIN_ROOT:-$WORKSPACE_ROOT/EmbodiChain}"
CHECKPOINT_PATH="${CHECKPOINT_PATH:-}"

if [[ -z "$CHECKPOINT_PATH" && $# -gt 0 && "${1:0:1}" != "-" ]]; then
    CHECKPOINT_PATH="$1"
    shift
fi
if [[ -z "$CHECKPOINT_PATH" ]]; then
    CHECKPOINT_PATH="$POLICY_DIR/checkpoint"
fi
if [[ ! -e "$CHECKPOINT_PATH" ]]; then
    echo "checkpoint not found: $CHECKPOINT_PATH" >&2
    echo "pass it as the first argument or set CHECKPOINT_PATH" >&2
    exit 2
fi

case "$BACKEND" in
    pi05)
        PYTHON_BIN="${PI05_PYTHON:-$REPO_ROOT/policy/pi05/.venv/bin/python}"
        ;;
    act)
        PYTHON_BIN="${ACT_PYTHON:-$REPO_ROOT/policy/act/.venv/bin/python}"
        ;;
    *)
        echo "unsupported backend: $BACKEND" >&2
        exit 2
        ;;
esac

if [[ ! -x "$PYTHON_BIN" ]]; then
    echo "official $BACKEND runtime not found: $PYTHON_BIN" >&2
    echo "install the official policy/$BACKEND environment first" >&2
    exit 2
fi
if [[ ! -f "$REPO_ROOT/scripts/eval_policy.py" ]]; then
    echo "this policy tree must be retained inside RoboSynChallenge" >&2
    exit 2
fi

# The official evaluation target is one physical GPU, GPU 0. These defaults
# remain overrideable for a local smoke test without changing the YAML.
GPU_ID="${ROBOSYN_GPU_ID:-0}"
POLICY_DEVICE="${ROBOSYN_POLICY_DEVICE:-cuda:0}"
export CUDA_VISIBLE_DEVICES="${ROBOSYN_CUDA_VISIBLE_DEVICES:-0}"
export PI05_JAX_VISIBLE_DEVICES="${PI05_JAX_VISIBLE_DEVICES:-0}"
export XLA_PYTHON_CLIENT_PREALLOCATE="${XLA_PYTHON_CLIENT_PREALLOCATE:-false}"
export EMBODICHAIN_ROOT
export PYTHONPATH="$REPO_ROOT:$REPO_ROOT/policy:$REPO_ROOT/policy/pi05/src:$REPO_ROOT/policy/pi05/packages/openpi-client/src:$EMBODICHAIN_ROOT${PYTHONPATH:+:$PYTHONPATH}"

cd "$REPO_ROOT"
exec env \
    PYTHONWARNINGS=ignore::UserWarning \
    EMBODICHAIN_SIM_EXIT_PROCESS=0 \
    "$PYTHON_BIN" -u scripts/eval_policy.py \
    --config "$POLICY_DIR/deploy_policy.yml" \
    --overrides \
    --checkpoint_path "$CHECKPOINT_PATH" \
    --gpu_id "$GPU_ID" \
    --pytorch_device "$POLICY_DEVICE" \
    "$@"
