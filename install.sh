#!/bin/bash

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# スクリプトのディレクトリを取得
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

log_info "Dotfilesのインストールを開始します..."
log_info "Dotfilesディレクトリ: $DOTFILES_DIR"

# Homebrewのインストール
if ! command -v brew &> /dev/null; then
    log_info "Homebrewをインストールしています..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Homebrewのパスを設定（Apple Silicon Macの場合）
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    log_info "Homebrewは既にインストールされています"
fi

# Homebrewパッケージのインストール
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    log_info "Homebrewパッケージをインストールしています..."
    brew bundle --file="$DOTFILES_DIR/Brewfile"
else
    log_warn "Brewfileが見つかりません"
fi

# zshプラグインのインストール
log_info "zshプラグインをインストールしています..."
if [ ! -d "$(brew --prefix)/share/zsh-autosuggestions" ]; then
    brew install zsh-autosuggestions
fi

if [ ! -d "$(brew --prefix)/share/zsh-syntax-highlighting" ]; then
    brew install zsh-syntax-highlighting
fi

# シェル設定ファイルのリンク作成
log_info "シェル設定ファイルをリンクしています..."
if [ -f "$DOTFILES_DIR/config/zsh/.zshrc" ]; then
    if [ -f ~/.zshrc ]; then
        log_warn "~/.zshrcが既に存在します。バックアップを作成します..."
        mv ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    fi
    ln -sf "$DOTFILES_DIR/config/zsh/.zshrc" ~/.zshrc
    log_info "~/.zshrcをリンクしました"
fi

if [ -f "$DOTFILES_DIR/config/zsh/.zprofile" ]; then
    if [ -f ~/.zprofile ]; then
        log_warn "~/.zprofileが既に存在します。バックアップを作成します..."
        mv ~/.zprofile ~/.zprofile.backup.$(date +%Y%m%d_%H%M%S)
    fi
    ln -sf "$DOTFILES_DIR/config/zsh/.zprofile" ~/.zprofile
    log_info "~/.zprofileをリンクしました"
fi

# Vim設定ファイルのリンク作成
log_info "Vim設定ファイルをリンクしています..."
if [ -f "$DOTFILES_DIR/config/vim/.vimrc" ]; then
    if [ -f ~/.vimrc ]; then
        log_warn "~/.vimrcが既に存在します。バックアップを作成します..."
        mv ~/.vimrc ~/.vimrc.backup.$(date +%Y%m%d_%H%M%S)
    fi
    ln -sf "$DOTFILES_DIR/config/vim/.vimrc" ~/.vimrc
    log_info "~/.vimrcをリンクしました"
fi

if [ -f "$DOTFILES_DIR/config/vim/.ideavimrc" ]; then
    if [ -f ~/.ideavimrc ]; then
        log_warn "~/.ideavimrcが既に存在します。バックアップを作成します..."
        mv ~/.ideavimrc ~/.ideavimrc.backup.$(date +%Y%m%d_%H%M%S)
    fi
    ln -sf "$DOTFILES_DIR/config/vim/.ideavimrc" ~/.ideavimrc
    log_info "~/.ideavimrcをリンクしました"
fi

# Git設定ファイルのリンク作成
log_info "Git設定ファイルをリンクしています..."
if [ -f "$DOTFILES_DIR/config/git/.gitconfig" ]; then
    if [ -f ~/.gitconfig ]; then
        log_warn "~/.gitconfigが既に存在します。バックアップを作成します..."
        mv ~/.gitconfig ~/.gitconfig.backup.$(date +%Y%m%d_%H%M%S)
    fi
    ln -sf "$DOTFILES_DIR/config/git/.gitconfig" ~/.gitconfig
    log_info "~/.gitconfigをリンクしました"
fi

# SSH設定ファイルのコピー（秘密鍵は含めない）
log_info "SSH設定ファイルをコピーしています..."
if [ -f "$DOTFILES_DIR/config/ssh/config" ]; then
    mkdir -p ~/.ssh
    if [ -f ~/.ssh/config ]; then
        log_warn "~/.ssh/configが既に存在します。バックアップを作成します..."
        cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)
    fi
    cp "$DOTFILES_DIR/config/ssh/config" ~/.ssh/config
    chmod 600 ~/.ssh/config
    log_info "~/.ssh/configをコピーしました"
fi

# VSCode設定のコピー
log_info "VSCode設定をコピーしています..."
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
if [ -f "$DOTFILES_DIR/config/vscode/settings.json" ]; then
    mkdir -p "$VSCODE_USER_DIR"
    if [ -f "$VSCODE_USER_DIR/settings.json" ]; then
        log_warn "VSCode settings.jsonが既に存在します。バックアップを作成します..."
        cp "$VSCODE_USER_DIR/settings.json" "$VSCODE_USER_DIR/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    cp "$DOTFILES_DIR/config/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
    log_info "VSCode settings.jsonをコピーしました"
fi

# VSCode拡張機能のインストール
if [ -f "$DOTFILES_DIR/vscode-extensions.txt" ] && command -v code &> /dev/null; then
    log_info "VSCode拡張機能をインストールしています..."
    while IFS= read -r extension; do
        if [ -n "$extension" ] && [[ ! "$extension" =~ ^# ]]; then
            code --install-extension "$extension" || log_warn "拡張機能 $extension のインストールに失敗しました"
        fi
    done < "$DOTFILES_DIR/vscode-extensions.txt"
    log_info "VSCode拡張機能のインストールが完了しました"
elif [ ! -f "$DOTFILES_DIR/vscode-extensions.txt" ]; then
    log_warn "vscode-extensions.txtが見つかりません"
elif ! command -v code &> /dev/null; then
    log_warn "VSCodeがインストールされていないか、PATHに含まれていません"
fi

log_info "Dotfilesのインストールが完了しました！"
log_info "新しいシェルセッションを開始するか、以下のコマンドを実行してください:"
log_info "  source ~/.zshrc"
