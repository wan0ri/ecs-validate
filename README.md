# ECS 検証

## 検証の目的

- ECS タスクが EFS に接続する際、AZ ごとのマウントターゲット IP に依存する挙動を確認
- SG のアウトバウンド設定を片側のみ許可した場合に接続失敗することを再現
- 正しい SG 設定で改善することを確認

## 構成図

## リソース構成

```bash
repo/
├── app/                          # コンテナ（EFS書き込みの簡易検証）
│   ├── Dockerfile
│   ├── entrypoint.sh      # このスクリプトの役割は、EFS が正しくマウントされているか確認し、テスト用のファイルを書き込むこと
│   └── README.md
│
├── infra/                        # Terraform（モジュール分割）
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── main.tf                   # ルートでモジュールを結線
│   ├── envs/
│   │   └── dev.tfvars
│   └── modules/
│       ├── network/              # デフォルトVPC＋AZ別サブネット抽出
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── security/             # SG（ロックダウン切替あり）
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── efs/                  # EFS＋マウントターゲット
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── ecs/                  # Cluster / TaskDef / Service（EFSマウント）
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── iam/                  # Task Execution Role
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── logs/                 # CloudWatch Logs
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── ecr/                  # （任意）ECRリポジトリ
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── oidc/                 # GitHub OIDC Provider＋AssumeRole
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
│
└── .github/
    └── workflows/
        ├── ci.yml                # Docker Build & (optional) Push
        └── deploy.yml            # Terraform Apply + ECS Deploy
```

### 各モジュールの責務と入出力

#### modules/network

- 目的: デフォルト VPC と ap-northeast-1a/1c のサブネット ID・CIDR を抽出（自動検出）
- 入力: region
- 出力: vpc_id, subnet_a_id, subnet_c_id, subnet_a_cidr, subnet_c_cidr, ecs_subnet_ids
- 備考: デフォルトサブネットが 2AZ 分無い場合は null になり得るので、ルートで検査可能に

#### modules/security

- 目的: SG を作成（ECS 用 SG・EFS 用 SG）。EFS SG のインバウンドは ECS SG 参照、ECS SG のアウトバウンドは変数で切替
- 入力:
  - vpc_id
  - lockdown_mode（false=all egress, true=2049 のみ）
  - allow_both_azs（true=両 AZ CIDR、false=片側のみ）
  - cidrs_allowed（lockdown_mode=true 時に使用する CIDR 配列）
- 出力: ecs_sg_id, efs_sg_id

#### modules/efs

- 目的: EFS 本体＋各 AZ のマウントターゲット（ENI）を作成
- 入力: subnet_a_id, subnet_c_id, efs_sg_id, tags
- 出力: efs_id

#### modules/iam

- 目的: ECS タスク実行ロール（AmazonECSTaskExecutionRolePolicy のみ）
- 入力: tags
- 出力: task_execution_role_arn, task_execution_role_name

#### modules/logs

- 目的: CloudWatch Logs のグループ（短期保持）
- 入力: region, retention_in_days, name, tags
- 出力: log_group_name

#### modules/ecs

- 目的: ECS クラスタ、タスク定義（EFS マウントあり）、サービス（Fargate）
- 入力:
  - cluster_name
  - subnet_ids, ecs_sg_id
  - task_execution_role_arn, log_group_name, region
  - efs_id（efs_volume_configuration で参照）
  - assign_public_ip（初回は true 推奨）
  - cpu, memory（デフォルト: 256/512）
- 出力: cluster_id, service_name, task_definition_arn

---

## コスト最適化のポイント

- 無料枠を活用（ECS Fargate、EFS、VPC は無料枠あり）
- 最小構成で OK（1 タスク、1EFS、デフォルト VPC）
- 短時間で削除（課金は時間単位なので、検証後すぐ削除）

## 構成案（Terraform で構築）

### 1. VPC / Subnet

- デフォルト VPC を利用（新規作成不要）
- サブネットは ap-northeast-1a と ap-northeast-1c の 2 つを使用（既存のデフォルトサブネットで OK）

### 2. EFS

- 1 つの EFS ファイルシステム
- 各 AZ に マウントターゲットを作成（デフォルト VPC のサブネットに配置）
- SG を作成し、インバウンド：2049/TCP ECS タスク SG から許可

### 3. ECS

- Fargate タスク（最小サイズ）
  - CPU: 0.25 vCPU
  - メモリ: 512MB
- タスク定義
  - コンテナイメージ：amazonlinux または busybox（軽量）
  - コマンド：sleep 3600（検証用に起動し続ける）
- EFS ボリュームをタスクにマウント
  - efsVolumeConfiguration で EFS を指定

### 4. SG

- ECS タスク用 SG
  - アウトバウンド：最初は 片側 AZ の CIDR のみ許可（例：10.24.96.0/23）
  - 検証後、もう片側 CIDR を追加して改善確認
- EFS 用 SG
  - インバウンド：2049/TCP ECS タスク SG から許可

## コスト見積り（東京リージョン）
