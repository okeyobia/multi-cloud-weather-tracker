"""Configuration for pytest."""
import pytest
from fastapi.testclient import TestClient
from app.main import app


@pytest.fixture
def client():
    """Fixture that provides a test client."""
    return TestClient(app)


@pytest.fixture
def event_loop():
    """Fixture that provides an event loop for async tests."""
    import asyncio
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()
