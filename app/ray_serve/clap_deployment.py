"""Ray Serve deployment for CLAP (audio) embeddings."""

import base64
import io
import logging
from typing import Any

import librosa
import numpy as np
import torch
from ray import serve
from starlette.requests import Request
from transformers import ClapModel, ClapProcessor

from model_loader import get_model_path

logger = logging.getLogger("ray.serve")

SAMPLE_RATE = 48000  # CLAP expects 48kHz audio


@serve.deployment(
    name="CLAPEmbedder",
    num_replicas=1,
    ray_actor_options={"num_gpus": 1, "num_cpus": 1},
    max_ongoing_requests=10,
    health_check_period_s=15,
    health_check_timeout_s=30,
)
class CLAPEmbedder:
    def __init__(self) -> None:
        model_path = get_model_path("clap/clap-htsat-unfused")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info("Loading CLAP model from %s onto %s", model_path, self.device)
        self.model = ClapModel.from_pretrained(str(model_path)).to(self.device)
        self.model.eval()
        self.processor = ClapProcessor.from_pretrained(str(model_path))
        logger.info("CLAP model loaded successfully")

    async def __call__(self, request: Request) -> dict[str, Any]:
        data = await request.json()

        if "text" in data:
            return self._embed_text(data["text"])
        elif "audio_b64" in data:
            return self._embed_audio(data["audio_b64"])
        else:
            return {"error": "Request must include 'text' or 'audio_b64'"}

    def _embed_text(self, text: str | list[str]) -> dict[str, Any]:
        if isinstance(text, str):
            text = [text]
        inputs = self.processor(text=text, return_tensors="pt", padding=True).to(self.device)
        with torch.no_grad():
            features = self.model.get_text_features(**inputs)
        embeddings = features.cpu().numpy().tolist()
        return {
            "embeddings": embeddings,
            "model": "clap-htsat-unfused",
            "modality": "text",
            "dim": len(embeddings[0]),
        }

    def _embed_audio(self, audio_b64: str) -> dict[str, Any]:
        audio_bytes = base64.b64decode(audio_b64)
        waveform, sr = librosa.load(io.BytesIO(audio_bytes), sr=SAMPLE_RATE, mono=True)
        waveform = waveform.astype(np.float32)

        inputs = self.processor(
            audios=waveform,
            sampling_rate=SAMPLE_RATE,
            return_tensors="pt",
        ).to(self.device)
        with torch.no_grad():
            features = self.model.get_audio_features(**inputs)
        embedding = features.cpu().numpy().tolist()
        return {
            "embeddings": embedding,
            "model": "clap-htsat-unfused",
            "modality": "audio",
            "dim": len(embedding[0]),
        }


app = CLAPEmbedder.bind()
