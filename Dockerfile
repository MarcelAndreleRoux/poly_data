# poly_data collector (upstream: github.com/warproxxx/poly_data, GPL-3.0).
# Added locally: a loop entrypoint so the pipeline keeps collecting over time.
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/opt/venv

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:0.8.14 /uv /uvx /bin/

WORKDIR /app
COPY pyproject.toml uv.lock ./
COPY poly_utils ./poly_utils
COPY update_utils ./update_utils
COPY tests ./tests
COPY update.py README.md LICENSE ./
RUN uv sync --frozen --no-dev --group dev \
    && uv run --frozen pytest -q tests \
    && rm -rf /root/.cache

COPY run_loop.sh /app/run_loop.sh
RUN chmod +x /app/run_loop.sh

VOLUME ["/app/data", "/app/processed"]
ENTRYPOINT ["/app/run_loop.sh"]
