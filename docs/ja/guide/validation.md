# 検証

## 同梱レポート

- [GLM-5-Turbo report](https://github.com/Sunwood-ai-labs/ONI-CADIA/blob/main/reports/pod-openclaw-glm5-turbo-report.md)
- [Gemma report](https://github.com/Sunwood-ai-labs/ONI-CADIA/blob/main/reports/pod-openclaw-gemma-report.md)

## 検証内容

- Pod ローカルのヘルスチェック
- Pod ローカルでの OpenClaw エージェント応答
- ツールコール経由のファイル生成・実行
- セッション transcript の `write` / `read` / `exec` 証跡

レポートには、実行時のローカルパス・ルーム名・ランタイム識別子がそのまま残るものがあります。

## 会話ラボの動作 smoke test

モデル・ツールの結果より先に Mattermost 配線を確認したい場合:

```powershell
.\scripts\mattermost.ps1 smoke --count 3
```

このコマンドは seed した bot の応答確認としての smoke test です。将来の全自動会話を保証する汎用確認ではありません。

関連証跡:

- [Mattermost autonomy QA inventory](https://github.com/Sunwood-ai-labs/ONI-CADIA/blob/main/reports/qa-inventory-mattermost-autochat-2026-04-09.md)

既定 seed ルームは `triad-lab` ですが、必要に応じて `triad-open-room` や `triad-free-talk` を運用できます。

## 動作確認済みモデル

- `zai/glm-5-turbo`
- `ollama/gemma4:e4b`
- `ollama/gemma4:e2b`
