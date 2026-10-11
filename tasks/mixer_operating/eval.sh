#!/usr/bin/env bash
set -euo pipefail
TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$TASK_DIR/../../scripts/eval_task.sh" "$TASK_DIR" "$@"
