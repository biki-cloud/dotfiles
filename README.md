# Dotfiles

macOS環境の設定ファイルとアプリケーションを管理するdotfilesリポジトリです。

## 概要

このリポジトリには以下の設定が含まれています：

- **Homebrewパッケージ**: すべてのHomebrewパッケージ（formulaとcask）のリスト
- **シェル設定**: zsh設定ファイル（.zshrc, .zprofile）
- **Vim設定**: .vimrc, .ideavimrc
- **VSCode設定**: settings.json、拡張機能リスト
- **Git設定**: .gitconfig
- **SSH設定**: .ssh/config（秘密鍵は含まれません）

## ディレクトリ構造

```
dotfiles-1/
├── README.md
├── install.sh              # インストールスクリプト
├── Brewfile                # Homebrewパッケージリスト
├── vscode-extensions.txt   # VSCode拡張機能リスト
├── config/
│   ├── zsh/
│   │   ├── .zshrc
│   │   └── .zprofile
│   ├── vscode/
│   │   ├── settings.json
│   │   └── keybindings.json
│   ├── vim/
│   │   ├── .vimrc
│   │   └── .ideavimrc
│   ├── git/
│   │   └── .gitconfig
│   └── ssh/
│       └── config
├── scripts/
│   └── backup.sh           # バックアップスクリプト
└── disk-management/
    ├── cleanup.sh          # ディスククリーンアップスクリプト
    ├── disk-usage-report.sh # ディスク使用状況レポート生成スクリプト
    └── disk-usage-report-*.txt # 生成されたレポートファイル
```

## インストール方法

新しいMacに設定を復元する場合：

1. リポジトリをクローン：
```bash
git clone <repository-url> ~/dotfiles-1
cd ~/dotfiles-1
```

2. インストールスクリプトを実行：
```bash
./install.sh
```

インストールスクリプトは以下を自動的に実行します：

- Homebrewのインストール（未インストールの場合）
- Homebrewパッケージのインストール（Brewfileから）
- zshプラグインのインストール
- 設定ファイルのシンボリックリンク作成
- VSCode拡張機能のインストール

3. 新しいシェルセッションを開始するか、以下を実行：
```bash
source ~/.zshrc
```

## バックアップ方法

現在のシステム設定をバックアップする場合：

```bash
./scripts/backup.sh
```

このスクリプトは以下をバックアップします：

- Homebrewパッケージリスト（Brewfile）
- シェル設定ファイル
- Vim設定ファイル
- Git設定ファイル
- SSH設定ファイル
- VSCode設定と拡張機能リスト

## ディスククリーンアップ

PCのディスク容量が逼迫している場合、以下のスクリプトを使用してクリーンアップできます。

### ディスク使用状況の調査

ディスク使用状況の詳細レポートを生成：

```bash
./disk-management/disk-usage-report.sh
```

このスクリプトは以下を調査します：

- 全体のディスク使用状況
- ホームディレクトリとLibraryディレクトリの使用状況
- パッケージマネージャーキャッシュのサイズ
- Docker関連の使用状況
- 大きなファイル（1GB以上）
- メモリ使用状況

レポートは `disk-management/disk-usage-report-YYYYMMDD_HHMMSS.txt` として保存されます。

### クリーンアップの実行

安全に削除可能なキャッシュと一時ファイルをクリーンアップ：

```bash
./disk-management/cleanup.sh
```

このスクリプトは以下をクリーンアップします（各項目について確認プロンプトが表示されます）：

- **Docker Build Cache**（約6GB解放可能）
- **パッケージマネージャーキャッシュ**
  - pnpm store（約6.8GB）
  - npm cache（約751MB）
  - Gradle cache（約1.1GB）
  - Maven cache（約54MB）
- **開発ツールキャッシュ**
  - pre-commit cache（約1.1GB）
  - uv cache（約801MB）
  - puppeteer cache（約741MB）
  - prisma cache（約253MB）
  - ms-playwright cache（約1.1GB）
- **アプリケーションキャッシュ**
  - Google Chrome cache（約1.5GB）
  - Cursor logs（約268MB）
  - 古いログファイル（30日以上前）
  - Homebrew cache
- **Xcode関連**
  - CoreSimulator cache（約1.2GB）

**注意**: クリーンアップ後、次回のビルドやインストールが若干遅くなる可能性があります。キャッシュは自動的に再生成されます。

### 推奨されるクリーンアップ頻度

- **月1回**: ディスク使用状況レポートを実行して状況を確認
- **3ヶ月に1回**: クリーンアップスクリプトを実行
- **ディスク使用率が90%を超えた場合**: すぐにクリーンアップを検討

## 手動セットアップ項目

以下の項目は手動で設定する必要があります：

- Xcodeのインストール
- SSHキーの生成とGitHubへの登録
  - [SSHキーをGitHubに登録](https://qiita.com/takayamag/items/9818f9b5cb1fad77e583)
- Chromeのインストールと設定
  - Chromeをデフォルトのブラウザに設定
  - ショートカットキーの設定
  - Googleアカウントへのログイン
- ターミナルのテーマ設定
  - [ターミナルのテーマ](https://qiita.com/obake_fe/items/c2edf65de684f026c59c)
- vim-plugのインストール
  - [vim-plugのインストール](https://qiita.com/kouichi_c/items/e19ccf94b8e5ab6ed18e)
- M1 Macの連続入力設定
  - [m1マックは連続入力できない](https://ryo-blog.lsv.jp/archives/20210422/108/)

## 含まれる設定の詳細

### シェル設定

- oh-my-zsh
- zsh-autosuggestions
- zsh-syntax-highlighting
- powerlevel10k
- starship
- その他のカスタムエイリアスと設定

### Vim設定

- vim-plugプラグイン
- NERDTree
- vim-airline
- カスタムキーマップ

### VSCode設定

- エディタ設定（フォント、フォントサイズなど）
- 拡張機能設定
- キーバインド設定

## 注意事項

- SSH設定ファイルには秘密鍵は含まれていません。秘密鍵は別途管理してください。
- 既存の設定ファイルがある場合、インストールスクリプトは自動的にバックアップを作成します。
- VSCodeの設定は、VSCodeがインストールされている場合のみ適用されます。

## 更新履歴

- 2024年: 包括的なdotfiles管理システムに更新
