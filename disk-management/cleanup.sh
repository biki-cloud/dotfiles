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

# 削除量の合計を追跡
TOTAL_FREED=0

# サイズを読みやすい形式に変換
format_size() {
    local size=$1
    if [ $size -ge 1073741824 ]; then
        echo "$(echo "scale=2; $size/1073741824" | bc)GB"
    elif [ $size -ge 1048576 ]; then
        echo "$(echo "scale=2; $size/1048576" | bc)MB"
    elif [ $size -ge 1024 ]; then
        echo "$(echo "scale=2; $size/1024" | bc)KB"
    else
        echo "${size}B"
    fi
}

# ディレクトリのサイズを取得
get_dir_size() {
    if [ -d "$1" ]; then
        du -sk "$1" 2>/dev/null | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
}

# 確認プロンプト
confirm() {
    local message=$1
    read -p "$(echo -e ${YELLOW}$message${NC} [y/N]: )" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

log_section "ディスククリーンアップスクリプト"
echo "このスクリプトは安全に削除可能なキャッシュと一時ファイルをクリーンアップします。"
echo ""

# 1. Docker Build Cacheのクリーンアップ
log_section "Docker Build Cacheのクリーンアップ"
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        BUILD_CACHE_SIZE=$(docker system df --format "{{.Size}}" 2>/dev/null | grep "Build Cache" | awk '{print $1}' || echo "0")
        if [ "$BUILD_CACHE_SIZE" != "0" ] && [ -n "$BUILD_CACHE_SIZE" ]; then
            log_info "Docker Build Cache: $BUILD_CACHE_SIZE が見つかりました"
            if confirm "Docker Build Cacheを削除しますか？"; then
                BEFORE=$(get_dir_size ~/.docker 2>/dev/null || echo "0")
                docker builder prune -af 2>/dev/null || log_warn "Docker Build Cacheの削除に失敗しました"
                AFTER=$(get_dir_size ~/.docker 2>/dev/null || echo "0")
                FREED=$((BEFORE - AFTER))
                TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
                log_info "Docker Build Cacheを削除しました"
            fi
        else
            log_info "Docker Build Cacheは見つかりませんでした"
        fi
    else
        log_warn "Dockerが実行されていません。スキップします。"
    fi
else
    log_info "Dockerがインストールされていません。スキップします。"
fi

# 2. パッケージマネージャーキャッシュのクリーンアップ
log_section "パッケージマネージャーキャッシュのクリーンアップ"

# pnpm store
if [ -d ~/Library/pnpm/store ]; then
    PNPM_SIZE=$(du -sk ~/Library/pnpm/store 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$PNPM_SIZE" -gt 0 ]; then
        PNPM_SIZE_READABLE=$(format_size $((PNPM_SIZE * 1024)))
        log_info "pnpm store: $PNPM_SIZE_READABLE が見つかりました"
        log_warn "pnpm storeを削除すると、次回のインストールが遅くなる可能性があります"
        if confirm "pnpm storeを削除しますか？"; then
            BEFORE=$(get_dir_size ~/Library/pnpm/store)
            rm -rf ~/Library/pnpm/store/*
            AFTER=$(get_dir_size ~/Library/pnpm/store)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "pnpm storeを削除しました"
        fi
    fi
fi

# npm cache
if command -v npm &> /dev/null; then
    log_info "npm cacheをクリーンアップしています..."
    BEFORE=$(get_dir_size ~/.npm 2>/dev/null || echo "0")
    npm cache clean --force 2>/dev/null || log_warn "npm cacheのクリーンアップに失敗しました"
    AFTER=$(get_dir_size ~/.npm 2>/dev/null || echo "0")
    FREED=$((BEFORE - AFTER))
    TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
    log_info "npm cacheをクリーンアップしました"
fi

# Gradle cache
if [ -d ~/.gradle ]; then
    GRADLE_SIZE=$(du -sk ~/.gradle 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$GRADLE_SIZE" -gt 0 ]; then
        GRADLE_SIZE_READABLE=$(format_size $((GRADLE_SIZE * 1024)))
        log_info "Gradle cache: $GRADLE_SIZE_READABLE が見つかりました"
        if confirm "Gradle cacheを削除しますか？"; then
            BEFORE=$(get_dir_size ~/.gradle)
            rm -rf ~/.gradle/caches/*
            AFTER=$(get_dir_size ~/.gradle)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "Gradle cacheを削除しました"
        fi
    fi
fi

# Maven cache
if [ -d ~/.m2 ]; then
    MAVEN_SIZE=$(du -sk ~/.m2 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$MAVEN_SIZE" -gt 0 ]; then
        MAVEN_SIZE_READABLE=$(format_size $((MAVEN_SIZE * 1024)))
        log_info "Maven cache: $MAVEN_SIZE_READABLE が見つかりました"
        if confirm "Maven cacheを削除しますか？"; then
            BEFORE=$(get_dir_size ~/.m2)
            rm -rf ~/.m2/repository/*
            AFTER=$(get_dir_size ~/.m2)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "Maven cacheを削除しました"
        fi
    fi
fi

# 3. 開発ツールキャッシュのクリーンアップ
log_section "開発ツールキャッシュのクリーンアップ"

# pre-commit cache
if [ -d ~/.cache/pre-commit ]; then
    PRECOMMIT_SIZE=$(du -sk ~/.cache/pre-commit 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$PRECOMMIT_SIZE" -gt 0 ]; then
        PRECOMMIT_SIZE_READABLE=$(format_size $((PRECOMMIT_SIZE * 1024)))
        log_info "pre-commit cache: $PRECOMMIT_SIZE_READABLE が見つかりました"
        if confirm "pre-commit cacheを削除しますか？"; then
            BEFORE=$(get_dir_size ~/.cache/pre-commit)
            rm -rf ~/.cache/pre-commit/*
            AFTER=$(get_dir_size ~/.cache/pre-commit)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "pre-commit cacheを削除しました"
        fi
    fi
fi

# uv cache
if [ -d ~/.cache/uv ]; then
    UV_SIZE=$(du -sk ~/.cache/uv 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$UV_SIZE" -gt 0 ]; then
        UV_SIZE_READABLE=$(format_size $((UV_SIZE * 1024)))
        log_info "uv cache: $UV_SIZE_READABLE が見つかりました"
        if confirm "uv cacheを削除しますか？"; then
            BEFORE=$(get_dir_size ~/.cache/uv)
            rm -rf ~/.cache/uv/*
            AFTER=$(get_dir_size ~/.cache/uv)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "uv cacheを削除しました"
        fi
    fi
fi

# puppeteer cache
if [ -d ~/.cache/puppeteer ]; then
    PUPPETEER_SIZE=$(du -sk ~/.cache/puppeteer 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$PUPPETEER_SIZE" -gt 0 ]; then
        PUPPETEER_SIZE_READABLE=$(format_size $((PUPPETEER_SIZE * 1024)))
        log_info "puppeteer cache: $PUPPETEER_SIZE_READABLE が見つかりました"
        if confirm "puppeteer cacheを削除しますか？"; then
            BEFORE=$(get_dir_size ~/.cache/puppeteer)
            rm -rf ~/.cache/puppeteer/*
            AFTER=$(get_dir_size ~/.cache/puppeteer)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "puppeteer cacheを削除しました"
        fi
    fi
fi

# prisma cache
if [ -d ~/.cache/prisma ]; then
    PRISMA_SIZE=$(du -sk ~/.cache/prisma 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$PRISMA_SIZE" -gt 0 ]; then
        PRISMA_SIZE_READABLE=$(format_size $((PRISMA_SIZE * 1024)))
        log_info "prisma cache: $PRISMA_SIZE_READABLE が見つかりました"
        if confirm "prisma cacheを削除しますか？"; then
            BEFORE=$(get_dir_size ~/.cache/prisma)
            rm -rf ~/.cache/prisma/*
            AFTER=$(get_dir_size ~/.cache/prisma)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "prisma cacheを削除しました"
        fi
    fi
fi

# ms-playwright cache
if [ -d ~/Library/Caches/ms-playwright ]; then
    PLAYWRIGHT_SIZE=$(du -sk ~/Library/Caches/ms-playwright 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$PLAYWRIGHT_SIZE" -gt 0 ]; then
        PLAYWRIGHT_SIZE_READABLE=$(format_size $((PLAYWRIGHT_SIZE * 1024)))
        log_info "ms-playwright cache: $PLAYWRIGHT_SIZE_READABLE が見つかりました"
        if confirm "ms-playwright cacheを削除しますか？"; then
            BEFORE=$(get_dir_size ~/Library/Caches/ms-playwright)
            rm -rf ~/Library/Caches/ms-playwright/*
            AFTER=$(get_dir_size ~/Library/Caches/ms-playwright)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "ms-playwright cacheを削除しました"
        fi
    fi
fi

# 4. アプリケーションログとキャッシュの削除
log_section "アプリケーションログとキャッシュの削除"

# Google Chrome cache
if [ -d ~/Library/Caches/Google ]; then
    CHROME_CACHE_SIZE=$(du -sk ~/Library/Caches/Google 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$CHROME_CACHE_SIZE" -gt 0 ]; then
        CHROME_CACHE_SIZE_READABLE=$(format_size $((CHROME_CACHE_SIZE * 1024)))
        log_info "Google Chrome cache: $CHROME_CACHE_SIZE_READABLE が見つかりました"
        if confirm "Google Chrome cacheを削除しますか？"; then
            BEFORE=$(get_dir_size ~/Library/Caches/Google)
            rm -rf ~/Library/Caches/Google/*
            AFTER=$(get_dir_size ~/Library/Caches/Google)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "Google Chrome cacheを削除しました"
        fi
    fi
fi

# Cursor logs
if [ -d ~/Library/Application\ Support/Cursor/logs ]; then
    CURSOR_LOG_SIZE=$(du -sk ~/Library/Application\ Support/Cursor/logs 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$CURSOR_LOG_SIZE" -gt 0 ]; then
        CURSOR_LOG_SIZE_READABLE=$(format_size $((CURSOR_LOG_SIZE * 1024)))
        log_info "Cursor logs: $CURSOR_LOG_SIZE_READABLE が見つかりました"
        if confirm "Cursor logsを削除しますか？"; then
            BEFORE=$(get_dir_size ~/Library/Application\ Support/Cursor/logs)
            rm -rf ~/Library/Application\ Support/Cursor/logs/*
            AFTER=$(get_dir_size ~/Library/Application\ Support/Cursor/logs)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "Cursor logsを削除しました"
        fi
    fi
fi

# Library/Logs (古いログ)
if [ -d ~/Library/Logs ]; then
    LOGS_SIZE=$(du -sk ~/Library/Logs 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$LOGS_SIZE" -gt 0 ]; then
        LOGS_SIZE_READABLE=$(format_size $((LOGS_SIZE * 1024)))
        log_info "Library/Logs: $LOGS_SIZE_READABLE が見つかりました"
        log_warn "古いログファイルを削除します（30日以上前のログ）"
        if confirm "古いログファイルを削除しますか？"; then
            BEFORE=$(get_dir_size ~/Library/Logs)
            find ~/Library/Logs -type f -mtime +30 -delete 2>/dev/null || true
            AFTER=$(get_dir_size ~/Library/Logs)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "古いログファイルを削除しました"
        fi
    fi
fi

# Homebrew cache
if command -v brew &> /dev/null; then
    log_info "Homebrew cacheをクリーンアップしています..."
    BEFORE=$(get_dir_size ~/Library/Caches/Homebrew 2>/dev/null || echo "0")
    brew cleanup --prune=all 2>/dev/null || log_warn "Homebrew cacheのクリーンアップに失敗しました"
    AFTER=$(get_dir_size ~/Library/Caches/Homebrew 2>/dev/null || echo "0")
    FREED=$((BEFORE - AFTER))
    TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
    log_info "Homebrew cacheをクリーンアップしました"
fi

# 5. Xcode関連のクリーンアップ
log_section "Xcode関連のクリーンアップ"

# CoreSimulator cache
if [ -d ~/Library/Developer/CoreSimulator/Caches ]; then
    SIM_CACHE_SIZE=$(du -sk ~/Library/Developer/CoreSimulator/Caches 2>/dev/null | awk '{print $1}' || echo "0")
    if [ "$SIM_CACHE_SIZE" -gt 0 ]; then
        SIM_CACHE_SIZE_READABLE=$(format_size $((SIM_CACHE_SIZE * 1024)))
        log_info "CoreSimulator cache: $SIM_CACHE_SIZE_READABLE が見つかりました"
        log_warn "CoreSimulator cacheを削除すると、次回のビルドが遅くなる可能性があります"
        if confirm "CoreSimulator cacheを削除しますか？"; then
            BEFORE=$(get_dir_size ~/Library/Developer/CoreSimulator/Caches)
            rm -rf ~/Library/Developer/CoreSimulator/Caches/*
            AFTER=$(get_dir_size ~/Library/Developer/CoreSimulator/Caches)
            FREED=$((BEFORE - AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "CoreSimulator cacheを削除しました"
        fi
    fi
fi

# 結果サマリー
log_section "クリーンアップ完了"
TOTAL_FREED_READABLE=$(format_size $TOTAL_FREED)
log_info "合計で約 $TOTAL_FREED_READABLE の容量を解放しました"

# 現在のディスク使用状況を表示
echo ""
log_section "現在のディスク使用状況"
df -h / | tail -1 | awk '{print "使用率: " $5 " (" $3 " / " $2 ")"}'
