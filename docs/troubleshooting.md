# トラブルシューティング

awslogs 初期化エラー:
- 症状: ResourceInitializationError: failed to validate logger args ...
- 原因: 443/TCP のアウトバウンドが閉じている
- 対処: `allow_https_egress=true` を security モジュールに渡す

EFS マウント失敗（code:32/timeout）:
- 症状: failed to invoke EFS utils / mount.nfs4: mount system call failed
- 原因: ECS SG から EFS MT への 2049/TCP が閉じている
- 対処: `/28` から `/32×MT` へ置換、または最終的に SG 参照方式へ

TaskDef 登録時のエラー:
- 症状: EFS IAM authorization requires a task role.
- 原因: `authorization_config.iam = "ENABLED"` だが `task_role_arn` 未指定
- 対処: IAM モジュールで task role を作成し、`task_role_arn` を渡す

JMESPath での絞り込みが失敗する:
- 症状: invalid token（数値リテラル）
- 対処: 数値はバッククォートで囲む、または段階フィルタ `[?cond1][?cond2]` を使う
