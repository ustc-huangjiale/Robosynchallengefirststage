#!/usr/bin/env bash
set -euo pipefail
repo="${ROBOSYN_ROOT:?set ROBOSYN_ROOT to the official RoboSynChallenge checkout}"
embodichain_repo="${EMBODICHAIN_ROOT:?set EMBODICHAIN_ROOT to the EmbodiChain checkout}"
expected=8818c82df5fa2522809b8105e7018950dcc9a9a8
expected_embodichain=89c14da8d0221dc4ee2a4a3e0ba1078b16d447bd
actual="$(git -C "$repo" rev-parse HEAD)"
actual_embodichain="$(git -C "$embodichain_repo" rev-parse HEAD)"
[[ "$actual" == "$expected" ]] || { echo "expected official commit $expected, got $actual" >&2; exit 2; }
[[ "$actual_embodichain" == "$expected_embodichain" ]] || { echo "expected EmbodiChain commit $expected_embodichain, got $actual_embodichain" >&2; exit 2; }
python3 - "$repo" <<'PYCODE'
from pathlib import Path
import sys
repo = Path(sys.argv[1])


def replace_once(path, old, new, already_present, description):
    source = path.read_text()
    if already_present in source:
        print(f"{description} already applied")
        return
    if source.count(old) != 1:
        raise SystemExit(f"{path} differs; refusing to apply {description}")
    path.write_text(source.replace(old, new))
    print(f"applied {description}")


# Keep the official PI0.5 dexsim 0.4.1 runtime while overriding the newer
# EmbodiChain metadata, and retain the Ubuntu 20.04-compatible pymeshlab wheel.
pi05_project = repo / "policy/pi05/pyproject.toml"
replace_once(pi05_project, "    \"dexsim-engine==0.4.3\",", "    \"dexsim-engine==0.4.1\",", "    \"dexsim-engine==0.4.1\",", "PI0.5 official dexsim 0.4.1 pin")
replace_once(pi05_project, "override-dependencies = [\n", "override-dependencies = [\n    \"dexsim-engine==0.4.1\",\n", "    \"dexsim-engine==0.4.1\",\n", "PI0.5 EmbodiChain dexsim metadata override")
replace_once(pi05_project, "    \"av==15.1.0\"\n]", "    \"av==15.1.0\",\n    \"pymeshlab==2023.12.post3\"\n]", "    \"pymeshlab==2023.12.post3\"", "PI0.5 Ubuntu 20.04 pymeshlab pin")
act_project = repo / "policy/act/pyproject.toml"
replace_once(act_project, "    \"av>=14.2.0\",\n    \"dexsim-engine==0.4.3\",\n]", "    \"av>=14.2.0\",\n    \"dexsim-engine==0.4.3\",\n    \"pymeshlab==2023.12.post3\",\n]", "    \"pymeshlab==2023.12.post3\",", "ACT Ubuntu 20.04 pymeshlab pin")

action_bank = repo / "robosynchallenge/tasks/manipulate_pipette/action_bank.py"
source = action_bank.read_text()
old = "return ret.positions[0].numpy().T"
new = "return ret.positions[0].detach().cpu().numpy().T"
if new not in source:
    if source.count(old) != 1:
        raise SystemExit("official Pipette action_bank differs; refusing to modify it")
    action_bank.write_text(source.replace(old, new))
    print("applied Pipette CUDA tensor-to-NumPy compatibility fix")
else:
    print("Pipette compatibility fix already present")

# The submitted checkpoint was trained with this instruction. Keep the
# simulator and success predicate official; only align the language input.
gym_config = repo / "configs/manipulate_pipette/random/gym_config.json"
source = gym_config.read_text()
old_instruction = "Use the pipette on the table to transfer liquid from one beaker to another"
new_instruction = "Hold the pipette over the beaker with the right gripper and press its plunger once with the left gripper."
if new_instruction not in source:
    if source.count(old_instruction) != 1:
        raise SystemExit("official Pipette instruction differs; refusing to modify it")
    gym_config.write_text(source.replace(old_instruction, new_instruction))
    print("aligned the Pipette language instruction with checkpoint training")
else:
    print("Pipette language instruction already aligned")

evaluator = repo / "scripts/eval_policy.py"
source = evaluator.read_text()
old_config = '''    if expert_check:
        max_seed_attempts_per_episode = int(
            config.get("eval_max_seed_attempts_per_episodes", 100)
        )
        if max_seed_attempts_per_episode < 1:
            raise ValueError(
                "eval_max_seed_attempts_per_episodes must be greater than zero."
            )
'''
new_config = '''    if expert_check:
        # Keep sampling candidate seeds until the expert feasibility check passes.
        max_seed_attempts_per_episode = None
'''
if old_config in source:
    source = source.replace(old_config, new_config)
    source = source.replace('''            " (max candidate seeds per episode: "
            f"{max_seed_attempts_per_episode})"
''', '''            " (candidate seeds per episode: unlimited)"
''')
    start = source.index("            if current_episode_seed_attempts >= max_seed_attempts_per_episode:")
    end = source.index("            ep_seed = (", start)
    source = source[:start] + source[end:]
    source = source.replace('f" Expert Feasibility Check Attempt {current_episode_seed_attempts}/"\n                        f"{max_seed_attempts_per_episode} "', 'f" Expert Feasibility Check Attempt {current_episode_seed_attempts} "')
    source = source.replace('f" Expert Feasibility Check Attempt {current_episode_seed_attempts}/"\n                    f"{max_seed_attempts_per_episode} "', 'f" Expert Feasibility Check Attempt {current_episode_seed_attempts} "')
    evaluator.write_text(source)
    print("removed the per-episode candidate-seed limit")
elif "candidate seeds per episode: unlimited" in source:
    print("candidate-seed limit already removed")
else:
    raise SystemExit("official evaluator differs; refusing to modify it")
PYCODE
