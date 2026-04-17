"""Embedding, classification, and similarity routes — proxies to Ray Serve CLIP/CLAP deployments."""

import base64
import os
import time
from typing import Any

import httpx
import numpy as np
from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydantic import BaseModel

router = APIRouter()

RAY_SERVE_URL = os.environ.get("RAY_SERVE_URL", "http://clip-clap-serve-svc.ray-system:8000")
HTTP_TIMEOUT = 30.0


class TextRequest(BaseModel):
    text: str


class SimilarityRequest(BaseModel):
    a: list[float]
    b: list[float]


class ClassifyRequest(BaseModel):
    labels: list[str]


async def _call_ray(endpoint: str, payload: dict[str, Any]) -> dict[str, Any]:
    """Forward a request to Ray Serve and return the parsed response."""
    url = f"{RAY_SERVE_URL}{endpoint}"
    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
        resp = await client.post(url, json=payload)
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Ray Serve returned {resp.status_code}: {resp.text}")
    return resp.json()


@router.post("/embed/text")
async def embed_text(req: TextRequest) -> dict[str, Any]:
    """Embed text via CLIP."""
    start = time.perf_counter()
    result = await _call_ray("/clip", {"text": req.text})
    result["latency_ms"] = round((time.perf_counter() - start) * 1000, 1)
    return result


@router.post("/embed/image")
async def embed_image(file: UploadFile) -> dict[str, Any]:
    """Embed an uploaded image via CLIP."""
    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Image must be under 10MB")

    image_b64 = base64.b64encode(contents).decode("utf-8")
    start = time.perf_counter()
    result = await _call_ray("/clip", {"image_b64": image_b64})
    result["latency_ms"] = round((time.perf_counter() - start) * 1000, 1)
    return result


@router.post("/embed/audio")
async def embed_audio(file: UploadFile) -> dict[str, Any]:
    """Embed uploaded audio via CLAP."""
    contents = await file.read()
    if len(contents) > 50 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Audio must be under 50MB")

    audio_b64 = base64.b64encode(contents).decode("utf-8")
    start = time.perf_counter()
    result = await _call_ray("/clap", {"audio_b64": audio_b64})
    result["latency_ms"] = round((time.perf_counter() - start) * 1000, 1)
    return result


@router.post("/similarity")
async def similarity(req: SimilarityRequest) -> dict[str, float]:
    """Compute cosine similarity between two embedding vectors. Pure math, no GPU."""
    a = np.array(req.a, dtype=np.float32)
    b = np.array(req.b, dtype=np.float32)

    if a.shape != b.shape:
        raise HTTPException(status_code=400, detail=f"Dimension mismatch: {a.shape} vs {b.shape}")

    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)
    if norm_a == 0 or norm_b == 0:
        raise HTTPException(status_code=400, detail="Zero-norm vector cannot be compared")

    score = float(np.dot(a, b) / (norm_a * norm_b))
    return {"score": score}


@router.post("/classify/image")
async def classify_image(file: UploadFile, labels: str = Form(...)) -> dict[str, Any]:
    """Zero-shot image classification via CLIP. Labels are comma-separated."""
    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Image must be under 10MB")

    label_list = [l.strip() for l in labels.split(",") if l.strip()]
    if len(label_list) < 2:
        raise HTTPException(status_code=400, detail="Provide at least 2 comma-separated labels")

    image_b64 = base64.b64encode(contents).decode("utf-8")
    start = time.perf_counter()
    result = await _call_ray("/clip-classify", {"image_b64": image_b64, "labels": label_list})
    result["latency_ms"] = round((time.perf_counter() - start) * 1000, 1)
    return result


@router.post("/classify/audio")
async def classify_audio(file: UploadFile, labels: str = Form(...)) -> dict[str, Any]:
    """Zero-shot audio classification via CLAP. Labels are comma-separated."""
    contents = await file.read()
    if len(contents) > 50 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Audio must be under 50MB")

    label_list = [l.strip() for l in labels.split(",") if l.strip()]
    if len(label_list) < 2:
        raise HTTPException(status_code=400, detail="Provide at least 2 comma-separated labels")

    audio_b64 = base64.b64encode(contents).decode("utf-8")
    start = time.perf_counter()
    result = await _call_ray("/clap-classify", {"audio_b64": audio_b64, "labels": label_list})
    result["latency_ms"] = round((time.perf_counter() - start) * 1000, 1)
    return result
