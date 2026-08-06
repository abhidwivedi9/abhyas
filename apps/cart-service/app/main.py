"""cart-service — shopping cart API for Sachid Aquatics.

Redis-backed on purpose (per ADR-0004): teaches cache/session-store
operational patterns (connection handling, TTLs, cache-stampede scenarios
in later milestones) that an in-memory-only service wouldn't surface.
"""
from __future__ import annotations

import os
import time

import redis
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
CART_TTL_SECONDS = int(os.environ.get("CART_TTL_SECONDS", "3600"))

app = FastAPI(title="cart-service", version="0.1.0")
r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True, socket_connect_timeout=2)


class CartItem(BaseModel):
    product_id: str = Field(..., min_length=1)
    quantity: int = Field(..., gt=0)


def cart_key(user_id: str) -> str:
    return f"cart:{user_id}"


@app.get("/health")
def health():
    # A real check, not a cosmetic one: liveness of THIS process is not
    # useful if it can't reach the store it depends on to do its job —
    # same lesson as Milestone 1's disk-full scenario, one layer up.
    try:
        r.ping()
    except redis.RedisError:
        raise HTTPException(status_code=503, detail="redis unreachable")
    return {"status": "ok"}


@app.get("/cart/{user_id}")
def get_cart(user_id: str):
    items = r.hgetall(cart_key(user_id))
    return {"user_id": user_id, "items": {k: int(v) for k, v in items.items()}}


@app.post("/cart/{user_id}/items")
def add_item(user_id: str, item: CartItem):
    key = cart_key(user_id)
    r.hincrby(key, item.product_id, item.quantity)
    r.expire(key, CART_TTL_SECONDS)
    return {"user_id": user_id, "items": {k: int(v) for k, v in r.hgetall(key).items()}}


@app.delete("/cart/{user_id}/items/{product_id}")
def remove_item(user_id: str, product_id: str):
    key = cart_key(user_id)
    removed = r.hdel(key, product_id)
    if not removed:
        raise HTTPException(status_code=404, detail="item not in cart")
    return {"user_id": user_id, "items": {k: int(v) for k, v in r.hgetall(key).items()}}


@app.get("/")
def root():
    return {"service": "cart-service", "time": time.time()}
