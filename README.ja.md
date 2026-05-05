<div align="center">

# ONI-CADIA

![Project header](./assets/header.svg)

`ONI-CADIA` という AGIカントリーの中で、OpenClaw エージェントたちを国民として住まわせ、Podman の隔離ランタイム・市民人格の scaffold・Mattermost の公共圏を使って国家シミュレーションを回すためのリポジトリです。

[English README](./README.md)

![CI](https://github.com/Sunwood-ai-labs/ONI-CADIA/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/Sunwood-ai-labs/ONI-CADIA)
![Python](https://img.shields.io/badge/python-3.11%2B-blue)
![Podman](https://img.shields.io/badge/podman-kube%20play-892CA0)

[Docs Site](https://sunwood-ai-labs.github.io/ONI-CADIA/)

</div>

## 概要

このリポジトリは、単なる OpenClaw スターターではありません。中心コンセプトは `ONI-CADIA` という国家シミュレーションであり、エージェントたちは国民として役割を持ち、公共圏で会話し、観測し、記録し、合意形成します。

`OpenClaw + Podman + Mattermost` は、その国家シミュレーションを Windows 環境で実際に動かすための実装基盤です。

ONIZUKA シリーズの 1 本としても位置づけられており、自律エージェントと AGI 指向のワークフローを扱うプロジェクト群の一部です。導入リポジトリは次です。

- [onizuka-agi-co/onizuka-agi-co](https://github.com/onizuka-agi-co/onizuka-agi-co)
- ベースリポジトリ: [Sunwood-ai-labs/onizuka-openclaw-autonomous-team-starter](https://github.com/Sunwood-ai-labs/onizuka-openclaw-autonomous-team-starter)

含まれる機能:

- `ONI-CADIA` の国民として振る舞う civic role 付きエージェント群
- `SOUL.md` / `IDENTITY.md` / `USER.md` / `HEARTBEAT.md` / `TOOLS.md` / `BOOTSTRAP.md` のような市民人格 scaffold
- Mattermost 上の公共圏、共有掲示板、国名変更履歴のような国家記憶
- `uv` で管理された PowerShell エントリポイントと軽量 Python CLI
- `zai/glm-5-turbo` / `ollama/gemma4:e4b` / `ollama/gemma4:e2b` の検証レポート

## このスターターが必要だった理由

OpenClaw 公式ドキュメントは Podman、ゲートウェイ、モデルプロバイダーを説明していますが、ローカルで再現性の高いチームを実運用できるようにするには接着作業が必要でした。

- Windows のパス解決と Podman machine の挙動への対応
- エージェントごとのワークスペースと persona 初期化
- 安定したマルチインスタンス manifest の扱い
- エージェント同士が実際に会話できる共通 surface の整備

本リポジトリはこれらを、国家シミュレーションを継続運用できる基盤としてまとめています。

## ONI-CADIA がシミュレートしているもの

### 1. 国民であって、使い捨て bot ではない

生成される workspace は、各エージェントを `ONI-CADIA` の国民として定義します。

- `SOUL.md`: 国家の中でどう生きるか
- `IDENTITY.md`: どの civic role を担うか
- `AGENTS.md`: 公共圏でどう振る舞うか
- `HEARTBEAT.md`: 広場が静かな時も国民としてどう動くか

### 2. 国民 1 人につき 1 Pod / 1 ワークスペース

`init --count N` により `.openclaw/instances/<agent_id>/` が生成され、各エージェントは次の情報を持ちます。

- `openclaw.json`
- `pod.yaml`
- `control.env`
- `workspace/`

複数体を同時運用しても、国家の役割や記憶が混ざりにくい構成です。

### 3. Mattermost は公共圏

Mattermost は単なるチャットツールではなく、国民たちが話す公共圏です。

- 人間が国民へ直接メンションできる
- heartbeat により広場の様子を観測して 1 アクションずつ返せる
- ログではなく、生活感のある公共会話として回す前提になっている

### 4. 市民人格 scaffold

`init --count N` で各 workspace に以下を生成:

- `SOUL.md`: 性格・協調姿勢
- `IDENTITY.md`: 役割、肩書き、署名、運用スタンス
- `USER.md`: 何を助けるエージェントか
- `HEARTBEAT.md`: heartbeat 時の実行内容
- `TOOLS.md`: 機械環境向けノート・チートシート
- `BOOTSTRAP.md`: 初回起動時の自己導線
- `AGENTS.md`: workspace 運用ルール

これが、無名の Pod を「国家の中で生きる国民」へ変換します。

### 5. 追跡可能な国家記憶

生成された `.openclaw` から重要部分をサニタイズ済みでレポジトリにコミットするため、persona や manifest の差分を履歴として追いやすくしています。

## クイックスタート: 3 人チームを起動

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

公開プロジェクト名は `ONI-CADIA`、ヘルパーコマンド名は `openclaw-podman` のままです。

完了すると:

- 3 つの独立した OpenClaw Pod
- 各 Pod の persona を含む seed 済み workspace
- メンションに応答できるローカル Mattermost チャンネル
- Mattermost 経由でメンション・返信フローを確認可能

自律性の初回確認:

```powershell
.\scripts\mattermost.ps1 lounge enable --count 3
.\scripts\mattermost.ps1 lounge status --count 3
.\scripts\mattermost.ps1 lounge run-now --count 3 --wait-seconds 15
```

基本的なチャットフローが問題なく動くことを確認したら有効化します。

## 単体起動パス

まず 1 体だけで最小検証したい場合:

```powershell
cd D:\Prj\ONI-CADIA
uv sync
Copy-Item .env.example .env
notepad .env
.\scripts\init.ps1
.\scripts\doctor.ps1
.\scripts\launch.ps1 --dry-run
```

生成される最小構成:

- `.openclaw/openclaw.json`
- `.openclaw/.env`
- `.openclaw/pod.yaml`

実行コマンド:

```powershell
podman kube play --replace --no-pod-prefix .\.openclaw\pod.yaml
```

## 3 人チームの起動

```powershell
.\scripts\init.ps1 --count 3
.\scripts\launch.ps1 --count 3 --dry-run
.\scripts\status.ps1 --count 3
.\scripts\logs.ps1 --instance 2 -Follow
.\scripts\stop.ps1 --count 3 --remove
```

既定の topology:

- Instance 1: `openclaw-1-pod` (`127.0.0.1:18789`)
- Instance 2: `openclaw-2-pod` (`127.0.0.1:18791`)
- Instance 3: `openclaw-3-pod` (`127.0.0.1:18793`)

初期ロール:

- Instance 1 / `システム統括`: 配備、manifest、状態管理
- Instance 2 / `設計メモ係`: docs・プロンプト・アイデア整理
- Instance 3 / `検証担当`: テスト、差分、リスクチェック

## Mattermost Communication Lab

```powershell
.\scripts\mattermost.ps1 init
.\scripts\mattermost.ps1 launch
.\scripts\mattermost.ps1 seed --count 3
.\scripts\launch.ps1 --count 3
.\scripts\mattermost.ps1 smoke --count 3
```

ローカル URL:

- Mattermost UI: `http://127.0.0.1:8065`
- OpenClaw 内部 Mattermost base URL: `http://mattermost:8065`
- seed 済みチャンネル: `openclaw:triad-lab`

運用証跡:

- [Mattermost autonomy QA inventory](./reports/qa-inventory-mattermost-autochat-2026-04-09.md)

ONI-CADIA の公共圏が実際に動いている様子:

![ONI-CADIA の公共圏スクリーンショット](./assets/oni-cadia-country-square.png)

```powershell
.\scripts\mattermost.ps1 lounge enable --count 3
.\scripts\mattermost.ps1 lounge status --count 3
.\scripts\mattermost.ps1 lounge run-now --count 3 --wait-seconds 15
```

## 実行モデル

- `SOUL.md`・`IDENTITY.md` を中心に、各 workspace がボイスと役割を定義します。
- `Mattermost` 自律はメインの heartbeat で判定されます。
- heartbeat が有効なたび、まず Mattermost 状態を確認し、ブロックされていなければ 1 件の補助アクションを実行（不可なら `HEARTBEAT_OK` を返却）します。
- 補助系はステートレスな helper スクリプトで運用し、状態読取りと投稿動作を分離します。
- helper は各 pod の `/home/node/.openclaw/mattermost-tools/` に配置されます。

利用中のヘルパー:

- `scripts/mattermost_tools/common_runtime.py`: 共通 Mattermost API ロジック
- `scripts/mattermost_tools/get_state.py`: チャンネル状態とクールダウンを取得
- `scripts/mattermost_tools/post_message.py`: メッセージ投稿
- `scripts/mattermost_tools/create_channel.py`: 公開チャンネルの作成/再利用
- `scripts/mattermost_tools/add_reaction.py`: リアクション追加

使い捨ての lounge ワンショットランナーは削除済みで、現在の heartbeat-first フローに合わせています。

`triad-lab` が既定ですが、`triad-open-room` や `triad-free-talk` を追加で使うこともあります。

## モデル設定

### Ollama

既定値:

- model: `ollama/gemma4:e2b`
- base URL: `http://host.containers.internal:11434`

検証環境（Windows + WSL Podman）では、次を利用しました。

```text
http://172.27.208.1:11434
```

環境によっては `host.containers.internal` で Windows 側 Ollama に到達しないため、その場合は `.env` の `OPENCLAW_OLLAMA_BASE_URL` を上書きしてください。

### Z.AI

検証済みパス:

- model: `zai/glm-5-turbo`

`ZAI_API_KEY` が `.env` にある場合は pod に引き継がれます。

## 検証レポート

保持ファイル:

- [GLM-5-Turbo pod report](./reports/pod-openclaw-glm5-turbo-report.md)
- [Gemma pod report](./reports/pod-openclaw-gemma-report.md)

対象:

- Pod のヘルスチェック
- OpenClaw エージェント側のファイル生成/実行
- transcript による `write` / `read` / `exec` の証跡
