"""The metrics endpoint reports the requests the application handled."""

from httpx import AsyncClient


async def test_metrics_count_handled_requests(client: AsyncClient) -> None:
    await client.get("/health")
    await client.get("/health")

    response = await client.get("/metrics")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain")
    counters = [
        line
        for line in response.text.splitlines()
        if line.startswith("http_requests_total{") and 'handler="/health"' in line
    ]
    assert len(counters) == 1
    assert counters[0].endswith(" 2.0")


async def test_metrics_include_process_information(client: AsyncClient) -> None:
    response = await client.get("/metrics")

    assert "python_info{" in response.text
