"""FastAPI demo backend for CLIP/CLAP inference on Akamai LKE."""

from fastapi import FastAPI
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

# Serve the SvelteKit frontend build as static files.
# This mount must come last — it catches all unmatched paths.
app.mount("/", StaticFiles(directory="frontend/build", html=True), name="frontend")
