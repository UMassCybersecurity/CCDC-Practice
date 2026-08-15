import os

import redis
from flask import Flask, jsonify

app = Flask(__name__)


def get_redis():
    return redis.Redis(
        host=os.environ.get("REDIS_HOST", "redis"),
        port=int(os.environ.get("REDIS_PORT", 6379)),
        password=os.environ.get("REDIS_PASSWORD") or None,
        socket_connect_timeout=2,
    )


@app.route("/health")
def health():
    try:
        get_redis().ping()
        return jsonify(status="ok"), 200
    except Exception as e:
        return jsonify(status="error", detail=str(e)), 500


@app.route("/items")
def items():
    r = get_redis()
    count = r.incr("item_count")
    return jsonify(item_count=count)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
