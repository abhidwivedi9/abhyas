"""Unit tests for cart-service, against a fake Redis (no live dependency)."""
import fakeredis
import pytest
from fastapi.testclient import TestClient

from app import main


@pytest.fixture(autouse=True)
def fake_redis(monkeypatch):
    fake = fakeredis.FakeRedis(decode_responses=True)
    monkeypatch.setattr(main, "r", fake)
    return fake


@pytest.fixture
def client():
    return TestClient(main.app)


def test_health_ok(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_empty_cart(client):
    resp = client.get("/cart/user-1")
    assert resp.status_code == 200
    assert resp.json() == {"user_id": "user-1", "items": {}}


def test_add_item(client):
    resp = client.post("/cart/user-1/items", json={"product_id": "sku-42", "quantity": 2})
    assert resp.status_code == 200
    assert resp.json()["items"] == {"sku-42": 2}


def test_add_item_accumulates_quantity(client):
    client.post("/cart/user-1/items", json={"product_id": "sku-42", "quantity": 2})
    resp = client.post("/cart/user-1/items", json={"product_id": "sku-42", "quantity": 3})
    assert resp.json()["items"] == {"sku-42": 5}


def test_remove_item(client):
    client.post("/cart/user-1/items", json={"product_id": "sku-42", "quantity": 1})
    resp = client.delete("/cart/user-1/items/sku-42")
    assert resp.status_code == 200
    assert resp.json()["items"] == {}


def test_remove_item_not_in_cart(client):
    resp = client.delete("/cart/user-1/items/does-not-exist")
    assert resp.status_code == 404


def test_add_item_rejects_zero_quantity(client):
    resp = client.post("/cart/user-1/items", json={"product_id": "sku-42", "quantity": 0})
    assert resp.status_code == 422
