# Backend API App

## 前提条件

 * [Node.js 16.x](https://nodejs.org/ja/download/)
 * [Yarn](https://yarnpkg.com/)
 * [AWS CLI](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/install-cliv2.html) 2.x

## リポジトリ構成

```
.
├─app: アプリケーションを格納するディレクトリ。
│   ├─node_modules: プロジェクトが依存するパッケージ群。
│   ├─src: アプリケーションのソースコードを格納するディレクトリ。
│   ├─.gitignore: Git管理除外指定ファイル。
│   ├─yarn.lock: Yarnのロックファイル。
│   ├─package.json: NPM パッケージ定義ファイル。
│   └─tsconfig.json: TypeScript 構成ファイル。
├─pipeline
│   ├─buildspecs: CodeBuildのビルド定義ファイル(buildspec)を格納するディレクトリ。
│   ├─cfn-templates: CI/CDのコード(CFnテンプレート)を格納するディレクトリ。
│   └─scripts: CI/CD関連スクリプトファイルを格納するディレクトリ。
├─resources
│   └─aws: AWSリソース定義ファイル(CFnテンプレート)を格納するディレクトリ。
└─README.md: 本ドキュメント
```

## CI/CDのデプロイ手順

### 1. S3バケットの作成


デプロイ対象のAWSアカウント、リージョンにS3バケットを作成します。
このバケットは手順「」の.envファイルに設定します。

### 2. GitHubとの接続設定の実施

[AWSのGitHub接続](https://docs.aws.amazon.com/ja_jp/codepipeline/latest/userguide/connections-github.html)に関するマニュアルを参照し、GitHubとの接続設定を実施します。
作成したGitHub接続のArnを次の名前「/codestar-connection/connection-arn」でパラメータストアにテキストとして設定します。

### 3. .envファイルの作成

.envファイルのテンプレート(env.tmpl)を元にenvファイルを作成します。
```
[プロジェクトルートで実行]
cp pipeline/scripts/env.tmpl pipeline/scripts/.env
```
下表を参考に.envファイルに必要な情報を設定します。

|  設定項目              |  設定内容                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------- |
|  APPLICATION_NAME      |  stee                                                                                             |
|  SERVICE_NAME          |  frontend-app                                                                                     |
|  S3_BUCKET_NAME        |  ネスト構成のCFnテンプレートをデプロイする際に利用するS3バケット名。                              |
|  REPOSITORY_NAME       |  ソースコードの変更を検出するアプリケーションリポジトリ名([ユーザー名|組織名]/リポジトリ名)。     |
|  BRANCH_NAME           |  ソースコードの変更を検出するブランチ名。                                                         |

### 4. スクリプト実行

```
[プロジェクトルートで実行]
bash pipeline/scripts/deploy.sh
```

### 注意事項

  * CI/CD Pipeline生成に失敗時、CloudFromation Stackはロールバックされますがアーティファクトリポジトリ(S3 バケット)、アクセスログを保存するS3 バケット、コンテナイメージリポジトリ(ECR リポジトリ)、は物理削除されません。マニュアルオペレーションで削除する必要があります。
  * CloudFromationでの初回作成失敗時は、ロールバック可能な前の状態が存在しないためマニュアルでCloudFromation Stackを削除する必要があります。


## アプリケーション開発

ローカルでアプリケーションを起動するには下記コマンドを実行します。
```
[プロジェクトルート/appで実行]
yarn install
yarn start
```
