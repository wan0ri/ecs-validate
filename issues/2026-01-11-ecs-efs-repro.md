# 2026-01-11 ECS×EFS 検証ログ

## ブランチ

- feat/ecs-fargate-ap-repro-failure（タスク1）
- fix/security-egress-efs-mt-ips-32（タスク2）

## 事前設定

```bash
export AWS_PROFILE=wan0ri-admin
export AWS_REGION=ap-northeast-1
```

## タスク1: 失敗再現（抜粋）

### plan（Cluster/TaskDef/Service 追加）

- 期待: +3 create

### apply（ターゲット例）

```bash
terraform apply -var-file=envs/dev.tfvars -target=module.ecs_cluster -target=module.ecs_task_definition -target=module.ecs_service
```

### エラー確認（サービス/タスク）

```bash
aws ecs describe-services --cluster ecs-validate --services ap-repro --query 'services[0].events[0:10].[createdAt,message]' --output table
aws ecs list-tasks --cluster ecs-validate --service-name ap-repro --query 'taskArns' --output text
aws ecs wait tasks-stopped --cluster ecs-validate --tasks <TASK_ARN>
aws ecs describe-tasks --cluster ecs-validate --tasks <TASK_ARN> --query 'tasks[0].[lastStatus,stoppedReason,containers[0].reason]' --output table
```

- 実績: stoppedReason に `failed to invoke EFS utils ... code: 32` を確認

### 補助（logs 初期化エラー対応）

- `allow_https_egress=true` を security モジュールに付与

## タスク2: /32×MT で成功

### plan

- `/28` 削除、`/32`×2 追加（MT IP: `172.31.39.170`, `172.31.13.203`）

### apply（セキュリティのみ）

```bash
terraform apply -var-file=envs/dev.tfvars -target=module.security
```

### 再デプロイ

```bash
aws ecs update-service --cluster ecs-validate --service ap-repro --force-new-deployment
aws ecs wait services-stable --cluster ecs-validate --services ap-repro
```

### 稼働確認

```bash
TASK_ARN=$(aws ecs list-tasks --cluster ecs-validate --service-name ap-repro --query 'taskArns[0]' --output text)
aws ecs wait tasks-running --cluster ecs-validate --tasks "$TASK_ARN"
aws ecs describe-tasks --cluster ecs-validate --tasks "$TASK_ARN" --query 'tasks[0].[lastStatus,stoppedReason]' --output table
```

- 実績: RUNNING / None を確認

### CloudWatch Logs

```bash
TASK_ID=$(basename "$TASK_ARN")
aws logs get-log-events --log-group-name /ecs/ecs-validate --log-stream-name ecs/app/$TASK_ID --limit 50 --query 'events[*].message' --output text
```

- 実績: `start` と `ls -al /data` を確認

### SG ルール裏取り（記録）

```bash
aws ec2 describe-security-groups --group-ids sg-002d35e9af702fde5 --query 'SecurityGroups[0].IpPermissionsEgress[].{from:FromPort,to:ToPort,proto:IpProtocol,cidrs:IpRanges[].CidrIp}' --output table
```

- 実績:
  - 443/tcp → 0.0.0.0/0
  - 2049/tcp → 172.31.13.203/32, 172.31.39.170/32

## メモ

- `task_role_arn` 未指定だと TaskDef 登録時に EFS IAM 認可エラー
- JMESPath の数値リテラルはバッククォートで囲うと安全
