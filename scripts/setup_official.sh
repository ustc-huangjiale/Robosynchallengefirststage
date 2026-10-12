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
python3 - "$repo" "$embodichain_repo" <<'PYCODE'
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


# Align PI0.5 with EmbodiChain v0.2.4.post1 and retain the Ubuntu
# 20.04-compatible pymeshlab wheel.
pi05_project = repo / "policy/pi05/pyproject.toml"
replace_once(pi05_project, "    \"dexsim-engine==0.4.1\",\n    \"embodichain\",", "    \"dexsim-engine==0.4.3\",\n    \"embodichain\",", "    \"dexsim-engine==0.4.3\",\n    \"embodichain\",", "PI0.5 dexsim 0.4.3 compatibility pin")
source = pi05_project.read_text()
override = "override-dependencies = [\n    \"dexsim-engine==0.4.1\",\n"
if override in source:
    pi05_project.write_text(source.replace(override, "override-dependencies = [\n"))
    print("removed obsolete PI0.5 dexsim metadata override")
elif "override-dependencies = [\n" in source:
    print("obsolete PI0.5 dexsim metadata override already absent")
else:
    raise SystemExit("PI0.5 override-dependencies section differs")
replace_once(pi05_project, "    \"av==15.1.0\"\n]", "    \"av==15.1.0\",\n    \"pymeshlab==2023.12.post3\"\n]", "    \"pymeshlab==2023.12.post3\"", "PI0.5 Ubuntu 20.04 pymeshlab pin")
act_project = repo / "policy/act/pyproject.toml"
replace_once(act_project, "    \"av>=14.2.0\",\n    \"dexsim-engine==0.4.3\",\n]", "    \"av>=14.2.0\",\n    \"dexsim-engine==0.4.3\",\n    \"pymeshlab==2023.12.post3\",\n]", "    \"pymeshlab==2023.12.post3\",", "ACT Ubuntu 20.04 pymeshlab pin")

# Keep expert CP-SAT scheduling deterministic and avoid native worker-pool
# conflicts with policy runtimes initialized in the same process.
action_scheduler = (
    Path(sys.argv[2])
    / "embodichain/lab/gym/envs/action_bank/configurable_action.py"
)
replace_once(
    action_scheduler,
    "        solver = cp_model.CpSolver()\n        status = solver.solve(model)",
    "        solver = cp_model.CpSolver()\n        solver.parameters.num_search_workers = 1\n        status = solver.solve(model)",
    "        solver.parameters.num_search_workers = 1",
    "single-worker expert CP-SAT scheduling",
)

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

# Language input now comes from each task's instruction_override in
# tasks/<task>/deploy_policy.yml, so the official gym_config.json files stay
# untouched. Restore the shipped Pipette instruction if an earlier run of this
# script rewrote it.
gym_config = repo / "configs/manipulate_pipette/random/gym_config.json"
source = gym_config.read_text()
official_instruction = "Use the pipette on the table to transfer liquid from one beaker to another"
patched_instruction = "Hold the pipette over the beaker with the right gripper and press its plunger once with the left gripper."
if official_instruction in source:
    print("official Pipette instruction intact")
elif source.count(patched_instruction) == 1:
    gym_config.write_text(source.replace(patched_instruction, official_instruction))
    print("reverted the Pipette gym_config instruction to the official text")
else:
    raise SystemExit("official Pipette instruction differs; refusing to modify it")

evaluator = repo / "scripts/eval_policy.py"
source = evaluator.read_text()
old_device_select = '''def select_cuda_device(config):
    """Align an unqualified policy CUDA device with the simulator GPU."""
    pytorch_device = str(config.get("pytorch_device", ""))
    if pytorch_device.startswith("cuda") and torch.cuda.is_available():
        torch.cuda.set_device(int(config.get("gpu_id", 0)))
'''
new_device_select = '''def select_cuda_device(config):
    """Select the policy's logical CUDA device after simulator startup."""
    pytorch_device = str(config.get("pytorch_device", ""))
    if pytorch_device.startswith("cuda") and torch.cuda.is_available():
        device = torch.device(pytorch_device)
        torch.cuda.set_device(0 if device.index is None else device.index)
'''
if old_device_select in source:
    source = source.replace(old_device_select, new_device_select)
    print("separated simulator physical GPU from policy logical CUDA device")
elif new_device_select in source:
    print("simulator/policy CUDA device separation already fixed")
else:
    raise SystemExit("official evaluator CUDA device selector differs")
evaluator.write_text(source)
old_cuda_order = "    config = parse_args_and_config()\n    select_cuda_device(config)\n"
new_cuda_order = "    config = parse_args_and_config()\n"
cuda_after_env = "    env, gym_config_dict = make_env_from_configs(config, gym_config_dict, action_config_dict)\n    select_cuda_device(config)\n"
if old_cuda_order in source:
    if "    env, gym_config_dict = make_env_from_configs(config, gym_config_dict, action_config_dict)\n" not in source:
        raise SystemExit("official evaluator environment creation differs")
    source = source.replace(old_cuda_order, new_cuda_order)
    source = source.replace("    env, gym_config_dict = make_env_from_configs(config, gym_config_dict, action_config_dict)\n", cuda_after_env)
    evaluator.write_text(source)
    print("moved Torch CUDA selection after DexSim initialization")
elif cuda_after_env in source:
    print("Torch CUDA selection order already fixed")
else:
    raise SystemExit("official evaluator CUDA initialization differs")
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

# Some simulator backends terminate the process during env.close(). Persist the
# official summary and metrics before closing the environment.
source = evaluator.read_text()
old_close_order = """    finally:
        if video_recorder:
            video_recorder.close_episode(success=False)
        env.close()

    inference_call_count"""
new_close_order = """    finally:
        if video_recorder:
            video_recorder.close_episode(success=False)

    inference_call_count"""
close_after_metrics = """    print(f"{'='*50}")

    env.close()


if __name__ == "__main__":"""
if close_after_metrics in source:
    print("metrics-before-environment-close ordering already fixed")
elif old_close_order in source:
    source = source.replace(old_close_order, new_close_order)
    main_guard = """    print(f"{'='*50}")


if __name__ == "__main__":"""
    if source.count(main_guard) != 1:
        raise SystemExit("official evaluator final summary differs")
    evaluator.write_text(source.replace(main_guard, close_after_metrics))
    print("moved environment close after metrics persistence")
else:
    raise SystemExit("official evaluator environment-close ordering differs")
PYCODE
