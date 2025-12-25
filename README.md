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
  - アウトバウンド：最初は 片側 AZ のみ許可（できるだけ狭い CIDR）。例: 10.0.0.0/28
    - 検証用の意図: 1AZ 側の EFS マウントターゲットへは到達できるが、もう片側へは到達できず失敗を再現
    - 後段で、マウントターゲットの実 IP(/32)に自動で狭める方式へ移行予定（Terraform で取得した IP で SG を生成）
  - 検証後、もう片側 AZ も許可、または SG 参照方式（ECS SG → EFS SG 2049/TCP）に切り替えて改善確認
- EFS 用 SG
  - インバウンド：2049/TCP ECS タスク SG から許可（SG 参照。CIDR は不要）

## CIDR ポリシーの見直し（範囲を狭くする方針）

- 初期再現フェーズ：片側 AZ のみ到達可能にするため、もう片側 AZ の CIDR を許可しない。
  - 例（仮）: `10.0.0.0/28` など小さなブロックで許可（あくまで検証用。実 IP と一致しないと到達不可のため、後で見直し）
- 改善フェーズ：Terraform で EFS マウントターゲットのプライベート IP を取得し、`/32` で ECS SG のアウトバウンドを生成。
  - これにより最小限の到達範囲（1 ホスト単位）まで狭められる。
- 最終形（推奨）：CIDR ではなく SG 参照（ECS SG → EFS SG 2049/TCP）。
  - EFS SG 側はインバウンド 2049/TCP を ECS SG からのみ許可。

## コスト見積り（東京リージョン・試算）

以下は最小構成（Fargate 0.25vCPU/0.5GB、EFS 標準、CloudWatch Logs 少量）での概算です。

- Fargate 実行コスト（1 時間）
  - vCPU: 約 $0.06/時間 × 0.25 = 約 $0.015
  - メモリ: 約 $0.007/GB-時間 × 0.5GB = 約 $0.0035
  - 小計: 約 $0.0185（≒ 2 セント）
- EFS ストレージ（検証ファイル 1GB・1 日）
  - 約 $0.30/GB-月 → 1GB・1 日あたり ≒ $0.30/30 ≒ $0.01
- CloudWatch Logs（少量）
  - 数 MB 程度なら $0.01 未満が目安

概算合計（1 時間 + 1GB/日）: おおむね $0.03〜$0.05 程度。

注記:

- 同一 AZ 内の EFS 通信はデータ転送料がかからない前提が多いが、最新の料金・条件を要確認。
- 実運用では ECR プッシュや CI/CD 実行分の費用、NAT 等の付帯費用が発生し得ます。
