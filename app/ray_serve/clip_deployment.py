"""Ray Serve deployment for CLIP (text + image) embeddings."""

import base64
import io
import logging
from typing import Any

import torch
from PIL import Image
from ray import serve
from starlette.requests import Request
from transformers import CLIPModel, CLIPProcessor

from model_loader import get_model_path

logger = logging.getLogger("ray.serve")


@serve.deployment(
    name="CLIPEmbedder",
    num_replicas=2,
    ray_actor_options={"num_gpus": 1, "num_cpus": 1},
    max_ongoing_requests=10,
    health_check_period_s=15,
    health_check_timeout_s=30,
)
class CLIPEmbedder:
    def __init__(self) -> None:
        model_path = get_model_path("clip/clip-vit-large-patch14")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info("Loading CLIP model from %s onto %s", model_path, self.device)
        self.model = CLIPModel.from_pretrained(str(model_path)).to(self.device)
        self.model.eval()
        self.processor = CLIPProcessor.from_pretrained(str(model_path))
        logger.info("CLIP model loaded successfully")

    async def __call__(self, request: Request) -> dict[str, Any]:
        data = await request.json()

        if "text" in data:
            return self._embed_text(data["text"])
        elif "image_b64" in data:
            return self._embed_image(data["image_b64"])
        else:
            return {"error": "Request must include 'text' or 'image_b64'"}

    def _embed_text(self, text: str | list[str]) -> dict[str, Any]:
        if isinstance(text, str):
            text = [text]
        inputs = self.processor(text=text, return_tensors="pt", padding=True, truncation=True).to(self.device)
        with torch.no_grad():
            features = self.model.get_text_features(**inputs)
        embeddings = features.cpu().numpy().tolist()
        return {
            "embeddings": embeddings,
            "model": "clip-vit-large-patch14",
            "modality": "text",
            "dim": len(embeddings[0]),
        }

    def _embed_image(self, image_b64: str) -> dict[str, Any]:
        image_bytes = base64.b64decode(image_b64)
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        inputs = self.processor(images=image, return_tensors="pt").to(self.device)
        with torch.no_grad():
            features = self.model.get_image_features(**inputs)
        embedding = features.cpu().numpy().tolist()
        return {
            "embeddings": embedding,
            "model": "clip-vit-large-patch14",
            "modality": "image",
            "dim": len(embedding[0]),
        }

    def _classify_image(self, image_b64: str, labels: list[str]) -> dict[str, Any]:
        image_bytes = base64.b64decode(image_b64)
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        inputs = self.processor(
            text=labels,
            images=image,
            return_tensors="pt",
            padding=True,
            truncation=True,
        ).to(self.device)

        with torch.no_grad():
            outputs = self.model(**inputs)
            logits_per_image = outputs.logits_per_image
            probs = logits_per_image.softmax(dim=1)

        probs_list = probs.cpu().numpy()[0].tolist()
        results = [{"label": label, "score": score} for label, score in zip(labels, probs_list)]
        results.sort(key=lambda x: x["score"], reverse=True)

        return {
            "results": results,
            "model": "clip-vit-large-patch14",
            "modality": "image",
        }


@serve.deployment(
    name="CLIPClassifier",
    num_replicas=2,
    ray_actor_options={"num_gpus": 1, "num_cpus": 1},
    max_ongoing_requests=10,
    health_check_period_s=15,
    health_check_timeout_s=30,
)
class CLIPClassifier:
    def __init__(self) -> None:
        model_path = get_model_path("clip/clip-vit-large-patch14")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info("Loading CLIP classifier from %s onto %s", model_path, self.device)
        self.model = CLIPModel.from_pretrained(str(model_path)).to(self.device)
        self.model.eval()
        self.processor = CLIPProcessor.from_pretrained(str(model_path))
        logger.info("CLIP classifier loaded successfully")

    async def __call__(self, request: Request) -> dict[str, Any]:
        data = await request.json()

        if "image_b64" not in data or "labels" not in data:
            return {"error": "Request must include 'image_b64' and 'labels'"}

        image_b64 = data["image_b64"]
        labels = data["labels"]

        if not isinstance(labels, list) or len(labels) < 2:
            return {"error": "'labels' must be a list with at least 2 items"}

        image_bytes = base64.b64decode(image_b64)
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        inputs = self.processor(
            text=labels,
            images=image,
            return_tensors="pt",
            padding=True,
            truncation=True,
        ).to(self.device)

        with torch.no_grad():
            outputs = self.model(**inputs)
            logits_per_image = outputs.logits_per_image
            probs = logits_per_image.softmax(dim=1)

        probs_list = probs.cpu().numpy()[0].tolist()
        results = [{"label": label, "score": score} for label, score in zip(labels, probs_list)]
        results.sort(key=lambda x: x["score"], reverse=True)

        return {
            "results": results,
            "model": "clip-vit-large-patch14",
            "modality": "image",
        }


embedder_app = CLIPEmbedder.bind()
classifier_app = CLIPClassifier.bind()
