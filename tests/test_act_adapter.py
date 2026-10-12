"""Run with the official ACT environment: python -m unittest discover -s tests."""
import unittest
from types import SimpleNamespace
from unittest.mock import Mock, patch

import torch

from submission.policy import act_adapter


class ACTDeviceTest(unittest.TestCase):
    def test_indexed_cuda_is_applied_after_config_validation(self):
        config = SimpleNamespace(device="cuda")
        model = Mock()
        model.parameters.return_value = iter([SimpleNamespace(device=torch.device("cuda:3"))])
        model.config.image_features = {"observation.images.cam_high": None}

        def parse_config(checkpoint, cli_overrides):
            self.assertEqual(cli_overrides, ["--device=cuda"])
            return config

        with patch.object(act_adapter.PreTrainedConfig, "from_pretrained", side_effect=parse_config), patch.object(
            act_adapter.ACTPolicy, "from_pretrained", return_value=model
        ) as load:
            result = act_adapter.get_model({"checkpoint_path": "/unused/checkpoint", "pytorch_device": "cuda:3"})

        self.assertEqual(config.device, "cuda:3")
        load.assert_called_once_with("/unused/checkpoint", config=config)
        self.assertEqual(result.act_device, torch.device("cuda:3"))


if __name__ == "__main__":
    unittest.main()
