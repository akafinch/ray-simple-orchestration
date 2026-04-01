# Build context: app/ (parent directory)
# Run with: docker build -f backend/Dockerfile -t clip-clap-demo app/

# Stage 1: Build SvelteKit frontend
FROM node:20-slim AS frontend-builder
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ .
RUN npm run build

# Stage 2: Python runtime
FROM python:3.11-slim
WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/main.py .
COPY backend/routes/ ./routes/
COPY --from=frontend-builder /frontend/build ./frontend/build

EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--log-level", "info"]
