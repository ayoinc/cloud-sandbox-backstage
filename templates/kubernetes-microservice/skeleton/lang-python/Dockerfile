FROM python:3.13-alpine AS base
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

ENV PORT=8080

USER 10001:10001

EXPOSE 8080

CMD ["python", "app.py"]
