# タスク1: EFS マウント失敗の再現

目的:

- Fargate タスクを EFS にマウントさせる前提で、SG/サブネット条件により意図的に失敗させる。

前提:

- allow_both_azs=false（1a 側のみ /28 許可）
- Service は 1c のみのサブネットへ配置
- allow_https_egress=true（awslogs/ECR への到達確保）

主要コマンド:

- terraform plan/apply（ECS Cluster/TaskDef/Service）
- aws ecs describe-services / list-tasks / describe-tasks

期待結果（例）:

- stoppedReason: code:32 / mount timeout / failed to invoke EFS utils ...
- コンテナログは空の可能性あり（マウント前に停止）
