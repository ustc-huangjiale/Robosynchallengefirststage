"""LeRobot ACT adapter implementing the official policy interface."""

import os

import numpy as np
import torch
from lerobot.configs.policies import PreTrainedConfig
from lerobot.policies.act.modeling_act import ACTPolicy

from .inference_timing import finish_inference, start_inference


def get_model(args):
    checkpoint = args.get("checkpoint_path")
    if not checkpoint:
        raise ValueError("checkpoint_path is required")

    nested = os.path.join(str(checkpoint), "pretrained_model")
    if (
        not os.path.isfile(os.path.join(str(checkpoint), "config.json"))
        and os.path.isfile(os.path.join(nested, "config.json"))
    ):
        checkpoint = nested

    device = args.get("pytorch_device", "cuda:0")
    # This pinned LeRobot release validates device types while the loaded model
    # itself correctly supports an indexed CUDA device.
    overrides = [f"--device={torch.device(device).type}"]
    config = PreTrainedConfig.from_pretrained(
        checkpoint,
        cli_overrides=overrides,
    )
    config.device = device
    model = ACTPolicy.from_pretrained(checkpoint, config=config)
    model.eval()
    model.act_device = next(model.parameters()).device
    model.act_step = int(args.get("act_step", 10))
    model.state_obs_path = args.get("state_obs_path", "robot/qpos")
    model.strict_action_dim = bool(args.get("strict_action_dim", True))
    model.image_keys = list(model.config.image_features)
    model.image_key_map = {
        "observation.images.cam_high": "cam_high",
        "observation.images.cam_right_wrist": "cam_right_wrist",
        "observation.images.cam_left_wrist": "cam_left_wrist",
        **(args.get("image_key_map") or {}),
    }
    return model


def eval(env, model, obs):
    final_obs, info, truncated, timings = obs, None, False, []
    for _ in range(model.act_step):
        runs_inference = (
            model.config.temporal_ensemble_coeff is not None
            or not model._action_queue
        )
        started = (
            start_inference(model.act_device) if runs_inference else None
        )

        state = final_obs
        for key in str(model.state_obs_path).split("/"):
            if key:
                state = state[key]
        state = torch.as_tensor(
            state,
            dtype=torch.float32,
            device=model.act_device,
        )
        if state.ndim == 1:
            state = state.unsqueeze(0)

        batch = {"observation.state": state}
        for image_key in model.image_keys:
            camera = model.image_key_map.get(
                image_key,
                image_key.removeprefix("observation.images."),
            )
            image = torch.as_tensor(
                final_obs["sensor"][camera]["color"],
                dtype=torch.float32,
                device=model.act_device,
            )
            if image.ndim == 3:
                image = image.unsqueeze(0)
            image = image[..., :3].permute(0, 3, 1, 2).contiguous()
            if image.max() > 1.5:
                image = image / 255.0
            batch[image_key] = image

        action = model.select_action(batch)
        if action.ndim == 1:
            action = action.unsqueeze(0)
        env_dim = int(np.prod(env.unwrapped.single_action_space.shape))
        if action.shape[-1] != env_dim:
            if model.strict_action_dim or action.shape[-1] < env_dim:
                raise ValueError(
                    f"policy action dim {action.shape[-1]}, "
                    f"environment expects {env_dim}"
                )
            action = action[:, :env_dim]
        action = action.to(
            device=env.unwrapped.device,
            dtype=torch.float32,
        )
        if runs_inference:
            finish_inference(started, timings, model.act_device)

        final_obs, _, _, truncated, info = env.step(action)
        if (
            env.get_wrapper_attr("is_task_success")()
            or torch.as_tensor(truncated).any().item()
        ):
            break
    return final_obs, info, truncated, timings


def reset_model(model):
    model.reset()
