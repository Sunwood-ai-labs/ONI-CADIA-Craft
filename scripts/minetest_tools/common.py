from __future__ import annotations

import argparse
import json
import os
import secrets
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib import error as urllib_error
from urllib import request as urllib_request


DEFAULT_BRIDGE_DIR = Path(os.environ.get("OPENCLAW_MINETEST_BRIDGE_DIR", "/home/node/.openclaw/minetest-bridge"))
CONFIG_DIR = Path("/home/node/.openclaw")
CONTROL_ENV_PATH = CONFIG_DIR / "control.env"
STATE_ENV_PATH = CONFIG_DIR / ".env"

PERSONAS = {
    1: "いおり",
    2: "つむぎ",
    3: "さく",
    4: "るり",
    5: "ひびき",
    6: "かなえ",
    7: "きみ",
    8: "くえん",
    9: "みにま",
}


def parse_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def runtime_env_values() -> dict[str, str]:
    return {**parse_env_file(STATE_ENV_PATH), **parse_env_file(CONTROL_ENV_PATH), **os.environ}


def api_base_url_from_args(args: argparse.Namespace) -> str:
    env = runtime_env_values()
    return (getattr(args, "api_base_url", "") or env.get("OPENCLAW_MINETEST_API_BASE_URL", "")).strip().rstrip("/")


def agent_token_from_args(args: argparse.Namespace) -> str:
    env = runtime_env_values()
    return (getattr(args, "agent_token", "") or env.get("OPENCLAW_MINETEST_AGENT_TOKEN", "")).strip()


def instance_from_args(args: argparse.Namespace) -> int:
    instance = int(getattr(args, "instance", 0) or 0)
    if instance > 0:
        return instance
    env_value = runtime_env_values().get("OPENCLAW_MINETEST_AGENT_ID", "").strip()
    return int(env_value or "0")


def bridge_dir_from_args(args: argparse.Namespace) -> Path:
    return Path(args.bridge_dir or DEFAULT_BRIDGE_DIR).expanduser().resolve()


def actions_dir(bridge_dir: Path) -> Path:
    return bridge_dir / "actions"


def state_path(bridge_dir: Path) -> Path:
    return bridge_dir / "state.json"


def chat_path(bridge_dir: Path) -> Path:
    return bridge_dir / "chat.jsonl"


def agent_name(instance_id: int, override: str | None = None) -> str:
    if override:
        return override
    return PERSONAS.get(instance_id, f"agent_{instance_id:03d}")


def append_action(bridge_dir: Path, instance_id: int, action: dict[str, Any]) -> dict[str, Any]:
    actions_dir(bridge_dir).mkdir(parents=True, exist_ok=True)
    payload = {
        "id": action.get("id") or f"{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}-{instance_id:03d}-{secrets.token_hex(4)}",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "agent_id": instance_id,
        "agent_name": agent_name(instance_id, str(action.get("agent_name") or "") or None),
        **action,
    }
    path = actions_dir(bridge_dir) / f"agent_{instance_id:03d}.jsonl"
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n")
    return payload


def api_request(
    method: str,
    path: str,
    *,
    base_url: str,
    token: str = "",
    payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    if not base_url:
        raise SystemExit("OPENCLAW_MINETEST_API_BASE_URL is not set.")
    body = None
    headers = {"Accept": "application/json"}
    if payload is not None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json; charset=utf-8"
    if token:
        headers["X-ONI-Agent-Token"] = token
    request = urllib_request.Request(
        f"{base_url}{path}",
        data=body,
        headers=headers,
        method=method,
    )
    try:
        with urllib_request.urlopen(request, timeout=30) as response:
            raw = response.read().decode("utf-8")
    except urllib_error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Minetest API returned HTTP {exc.code}: {detail}") from exc
    except urllib_error.URLError as exc:
        raise SystemExit(f"Minetest API request failed: {exc}") from exc
    try:
        data = json.loads(raw or "{}")
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Minetest API returned non-JSON: {raw}") from exc
    if not isinstance(data, dict):
        raise SystemExit("Minetest API returned a non-object JSON payload.")
    return data


def read_state(bridge_dir: Path) -> dict[str, Any]:
    path = state_path(bridge_dir)
    if not path.exists():
        return {
            "updated_at": "",
            "processed_count": 0,
            "agents": {},
            "chat_log": [],
            "last_action": None,
        }
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Minetest state is not valid JSON: {path} ({exc})") from exc
    if not isinstance(data, dict):
        raise SystemExit(f"Minetest state is not a JSON object: {path}")
    return data


def read_state_via_api(args: argparse.Namespace) -> dict[str, Any]:
    return api_request("GET", "/state", base_url=api_base_url_from_args(args))


def append_action_via_api(args: argparse.Namespace, action: dict[str, Any]) -> dict[str, Any]:
    instance_id = instance_from_args(args)
    if instance_id <= 0:
        raise SystemExit("--instance or OPENCLAW_MINETEST_AGENT_ID is required.")
    payload = api_request(
        "POST",
        f"/agents/{instance_id}/actions",
        base_url=api_base_url_from_args(args),
        token=agent_token_from_args(args),
        payload=action,
    )
    queued = payload.get("queued")
    if not isinstance(queued, dict):
        raise SystemExit(f"Minetest API did not return queued action: {payload}")
    return queued


def print_json(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, ensure_ascii=False, indent=2))
