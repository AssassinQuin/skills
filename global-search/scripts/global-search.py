#!/usr/bin/env python3
"""Global search skill script (Python stdlib only)."""

from __future__ import annotations

import json
import os
import sys
import time
from typing import Any, Dict, NoReturn
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

DEFAULT_BASE_URL = "https://developer.zhihu.com"
REQUEST_TIMEOUT_SECONDS = 5
ENV_FILE_CANDIDATES = [
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"),
    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), ".env"),
]


def load_env_file() -> None:
    """Populate os.environ from .env if a key is not already set.

    Supports both ZHIHU_ACCESS_SECRET (canonical) and zhihu_token (.env actual).
    """
    for path in ENV_FILE_CANDIDATES:
        if not os.path.exists(path):
            continue
        try:
            with open(path, "r", encoding="utf-8") as fh:
                for raw in fh:
                    line = raw.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    key, _, value = line.partition("=")
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    if key and key not in os.environ:
                        os.environ[key] = value
        except OSError:
            continue


def print_usage() -> None:
    print(
        "Usage:\n"
        "  python3 global-search.py "
        '\'{"query":"如何理解 rave 文化","count":8,"filter":"host==\\"example.com\\"","search_db":"all"}\'\n\n'
        "Environment:\n"
        "  ZHIHU_ACCESS_SECRET      Bearer auth token\n"
        "  ZHIHU_OPENAPI_BASE_URL   Optional, default https://developer.zhihu.com\n"
        "  ZHIHU_GLOBAL_SEARCH_URL  Optional full endpoint override\n"
    )


def die(message: str, *, body: Any | None = None) -> NoReturn:
    payload: Dict[str, Any] = {"error": message, "exit_code": 1}
    if body is not None:
        payload["body"] = body
    print(json.dumps(payload, ensure_ascii=False))
    raise SystemExit(1)


def parse_payload(raw: str) -> Dict[str, Any]:
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        die("Invalid JSON payload")
    if not isinstance(data, dict):
        die("Invalid JSON payload")
    return data


def parse_query(payload: Dict[str, Any]) -> str:
    query = payload.get("query") or payload.get("Query") or ""
    if not isinstance(query, str) or not query.strip():
        die("query is required")
    query = query.strip()
    return query


def parse_count(payload: Dict[str, Any]) -> int:
    raw = payload.get("count", payload.get("Count", 10))
    try:
        count = int(raw)
    except (TypeError, ValueError):
        count = 10
    return max(1, min(20, count))


def parse_filter(payload: Dict[str, Any]) -> str:
    raw = payload.get("filter", payload.get("Filter", ""))
    if raw is None:
        return ""
    if not isinstance(raw, str):
        die("filter must be a string")
    return raw.strip()


def parse_search_db(payload: Dict[str, Any]) -> str:
    raw = payload.get("search_db", payload.get("SearchDB", ""))
    if raw is None:
        return ""
    if not isinstance(raw, str):
        die("search_db must be a string")
    value = raw.strip().lower()
    if value and value not in {"all", "realtime", "static"}:
        die("search_db must be one of all, realtime, static")
    return value


def get_endpoint() -> str:
    explicit = os.getenv("ZHIHU_GLOBAL_SEARCH_URL", "").strip()
    if explicit:
        return explicit
    base_url = os.getenv("ZHIHU_OPENAPI_BASE_URL", DEFAULT_BASE_URL).strip()
    return f"{base_url.rstrip('/')}/api/v1/content/global_search"


def request_global_search(query: str, count: int, filter_expr: str, search_db: str) -> Dict[str, Any]:
    # 兼容两种命名：官方 ZHIHU_ACCESS_SECRET 或 .env 实际的 zhihu_token
    secret = (
        os.getenv("ZHIHU_ACCESS_SECRET", "").strip()
        or os.getenv("zhihu_token", "").strip()
    )
    if not secret:
        die(
            "Set ZHIHU_ACCESS_SECRET (or zhihu_token in ~/.claude/skills/.env) first (Bearer auth only)"
        )

    params_dict = {"Query": query, "Count": str(count)}
    if filter_expr:
        params_dict["Filter"] = filter_expr
    if search_db:
        params_dict["SearchDB"] = search_db
    params = urlencode(params_dict)
    url = f"{get_endpoint()}?{params}"
    req = Request(
        url=url,
        method="GET",
        headers={
            "Authorization": f"Bearer {secret}",
            "X-Request-Timestamp": str(int(time.time())),
        },
    )

    try:
        with urlopen(req, timeout=REQUEST_TIMEOUT_SECONDS) as resp:
            body_text = resp.read().decode("utf-8", errors="replace")
    except HTTPError as err:
        body_text = err.read().decode("utf-8", errors="replace")
        die(f"HTTP {err.code}", body=body_text)
    except (URLError, TimeoutError):
        die("HTTP request failed (timeout or network error)")

    try:
        return json.loads(body_text)
    except json.JSONDecodeError:
        die("Non-JSON response from API")


def normalize_items(api_resp: Dict[str, Any]) -> Dict[str, Any]:
    raw_data = api_resp.get("Data")
    data: Dict[str, Any] = raw_data if isinstance(raw_data, dict) else {}
    raw_items = data.get("Items")
    items = raw_items if isinstance(raw_items, list) else []
    normalized_items = []
    for item in items:
        if not isinstance(item, dict):
            continue
        normalized_items.append(
            {
                "title": item.get("Title", ""),
                "url": item.get("Url", ""),
                "author_name": item.get("AuthorName", ""),
                "summary": item.get("ContentText", ""),
                "edit_time": item.get("EditTime", 0),
            }
        )

    return {
        "code": api_resp.get("Code", -1),
        "message": api_resp.get("Message", ""),
        "item_count": len(normalized_items),
        "items": normalized_items,
    }


def main() -> None:
    load_env_file()
    if len(sys.argv) >= 2 and sys.argv[1] in {"-h", "--help"}:
        print_usage()
        return

    if len(sys.argv) < 2:
        print_usage()
        raise SystemExit(1)

    payload = parse_payload(sys.argv[1])
    query = parse_query(payload)
    count = parse_count(payload)
    filter_expr = parse_filter(payload)
    search_db = parse_search_db(payload)

    api_resp = request_global_search(query, count, filter_expr, search_db)
    result = normalize_items(api_resp)
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
