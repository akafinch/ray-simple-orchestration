FROM rayproject/ray:2.54.0-gpu

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY model_loader.py clip_deployment.py clap_deployment.py serve_config.py ./

ENV MODEL_CACHE_PATH=/model-cache
