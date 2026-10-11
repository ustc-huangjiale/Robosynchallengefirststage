# sample_loading checkpoint

- Policy: π0.5
- Checkpoint step: 4900
- Recorded evaluation result: 2/93 (2.2%); run stopped before episode 94 by the former 100-candidate feasibility cap; original checkpoint selection benchmark: 3/60 (5%)
- Hugging Face repository: https://huggingface.co/ustc-huangjiale/robosynchallenge-firststage-pi05-sample-loading
- Repository checkpoint path: `ckpt/`

Download with:

```bash
python scripts/download_checkpoint.py sample_loading --namespace ustc-huangjiale
```

Do not commit downloaded weight files to GitHub.
