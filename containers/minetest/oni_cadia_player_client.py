#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import signal
import subprocess
import time
from pathlib import Path
from typing import Any


BRIDGE_DIR = Path(os.environ.get("ONI_CADIA_BRIDGE_DIR", "/var/lib/minetest/.minetest/worlds/oni-cadia/oni-cadia-bridge"))
SERVER_ADDRESS = os.environ.get("ONI_CADIA_SERVER_ADDRESS", "127.0.0.1")
SERVER_PORT = os.environ.get("ONI_CADIA_SERVER_PORT", "30000")
AGENT_ID = int(os.environ.get("ONI_CADIA_AGENT_ID", "0") or "0")

stop_requested = False


def handle_stop(signum: int, frame: object) -> None:
    del signum, frame
    global stop_requested
    stop_requested = True


def read_accounts() -> dict[str, Any]:
    path = BRIDGE_DIR / "accounts.json"
    return json.loads(path.read_text(encoding="utf-8"))


def account_for(agent_id: int) -> dict[str, Any]:
    agents = read_accounts().get("agents", {})
    account = agents.get(str(agent_id))
    if not isinstance(account, dict):
        raise SystemExit(f"missing account for agent {agent_id}")
    return account


def write_runtime_files(account: dict[str, Any]) -> tuple[Path, Path]:
    runtime_dir = Path("/tmp") / f"oni-cadia-agent-{AGENT_ID:03d}"
    runtime_dir.mkdir(parents=True, exist_ok=True)
    password_file = runtime_dir / "password"
    config_file = runtime_dir / "luanti.conf"
    password_file.write_text(str(account["token"]), encoding="utf-8")
    password_file.chmod(0o600)
    config_file.write_text(
        "\n".join(
            [
                "enable_sound = false",
                "fps_max = 5",
                "wanted_fps = 5",
                "viewing_range = 24",
                "enable_particles = false",
                "enable_clouds = false",
                "screen_w = 640",
                "screen_h = 480",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return password_file, config_file


def launch_once(account: dict[str, Any]) -> int:
    username = str(account["username"])
    password_file, config_file = write_runtime_files(account)
    log_file = Path("/tmp") / f"oni-cadia-agent-{AGENT_ID:03d}.log"
    env = os.environ.copy()
    env["LIBGL_ALWAYS_SOFTWARE"] = "1"
    env["MESA_GL_VERSION_OVERRIDE"] = "3.3"
    command = [
        "xvfb-run",
        "-a",
        "-s",
        "-screen 0 640x480x24 +extension GLX +render -noreset",
        "luanti",
        "--go",
        "--address",
        SERVER_ADDRESS,
        "--port",
        SERVER_PORT,
        "--name",
        username,
        "--password-file",
        str(password_file),
        "--config",
        str(config_file),
        "--logfile",
        str(log_file),
    ]
    print(f"starting Luanti client agent={AGENT_ID} username={username} server={SERVER_ADDRESS}:{SERVER_PORT}", flush=True)
    process = subprocess.Popen(command, env=env)
    while process.poll() is None:
        if stop_requested:
            process.terminate()
            try:
                return process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                return process.wait()
        time.sleep(1)
    return process.returncode or 0


def main() -> int:
    if AGENT_ID <= 0:
        raise SystemExit("ONI_CADIA_AGENT_ID must be set")
    signal.signal(signal.SIGTERM, handle_stop)
    signal.signal(signal.SIGINT, handle_stop)
    while not stop_requested:
        try:
            account = account_for(AGENT_ID)
            code = launch_once(account)
            print(f"Luanti client exited agent={AGENT_ID} code={code}", flush=True)
        except Exception as exc:
            print(f"Luanti client failed agent={AGENT_ID}: {exc}", flush=True)
        if not stop_requested:
            time.sleep(5)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
