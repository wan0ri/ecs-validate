# タスク2: /28 → /32×MT で成功へ

変更点:

- `module "security"` に以下を追加。

```bash
use_efs_mt_ips = true
efs_mt_ips      = module.efs[0].mount_target_ips
```

検証手順:

1. terraform plan で /28 削除 → /32×MT 追加を確認
2. terraform apply -target=module.security で最小適用
3. aws ecs update-service --force-new-deployment
4. services-stable / tasks-running 待機 → RUNNING を確認
5. CloudWatch Logs に `start` と `ls -al /data` が出力されること

裏取り:

- SG 2049/TCP の宛先が `x.x.x.x/32`（MT IP）であること
