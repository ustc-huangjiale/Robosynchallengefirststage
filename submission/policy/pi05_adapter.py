"""pi0.5 adapter implementing the official policy interface."""
import numpy as np
import torch

from .inference_timing import finish_inference, start_inference
from .pi05_model import PI05


def _images_and_state(obs):
    images = [
        obs["sensor"][name]["color"][0, ..., :3].detach().cpu().numpy()
        for name in ("cam_high", "cam_right_wrist", "cam_left_wrist")
    ]
    state = obs["robot"]["qpos"][0].detach().cpu().numpy()
    return images, state


def get_model(args):
    checkpoint = args.get("checkpoint_path")
    if not checkpoint:
        raise ValueError("checkpoint_path is required")
    model = PI05(
        args["train_config_name"],
        checkpoint,
        int(args.get("pi0_step", 10)),
        instruction_override=args.get("instruction_override"),
        denormalize_eef_action=bool(
            args.get("denormalize_eef_action", False)
        ),
    )
    model.pytorch_device = args.get("pytorch_device", "cuda:0")
    return model


def eval(env, model, obs):
    model.configure_environment(env)
    if model.observation_window is None:
        model.set_language(getattr(env, "_current_instruction", None))
    timings = []
    started = start_inference(model.pytorch_device)
    images, state = _images_and_state(obs)
    model.update_observation_window(images, state)
    actions = model.get_action()[: model.pi0_step]

    env_dim = int(np.prod(env.unwrapped.single_action_space.shape))
    tensors = []
    for action in actions:
        values = np.asarray(action, dtype=np.float32).reshape(-1)
        if values.size < env_dim:
            raise ValueError(
                f"policy action dim {values.size}, environment expects {env_dim}"
            )
        tensors.append(
            torch.as_tensor(
                values[:env_dim],
                dtype=torch.float32,
                device=env.unwrapped.device,
            ).unsqueeze(0)
        )
    finish_inference(started, timings, model.pytorch_device)

    final_obs, info, truncated = obs, None, False
    for action in tensors:
        final_obs, _, _, truncated, info = env.step(action)
        if (
            env.get_wrapper_attr("is_task_success")()
            or torch.as_tensor(truncated).any().item()
        ):
            break
        images, state = _images_and_state(final_obs)
        model.update_observation_window(images, state)
    return final_obs, info, truncated, timings


def reset_model(model):
    model.reset()
