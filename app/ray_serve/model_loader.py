"""Utility for resolving model paths from the local cache directory."""

import os
from pathlib import Path


def get_model_path(model_subdir: str) -> Path:
    """Return the resolved path for a model inside the init-container-populated cache.

    Args:
        model_subdir: Relative path within the cache, e.g. "clip/clip-vit-large-patch14".

    Returns:
        Absolute Path to the model directory.

    Raises:
        FileNotFoundError: If the resolved path does not exist (init container likely failed).
    """
    cache_root = Path(os.environ.get("MODEL_CACHE_PATH", "/model-cache"))
    model_path = cache_root / model_subdir

    if not model_path.exists():
        raise FileNotFoundError(
            f"Model not found at {model_path}. "
            "Check that the model-puller init container completed successfully."
        )
    return model_path
