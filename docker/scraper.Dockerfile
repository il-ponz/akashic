FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_LINK_MODE=copy \
    PATH="/opt/venv/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates poppler-utils tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv

WORKDIR /workspace
COPY scraper/pyproject.toml scraper/uv.lock ./scraper/
COPY scraper/pcblib ./scraper/pcblib
RUN uv sync --frozen --project /workspace/scraper

CMD ["pcblib"]
