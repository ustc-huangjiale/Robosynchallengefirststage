"""Regression checks for the verified Manipulate Pipette event latch."""

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OVERRIDE = ROOT / "scripts/official_overrides/manipulate_pipette.py"
SETUP = ROOT / "scripts/setup_official.sh"
EXPECTED_SHA256 = "8d40cec29db0b089dc48bb5f9914a2f65c42feffb91ab9c4e2cc725705475b00"


def test_verified_override_is_unchanged():
    assert hashlib.sha256(OVERRIDE.read_bytes()).hexdigest() == EXPECTED_SHA256


def test_override_latches_press_on_each_control_step():
    source = OVERRIDE.read_text()
    assert "def _update_sim_state(self, **kwargs):" in source
    assert "self._refresh_pipette_state(count_press=True)" in source
    assert "self._pipette_press_event = at_min & ~self._pipette_was_at_min" in source
    assert "self._pipette_min_reach_count += self._pipette_press_event.to(torch.int32)" in source


def test_override_resets_latch_at_episode_boundary():
    source = OVERRIDE.read_text()
    assert "def _initialize_episode(self, env_ids=None, **kwargs):" in source
    assert "self._pipette_min_reach_count[ids] = 0" in source
    assert "self._pipette_press_event[ids] = False" in source
    assert "self._pipette_was_at_min[ids] = self._pipette_metrics" in source


def test_official_success_predicate_is_preserved():
    source = OVERRIDE.read_text()
    assert "threshold = 0.66 * limits[:, 0] + self._pipette_min_tolerance" in source
    assert "self._pipette_min_reach_count >= 1" in source
    assert "& ~beaker_fallen & ~pipette_fallen" in source


def test_setup_installs_only_known_pipette_versions():
    source = SETUP.read_text()
    assert EXPECTED_SHA256 in source
    assert "official_pipette_sha256" in source
    assert 'ROBOSYN_PIPETTE_TASK_MODE:-latched' in source
    assert 'pipette_task_mode == "latched"' in source
    assert 'pipette_task_mode == "official"' in source
    assert "refusing to replace an unknown implementation" in source
