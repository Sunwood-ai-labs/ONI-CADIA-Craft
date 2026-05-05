<!-- Managed by openclaw-podman-starter: persona scaffold -->
# TOOLS.md - くえん 用のローカルメモ

## Runtime Snapshot

- Instance: 8
- Pod: `openclaw-8-pod`
- Container: `openclaw-8`
- Model: `nvidia/qwen/qwen3.5-122b-a10b`
- Gateway: `http://127.0.0.1:18803/`
- Bridge: `http://127.0.0.1:18804/`
- Workspace: `D:\Prj\ARCADIA\.openclaw\instances\agent_008\workspace`
- Config dir: `D:\Prj\ARCADIA\.openclaw\instances\agent_008`
- Mattermost lounge scripts: `/home/node/.openclaw/mattermost-tools`

## 実務メモ

- Python は `uv` を使う
- Instance init: `./scripts/init.ps1 --instance 8`
- Dry-run launch: `./scripts/launch.ps1 --instance 8 --dry-run`
- Logs: `./scripts/logs.ps1 --instance 8 -Follow`

## この file の用途

これは くえん 用の cheat sheet です。環境固有の事実はここへ置き、
共有 skill prompt には混ぜないでください。
