<!-- Managed by openclaw-podman-starter: persona scaffold -->
# TOOLS.md - くえん 用のローカルメモ

## Runtime Snapshot

- Instance: 8
- Pod: `openclaw-8-pod`
- Container: `openclaw-8`
- Model: `zai/glm-5.1`
- Gateway: `http://127.0.0.1:28803/`
- Bridge: `http://127.0.0.1:28804/`
- Workspace: `/home/maki/codex-workspace/ONI-CADIA-Craft/.openclaw/instances/agent_008/workspace`
- Config dir: `/home/maki/codex-workspace/ONI-CADIA-Craft/.openclaw/instances/agent_008`
- Minetest/Luanti action scripts: `/home/node/.openclaw/minetest-tools`
- Minetest/Luanti API: `$OPENCLAW_MINETEST_API_BASE_URL`

## 実務メモ

- Python は `uv` を使う
- Instance init: `./scripts/init.ps1 --instance 8`
- Dry-run launch: `./scripts/launch.ps1 --instance 8 --dry-run`
- Logs: `./scripts/logs.ps1 --instance 8 -Follow`

## Minetest / Luanti 国土チャット

会話は Mattermost ではなく Minetest/Luanti 内で行います。自分の agent API account と token で、国土チャット・移動・建築を 1 アクションずつ置けます。
それぞれの agent は独立した API account を持ち、同じ ONI-CADIA Minetest API を通じて国土へ反映されます。

- 状態とチャット確認: `python3 /home/node/.openclaw/minetest-tools/get_state.py`
- 発言: `python3 /home/node/.openclaw/minetest-tools/act.py say --message "広場に灯りを置きます"`
- 移動: `python3 /home/node/.openclaw/minetest-tools/act.py move --direction east --steps 3`
- 建築: `python3 /home/node/.openclaw/minetest-tools/act.py build --shape house --material wood --label "くえん の工房"`

1 回の会話で無理に大量建築しないでください。小さな一手を置き、Minetest の国土チャットで自然に話します。

## この file の用途

これは くえん 用の cheat sheet です。環境固有の事実はここへ置き、
共有 skill prompt には混ぜないでください。
