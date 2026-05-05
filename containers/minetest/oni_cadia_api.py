#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import secrets
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


BRIDGE_DIR = Path(os.environ.get("ONI_CADIA_BRIDGE_DIR", "/var/lib/minetest/.minetest/worlds/oni-cadia/oni-cadia-bridge"))
HOST = os.environ.get("ONI_CADIA_API_HOST", "0.0.0.0")
PORT = int(os.environ.get("ONI_CADIA_API_PORT", "30800"))


def actions_dir() -> Path:
    return BRIDGE_DIR / "actions"


def state_path() -> Path:
    return BRIDGE_DIR / "state.json"


def accounts_path() -> Path:
    return BRIDGE_DIR / "accounts.json"


def read_json(path: Path, fallback: dict[str, Any]) -> dict[str, Any]:
    if not path.exists():
        return fallback
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return fallback
    return payload if isinstance(payload, dict) else fallback


def read_accounts() -> dict[str, Any]:
    return read_json(accounts_path(), {"agents": {}})


def account_for(agent_id: int) -> dict[str, Any] | None:
    agents = read_accounts().get("agents")
    if not isinstance(agents, dict):
        return None
    account = agents.get(str(agent_id))
    return account if isinstance(account, dict) else None


def public_account(account: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": account.get("id"),
        "username": account.get("username"),
        "display_name": account.get("display_name"),
    }


def json_bytes(payload: dict[str, Any], status: int = 200) -> tuple[int, bytes]:
    return status, (json.dumps(payload, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def append_action(agent_id: int, account: dict[str, Any], action: dict[str, Any]) -> dict[str, Any]:
    actions_dir().mkdir(parents=True, exist_ok=True)
    payload = {
        "id": action.get("id") or f"{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}-{agent_id:03d}-{secrets.token_hex(4)}",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "agent_id": agent_id,
        "agent_name": account.get("display_name") or account.get("username") or f"agent_{agent_id:03d}",
        "agent_username": account.get("username") or f"agent_{agent_id:03d}",
        **action,
    }
    path = actions_dir() / f"agent_{agent_id:03d}.jsonl"
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n")
    return payload


class Handler(BaseHTTPRequestHandler):
    server_version = "ONI-CADIA-Minetest-API/1.0"

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"{self.address_string()} - {fmt % args}", flush=True)

    def send_json(self, payload: dict[str, Any], status: int = 200) -> None:
        code, body = json_bytes(payload, status)
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def read_body(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0") or "0")
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        payload = json.loads(raw.decode("utf-8"))
        if not isinstance(payload, dict):
            raise ValueError("request body must be a JSON object")
        return payload

    def authenticate(self, agent_id: int) -> dict[str, Any] | None:
        account = account_for(agent_id)
        if not account:
            self.send_json({"error": "unknown agent account"}, HTTPStatus.NOT_FOUND)
            return None
        expected = str(account.get("token", ""))
        supplied = self.headers.get("X-ONI-Agent-Token", "")
        if not expected or not secrets.compare_digest(expected, supplied):
            self.send_json({"error": "invalid agent token"}, HTTPStatus.UNAUTHORIZED)
            return None
        return account

    def do_GET(self) -> None:
        path = urlparse(self.path).path.strip("/")
        if path == "health":
            self.send_json({"ok": True})
            return
        if path == "state":
            self.send_json(read_json(state_path(), {"agents": {}, "chat_log": [], "processed_count": 0}))
            return
        if path == "agents":
            agents = read_accounts().get("agents")
            public = {}
            if isinstance(agents, dict):
                for key, account in agents.items():
                    if isinstance(account, dict):
                        public[key] = public_account(account)
            self.send_json({"agents": public})
            return
        self.send_json({"error": "not found"}, HTTPStatus.NOT_FOUND)

    def do_POST(self) -> None:
        path_parts = [part for part in urlparse(self.path).path.split("/") if part]
        if len(path_parts) == 3 and path_parts[0] == "agents" and path_parts[2] == "actions":
            try:
                agent_id = int(path_parts[1])
            except ValueError:
                self.send_json({"error": "invalid agent id"}, HTTPStatus.BAD_REQUEST)
                return
            account = self.authenticate(agent_id)
            if account is None:
                return
            try:
                action = self.read_body()
            except (json.JSONDecodeError, ValueError) as exc:
                self.send_json({"error": str(exc)}, HTTPStatus.BAD_REQUEST)
                return
            kind = str(action.get("action") or action.get("type") or "").strip()
            if kind not in {"say", "move", "mine", "build"}:
                self.send_json({"error": "action must be say, move, mine, or build"}, HTTPStatus.BAD_REQUEST)
                return
            queued = append_action(agent_id, account, {"action": kind, **action})
            self.send_json({"queued": queued}, HTTPStatus.ACCEPTED)
            return
        self.send_json({"error": "not found"}, HTTPStatus.NOT_FOUND)


def main() -> int:
    BRIDGE_DIR.mkdir(parents=True, exist_ok=True)
    actions_dir().mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"ONI-CADIA Minetest API listening on {HOST}:{PORT} bridge={BRIDGE_DIR}", flush=True)
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
