# 設定

## 主要な環境変数

- `OPENCLAW_IMAGE`: 実行する OpenClaw イメージ
- `OPENCLAW_PODMAN_PUBLISH_HOST`: 公開先ホストアドレス
- `OPENCLAW_OLLAMA_BASE_URL`: Ollama API エンドポイント
- `OPENCLAW_OLLAMA_MODEL`: 既定 Ollama モデル ID
- `OPENCLAW_SCALE_INSTANCE_ROOT`: 生成インスタンスのルート
- `OPENCLAW_SCALE_GATEWAY_PORT_START`: ゲートウェイ開始ポート
- `OPENCLAW_SCALE_BRIDGE_PORT_START`: ブリッジ開始ポート
- `OPENCLAW_SCALE_PORT_STEP`: インスタンスごとのポート増分

## エージェント向け調整

会話ラボ系の挙動を制御する変数:

- `OPENCLAW_MATTERMOST_ENABLED`
- `OPENCLAW_MATTERMOST_CHANNEL_NAME`
- `OPENCLAW_MATTERMOST_AUTONOMY_ENABLED`
- `OPENCLAW_MATTERMOST_AUTONOMY_INTERVAL`
- `OPENCLAW_MATTERMOST_AUTONOMY_INTERVAL_INSTANCE_00N`
- `OPENCLAW_MATTERMOST_AUTONOMY_MODEL`

チーム行動の大半は env ではなく workspace 側のスカフォールドで決まります。  
`.env` で基盤値を揃えた後、各 workspace の `SOUL.md` / `IDENTITY.md` / `USER.md` / `HEARTBEAT.md` を必要に応じて編集してください。

## Windows + WSL Podman の補足

検証時点の Windows + WSL Podman では以下を利用していました:

```text
http://172.27.208.1:11434
```

環境で `host.containers.internal` が Windows 側 Ollama へ届かない場合は、`.env` の `OPENCLAW_OLLAMA_BASE_URL` を適切な値に変更してください。

## 信頼境界

本プロジェクトは同一信頼前提の運用を想定しています。  
OpenClaw はコンテナ内のフルアクセスモードを前提とし、主な分離境界は Podman pod 自体で担保します。
