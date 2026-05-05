# AGENTS.md

## Git Discipline

- Codex はこのリポジトリでコード・設定・ドキュメントの有意な変更を行ったら、作業単位ごとに `git status` で差分を確認し、secret や runtime state を除外してコミットし、可能なら即座に `git push` してください。
- コミットまたはプッシュできない場合は、理由と未反映の差分をユーザーに明示してください。
- `.env`、API key、token、DB、log、world data、runtime state はコミットしないでください。
