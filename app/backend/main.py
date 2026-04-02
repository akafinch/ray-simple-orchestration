"""FastAPI demo backend for CLIP/CLAP inference on Akamai LKE."""

import os

import httpx
from fastapi import FastAPI, Request, Response
from fastapi.staticfiles import StaticFiles
from prometheus_fastapi_instrumentator import Instrumentator

from routes.embed import router as embed_router
from routes.health import router as health_router

app = FastAPI(
    title="CLIP/CLAP Inference Demo",
    description="Multimodal embedding service powered by Ray Serve on Akamai GPU infrastructure",
    version="1.0.0",
)

# Prometheus metrics at /metrics
Instrumentator().instrument(app).expose(app)

# API routes
app.include_router(health_router)
app.include_router(embed_router)

# Grafana reverse proxy — keeps Grafana on ClusterIP, no extra LoadBalancer
GRAFANA_INTERNAL = os.environ.get(
    "GRAFANA_INTERNAL_URL", "http://kube-prometheus-stack-grafana.monitoring:80"
)


@app.api_route("/grafana/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def grafana_proxy(path: str, request: Request) -> Response:
    """Forward requests to the cluster-internal Grafana service."""
    url = f"{GRAFANA_INTERNAL}/{path}"
    if request.url.query:
        url = f"{url}?{request.url.query}"

    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.request(
            method=request.method,
            url=url,
            headers={k: v for k, v in request.headers.items() if k.lower() != "host"},
            content=await request.body(),
        )

    return Response(
        content=resp.content,
        status_code=resp.status_code,
        headers={k: v for k, v in resp.headers.items() if k.lower() not in ("transfer-encoding",)},
    )


# Serve the SvelteKit frontend build as static files.
# This mount must come last — it catches all unmatched paths.
app.mount("/", StaticFiles(directory="frontend/build", html=True), name="frontend")
