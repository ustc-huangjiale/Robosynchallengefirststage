"""mixer_operating ACT policy entry point."""
from submission.policy.act_adapter import eval, get_model, reset_model

__all__ = ["get_model", "eval", "reset_model"]
