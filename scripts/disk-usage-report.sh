#!/bin/bash

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# レポートファイル名
REPORT_FILE="disk-usage-report-$(date +%Y%m%d_%H%M%S).txt"

log_section "ディスク使用状況レポート生成"
echo "レポートファイル: $REPORT_FILE"
echo ""

{
    echo "=========================================="
    echo "ディスク使用状況レポート"
    echo "生成日時: $(date)"
    echo "=========================================="
    echo ""

    # 1. 全体のディスク使用状況
    log_section "全体のディスク使用状況"
    df -h
    echo ""

    # 2. ホームディレクトリの使用状況
    log_section "ホームディレクトリの使用状況"
    du -sh ~ 2>/dev/null | head -1
    echo ""

    # 3. Libraryディレクトリの詳細
    log_section "Libraryディレクトリの使用状況（上位20件）"
    du -sh ~/Library/* 2>/dev/null | sort -hr | head -20
    echo ""

    # 4. Application Supportの詳細
    log_section "Application Supportの使用状況（上位15件）"
    du -sh ~/Library/Application\ Support/* 2>/dev/null | sort -hr | head -15
    echo ""

    # 5. Cachesの詳細
    log_section "Cachesの使用状況（上位15件）"
    du -sh ~/Library/Caches/* 2>/dev/null | sort -hr | head -15
    echo ""

    # 6. キャッシュディレクトリの詳細
    log_section "~/.cacheの使用状況（上位10件）"
    du -sh ~/.cache/* 2>/dev/null | sort -hr | head -10
    echo ""

    # 7. パッケージマネージャーキャッシュ
    log_section "パッケージマネージャーキャッシュ"
    echo "pnpm store:"
    du -sh ~/Library/pnpm/store 2>/dev/null || echo "  見つかりません"
    echo "npm cache:"
    du -sh ~/.npm 2>/dev/null || echo "  見つかりません"
    echo "Gradle cache:"
    du -sh ~/.gradle 2>/dev/null || echo "  見つかりません"
    echo "Maven cache:"
    du -sh ~/.m2 2>/dev/null || echo "  見つかりません"
    echo ""

    # 8. Docker関連
    log_section "Docker関連の使用状況"
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            docker system df 2>/dev/null || echo "Docker情報の取得に失敗しました"
        else
            echo "Dockerが実行されていません"
        fi
    else
        echo "Dockerがインストールされていません"
    fi
    echo ""

    # 9. 大きなファイル（1GB以上）
    log_section "大きなファイル（1GB以上）"
    find ~ -type f -size +1G 2>/dev/null | head -20 || echo "大きなファイルが見つかりませんでした"
    echo ""

    # 10. 開発ツール関連
    log_section "開発ツール関連の使用状況"
    echo "Xcode関連:"
    du -sh ~/Library/Developer/* 2>/dev/null | sort -hr || echo "  見つかりません"
    echo ""
    echo "JetBrains:"
    du -sh ~/Library/Application\ Support/JetBrains 2>/dev/null || echo "  見つかりません"
    echo ""

    # 11. ユーザーディレクトリ
    log_section "ユーザーディレクトリの使用状況"
    for dir in Downloads Documents Desktop Movies Pictures; do
        if [ -d ~/$dir ]; then
            echo "$dir:"
            du -sh ~/$dir 2>/dev/null
        fi
    done
    echo ""

    # 12. メモリ使用状況
    log_section "メモリ使用状況"
    vm_stat | head -20
    echo ""

    # 13. プロセス使用状況（上位10件）
    log_section "メモリ使用量の多いプロセス（上位10件）"
    ps aux | sort -rk 4 | head -11
    echo ""

    echo "=========================================="
    echo "レポート終了"
    echo "=========================================="

} | tee "$REPORT_FILE"

log_info "レポートを生成しました: $REPORT_FILE"
log_info "レポートファイルの場所: $(pwd)/$REPORT_FILE"
