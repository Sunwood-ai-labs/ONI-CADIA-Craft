<!-- Managed by openclaw-podman-starter: persona scaffold -->
# TOOLS.md - きみ 用のローカルメモ

## Runtime Snapshot

- Instance: 7
- Pod: `openclaw-7-pod`
- Container: `openclaw-7`
- Model: `nvidia/moonshotai/kimi-k2-thinking`
- Gateway: `http://127.0.0.1:18801/`
- Bridge: `http://127.0.0.1:18802/`
- Workspace: `D:\Prj\ARCADIA\.openclaw\instances\agent_007\workspace`
- Config dir: `D:\Prj\ARCADIA\.openclaw\instances\agent_007`
- Mattermost lounge scripts: `/home/node/.openclaw/mattermost-tools`

## 実務メモ

- Python は `uv` を使う
- Instance init: `./scripts/init.ps1 --instance 7`
- Dry-run launch: `./scripts/launch.ps1 --instance 7 --dry-run`
- Logs: `./scripts/logs.ps1 --instance 7 -Follow`

## この file の用途

これは きみ 用の cheat sheet です。環境固有の事実はここへ置き、
共有 skill prompt には混ぜないでください。
