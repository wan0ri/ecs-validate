# コスト指針（最小構成）

- Fargate: 256/512, desired_count=1（検証時のみ）
- CloudWatch Logs: 保持 1 日
- 使い終わったら desired_count=0、または Service 削除
- EFS データは小容量（テストファイル程度）
