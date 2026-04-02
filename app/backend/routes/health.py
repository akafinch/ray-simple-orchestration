"""Health and readiness endpoints."""

import os

import httpx
from fastapi import APIRouter

router = APIRouter()

RAY_SERVE_URL = os.environ.get("RAY_SERVE_URL", "http://clip-clap-serve-svc.ray-system:8000")


@router.get("/health")
async def health() -> dict:
    """Liveness probe + Ray Serve reachability check."""
    ray_status = "unreachable"
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(f"{RAY_SERVE_URL}/-/healthz")
            if resp.status_code == 200:
                ray_status = "reachable"
    except httpx.HTTPError:
        pass

    return {"status": "ok", "ray_serve": ray_status}


@router.get("/ready")
async def ready() -> dict:
    """Readiness probe — only ready when Ray Serve is reachable."""
    async with httpx.AsyncClient(timeout=5.0) as client:
        resp = await client.get(f"{RAY_SERVE_URL}/-/healthz")
        resp.raise_for_status()
    return {"status": "ready"}


@router.get("/config")
async def config() -> dict:
    """Expose non-sensitive runtime config for the frontend."""
    return {
        "ray_serve_url": RAY_SERVE_URL,
        "grafana_url": "/grafana",
    }
