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
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR"

log_info "Dotfilesのバックアップを開始します..."
log_info "Dotfilesディレクトリ: $DOTFILES_DIR"

# Homebrewパッケージのバックアップ
if command -v brew &> /dev/null; then
    log_info "Homebrewパッケージリストをバックアップしています..."
    brew bundle dump --force --file="$DOTFILES_DIR/Brewfile"
    log_info "Brewfileを更新しました"
else
    log_warn "Homebrewがインストールされていません"
fi

# シェル設定ファイルのバックアップ
log_info "シェル設定ファイルをバックアップしています..."
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc "$DOTFILES_DIR/config/zsh/.zshrc"
    log_info "~/.zshrcをバックアップしました"
else
    log_warn "~/.zshrcが見つかりません"
fi

if [ -f ~/.zprofile ]; then
    cp ~/.zprofile "$DOTFILES_DIR/config/zsh/.zprofile"
    log_info "~/.zprofileをバックアップしました"
else
    log_warn "~/.zprofileが見つかりません"
fi

# Vim設定ファイルのバックアップ
log_info "Vim設定ファイルをバックアップしています..."
if [ -f ~/.vimrc ]; then
    cp ~/.vimrc "$DOTFILES_DIR/config/vim/.vimrc"
    log_info "~/.vimrcをバックアップしました"
else
    log_warn "~/.vimrcが見つかりません"
fi

if [ -f ~/.ideavimrc ]; then
    cp ~/.ideavimrc "$DOTFILES_DIR/config/vim/.ideavimrc"
    log_info "~/.ideavimrcをバックアップしました"
else
    log_warn "~/.ideavimrcが見つかりません"
fi

# Git設定ファイルのバックアップ
log_info "Git設定ファイルをバックアップしています..."
if [ -f ~/.gitconfig ]; then
    cp ~/.gitconfig "$DOTFILES_DIR/config/git/.gitconfig"
    log_info "~/.gitconfigをバックアップしました"
else
    log_warn "~/.gitconfigが見つかりません"
fi

# SSH設定ファイルのバックアップ（秘密鍵は含めない）
log_info "SSH設定ファイルをバックアップしています..."
if [ -f ~/.ssh/config ]; then
    mkdir -p "$DOTFILES_DIR/config/ssh"
    cp ~/.ssh/config "$DOTFILES_DIR/config/ssh/config"
    log_info "~/.ssh/configをバックアップしました"
else
    log_warn "~/.ssh/configが見つかりません"
fi

# VSCode設定のバックアップ
log_info "VSCode設定をバックアップしています..."
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
if [ -f "$VSCODE_USER_DIR/settings.json" ]; then
    mkdir -p "$DOTFILES_DIR/config/vscode"
    cp "$VSCODE_USER_DIR/settings.json" "$DOTFILES_DIR/config/vscode/settings.json"
    log_info "VSCode settings.jsonをバックアップしました"
else
    log_warn "VSCode settings.jsonが見つかりません"
fi

if [ -f "$VSCODE_USER_DIR/keybindings.json" ]; then
    cp "$VSCODE_USER_DIR/keybindings.json" "$DOTFILES_DIR/config/vscode/keybindings.json"
    log_info "VSCode keybindings.jsonをバックアップしました"
fi

# VSCode拡張機能リストのバックアップ
if command -v code &> /dev/null; then
    log_info "VSCode拡張機能リストをバックアップしています..."
    code --list-extensions > "$DOTFILES_DIR/vscode-extensions.txt" 2>/dev/null || true
    log_info "vscode-extensions.txtを更新しました"
else
    log_warn "VSCodeがインストールされていないか、PATHに含まれていません"
fi

log_info "Dotfilesのバックアップが完了しました！"
