FROM ${{ values.baseImage }} AS base
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py ./

# Built by the pipeline with --target test: runs the unit tests.
FROM base AS test
COPY test_app.py ./
RUN python -m unittest -v

FROM base

ENV PORT=${{ values.port }}

USER 10001:10001

EXPOSE ${{ values.port }}
{%- if values.includeHealthcheck %}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-q", "--spider", "http://127.0.0.1:${{ values.port }}/health"]
{%- endif %}

CMD ["python", "app.py"]
