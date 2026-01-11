# 段階適用（トグル運用）

- フラグ: `enable_iam`, `enable_logs`, `enable_efs`, `enable_security`, `enable_ecs`
- 推奨順序:
  1. IAM（タスク実行ロール）
  2. Logs（/ecs/ecs-validate, 保持1日）
  3. EFS（AP有効、MT作成）
  4. Security（ロックダウン＋443許可）
  5. ECS（Cluster → TaskDef → Service）

検証モード:

- 失敗再現: `allow_both_azs=false` で 1c に ECS を配置し、NFS 2049 を到達不能にする
- 改善確認: `/28` → `/32×MT` に置換して RUNNING を確認

注意点:

- awslogs 初期化には 443/TCP のアウトバウンドが必要（`allow_https_egress=true`）。
- Fargate は `awsvpc`、TaskDef に `task_role_arn` が必要（EFS IAM 認可時）。
