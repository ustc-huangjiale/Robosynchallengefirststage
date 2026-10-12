#!/usr/bin/env python3
"""Download small public OpenPI runtime assets with integrity checks."""
from __future__ import annotations

import hashlib
import os
from pathlib import Path
import shutil
import urllib.request

URL = "https://storage.googleapis.com/big_vision/paligemma_tokenizer.model"
SHA256 = "8986bb4f423f07f8c7f70d0dbe3526fb2316056c17bae71b1ea975e77a168fc6"


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def main() -> None:
    cache = Path(os.environ.get("OPENPI_DATA_HOME", "~/.cache/openpi")).expanduser().resolve()
    target = cache / "big_vision" / "paligemma_tokenizer.model"
    if target.is_file() and digest(target) == SHA256:
        print(f"verified {target}")
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    partial = target.with_suffix(".partial")
    if partial.exists():
        partial.unlink()
    print(f"downloading {URL} -> {target}")
    with urllib.request.urlopen(URL, timeout=120) as response, partial.open("wb") as output:
        shutil.copyfileobj(response, output)
    actual = digest(partial)
    if actual != SHA256:
        partial.unlink()
        raise SystemExit(f"tokenizer SHA256 mismatch: expected {SHA256}, got {actual}")
    partial.replace(target)
    print(f"verified {target}")


if __name__ == "__main__":
    main()
