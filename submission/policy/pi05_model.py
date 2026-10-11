"""OpenPI pi0.5 checkpoint wrapper with model-owned task transforms."""
import dataclasses
import os

os.environ.setdefault("JAX_PLATFORMS", "cuda")
import jax

if devices := os.environ.get("PI05_JAX_VISIBLE_DEVICES"):
    jax.config.update("jax_cuda_visible_devices", devices)

import numpy as np
from openpi.models import pi0_config
from openpi.policies import policy_config
from openpi.training import config as training_config


_TASK_REPO_IDS = {
    "pi05_items_handover_release_full":
        "RoboSynChallenge/cobotmagic_Sim_items_handover_release_random1000",
    "pi05_items_handover_release_handover46_v9_full":
        "RoboSynChallenge/cobotmagic_Sim_items_handover_release_handover46_v9_exact_left40_right60_insert50_random1000",
    "pi05_table_rearrangement_official_strict1000_recovery295_full":
        "RoboSynChallenge/cobotmagic_Sim_table_rearrangement_official_strict1000_recovery295",
    "pi05_base_robosynchallenge_manipulate_pipette_synth1200_v1":
        "RoboSynChallenge/cobotmagic_Sim_manipulate_pipette_merged1356_v21",
    "pi05_sample_loading_official8818_best":
        "RoboSynChallenge/cobotmagic_Sim_sample_loading",
    "pi05_click_bell_multisource_v1":
        "RoboSynChallenge/cobotmagic_Sim_click_bell_multisource_v1",
    "pi05_water_pouring_official1k_v2":
        "RoboSynChallenge/cobotmagic_Sim_water_pouring",
    "pi05_handle_basket_reachability_v2":
        "RoboSynChallenge/cobotmagic_Sim_handle_basket_reachability_balanced_v2",
    "pi05_drawer_open_place_stage2_v1":
        "RoboSynChallenge/cobotmagic_Sim_drawer_open_place_stage2_v1",
}


def _get_config(name):
    """Build task-specific inference transforms without local symlink aliases."""
    repo_id = _TASK_REPO_IDS.get(name)
    if repo_id is None:
        return training_config.get_config(name)
    data_kwargs = {}
    if name == "pi05_table_rearrangement_official_strict1000_recovery295_full":
        data_kwargs.update(
            gripper_action_input_scale=20.0,
            gripper_action_output_scale=0.05,
        )
    return training_config.TrainConfig(
        name=name,
        model=pi0_config.Pi0Config(pi05=True, action_horizon=50),
        data=training_config.LeRobotEmbodiChainDataConfig(
            repo_id=repo_id,
            base_config=training_config.DataConfig(prompt_from_task=True),
            extra_delta_transform=True,
            **data_kwargs,
        ),
    )

class PI05:
    def __init__(
        self,
        train_config_name,
        checkpoint_path,
        pi0_step,
        instruction_override=None,
        denormalize_eef_action=False,
    ):
        config = _get_config(train_config_name)
        if hasattr(config.model, "pytorch_compile_mode"):
            config = dataclasses.replace(
                config,
                model=dataclasses.replace(
                    config.model, pytorch_compile_mode=None
                ),
            )
        self.policy = policy_config.create_trained_policy(config, checkpoint_path)
        self.pi0_step = int(pi0_step)
        self.instruction_override = instruction_override
        self.denormalize_eef_action = bool(denormalize_eef_action)
        self.observation_window = None
        self.pytorch_device = None
        self._eef_indices = None
        self._action_low = None
        self._action_high = None

    def configure_environment(self, env):
        """Capture output-space metadata once; all mapping remains model-owned."""
        if not self.denormalize_eef_action or self._eef_indices is not None:
            return
        base = env.unwrapped
        active_ids = list(base.active_joint_ids)
        active_index = {joint_id: index for index, joint_id in enumerate(active_ids)}
        indices = []
        for part in ("left_eef", "right_eef"):
            for joint_id in base.robot.get_joint_ids(name=part, remove_mimic=True):
                if joint_id in active_index:
                    indices.append(active_index[joint_id])
        space = base.single_action_space
        self._eef_indices = tuple(indices)
        self._action_low = np.asarray(space.low, dtype=np.float32).reshape(-1)
        self._action_high = np.asarray(space.high, dtype=np.float32).reshape(-1)

    def set_language(self, instruction):
        self.instruction = self.instruction_override or instruction

    def update_observation_window(self, images, state):
        front, right, left = images
        self.observation_window = {
            "observation/image": front,
            "observation/left_wrist_image": left,
            "observation/right_wrist_image": right,
            "observation/state": state,
            "prompt": self.instruction,
        }

    def _postprocess_actions(self, actions):
        values = np.asarray(actions, dtype=np.float32).copy()
        if not self.denormalize_eef_action:
            return values
        if self._eef_indices is None:
            raise RuntimeError("configure_environment() must run before inference")
        for index in self._eef_indices:
            values[..., index] = self._action_low[index] + np.clip(
                values[..., index], 0.0, 1.0
            ) * (self._action_high[index] - self._action_low[index])
        return values

    def get_action(self):
        actions = self.policy.infer(self.observation_window)["actions"]
        return self._postprocess_actions(actions)

    def reset(self):
        self.instruction = None
        self.observation_window = None
