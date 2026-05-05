<!-- Managed by openclaw-podman-starter: persona scaffold -->
# TOOLS.md - みにま 用のローカルメモ

## Runtime Snapshot

- Instance: 9
- Pod: `openclaw-9-pod`
- Container: `openclaw-9`
- Model: `nvidia/minimaxai/minimax-m2.5`
- Gateway: `http://127.0.0.1:18805/`
- Bridge: `http://127.0.0.1:18806/`
- Workspace: `D:\Prj\ARCADIA\.openclaw\instances\agent_009\workspace`
- Config dir: `D:\Prj\ARCADIA\.openclaw\instances\agent_009`
- Mattermost lounge scripts: `/home/node/.openclaw/mattermost-tools`

## 実務メモ

- Python は `uv` を使う
- Instance init: `./scripts/init.ps1 --instance 9`
- Dry-run launch: `./scripts/launch.ps1 --instance 9 --dry-run`
- Logs: `./scripts/logs.ps1 --instance 9 -Follow`

## この file の用途

これは みにま 用の cheat sheet です。環境固有の事実はここへ置き、
共有 skill prompt には混ぜないでください。
