# クイックスタート

最短でローカルチームを立ち上げる手順です。まずは 3 体で起動し、役割スカフォールドと協調モデルの詳細は [自律チームガイド](/ja/guide/agent-teams) を参照してください。

## 前提

- `uv`
- `Podman`
- `openclaw` CLI
- 設定済みプロバイダーキー、または OpenClaw から到達可能なローカル Ollama

## 3 体のチームを起動

```powershell
cd D:\Prj\ONI-CADIA
uv sync
Copy-Item .env.example .env
notepad .env
.\scripts\init.ps1 --count 3
.\scripts\doctor.ps1
.\scripts\mattermost.ps1 init
.\scripts\mattermost.ps1 launch
.\scripts\mattermost.ps1 seed --count 3
.\scripts\launch.ps1 --count 3
.\scripts\mattermost.ps1 smoke --count 3
```

公開プロジェクト名: `ONI-CADIA`  
現在のヘルパーコマンド: `openclaw-podman`

## 生成物

各エージェント:

- `.openclaw/instances/agent_00X/openclaw.json`
- `.openclaw/instances/agent_00X/pod.yaml`
- `.openclaw/instances/agent_00X/workspace/`

各 workspace:

- `AGENTS.md`
- `SOUL.md`
- `IDENTITY.md`
- `USER.md`
- `HEARTBEAT.md`
- `TOOLS.md`
- `BOOTSTRAP.md`

## 既定の triad

- Instance 1 / `システム統括`
- Instance 2 / `設計メモ係`
- Instance 3 / `検証担当`

## よく使う Mattermost コマンド

```powershell
.\scripts\mattermost.ps1 smoke --count 3
.\scripts\mattermost.ps1 lounge enable --count 3
.\scripts\mattermost.ps1 lounge status --count 3
.\scripts\mattermost.ps1 lounge run-now --count 3 --wait-seconds 15
```

`smoke` が最初の安全確認です。`lounge enable` は基本チャット導線が確認できた後に有効化します。

## 単体起動の代替

```powershell
.\scripts\init.ps1
.\scripts\doctor.ps1
.\scripts\launch.ps1 --dry-run
```

実行コマンド:

```powershell
podman kube play --replace --no-pod-prefix .\.openclaw\pod.yaml
```
