#!/bin/bash

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# オプション（デフォルトは対話モード）
YES_ALL=false
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            YES_ALL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-y|--yes] [--dry-run]"
            echo "  -y, --yes    確認なしで実行（安全な項目のみ自動実行）"
            echo "  --dry-run    削除せずに何を削除するか表示するだけ"
            echo "  -h, --help   このヘルプを表示"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

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

log_dry() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $1"
}

# 削除量の合計を追跡（バイト）
TOTAL_FREED=0

# サイズを読みやすい形式に変換（bc がなくても動く）
format_size() {
    local size=$1
    if [ -z "$size" ] || [ "$size" -lt 0 ] 2>/dev/null; then
        echo "0B"
        return
    fi
    if [ "$size" -ge 1073741824 ] 2>/dev/null; then
        echo "$(awk "BEGIN { printf \"%.2fGB\", $size/1073741824 }")"
    elif [ "$size" -ge 1048576 ] 2>/dev/null; then
        echo "$(awk "BEGIN { printf \"%.2fMB\", $size/1048576 }")"
    elif [ "$size" -ge 1024 ] 2>/dev/null; then
        echo "$(awk "BEGIN { printf \"%.2fKB\", $size/1024 }")"
    else
        echo "${size}B"
    fi
}

# ディレクトリのサイズを取得（KB）
get_dir_size() {
    if [ -d "$1" ]; then
        du -sk "$1" 2>/dev/null | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
}

# 確認プロンプト（-y または --dry-run の場合は yes）
confirm() {
    local message=$1
    if [ "$DRY_RUN" = true ] || [ "$YES_ALL" = true ]; then
        return 0
    fi
    read -p "$(echo -e ${YELLOW}$message${NC} [y/N]: )" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# 汎用: ディレクトリをクリーンアップ（確認あり）
# 使用法: clean_dir "説明" "ディレクトリパス" ["警告メッセージ"]
clean_dir() {
    local desc="$1"
    local dir="$2"
    local warn="${3:-}"

    [ -d "$dir" ] || return 0
    local size_kb
    size_kb=$(get_dir_size "$dir")
    [ "${size_kb:-0}" -gt 0 ] 2>/dev/null || return 0

    local size_readable
    size_readable=$(format_size $((size_kb * 1024)))
    log_info "$desc: $size_readable が見つかりました"
    [ -n "$warn" ] && log_warn "$warn"
    if confirm "$desc を削除しますか？"; then
        if [ "$DRY_RUN" = true ]; then
            log_dry "削除する: $dir"
            TOTAL_FREED=$((TOTAL_FREED + size_kb * 1024))
            return 0
        fi
        local before after freed
        before=$(get_dir_size "$dir")
        rm -rf "${dir:?}"/*
        after=$(get_dir_size "$dir")
        freed=$((before - after))
        [ "$freed" -lt 0 ] && freed=0
        TOTAL_FREED=$((TOTAL_FREED + freed * 1024))
        log_info "$desc を削除しました"
    fi
}

# 汎用: 確認なしで実行（安全なキャッシュ向け）
clean_dir_auto() {
    local desc="$1"
    local dir="$2"

    [ -d "$dir" ] || return 0
    local size_kb
    size_kb=$(get_dir_size "$dir")
    [ "${size_kb:-0}" -gt 0 ] 2>/dev/null || return 0

    log_info "$desc をクリーンアップしています..."
    if [ "$DRY_RUN" = true ]; then
        log_dry "削除する: $dir ($(format_size $((size_kb * 1024))))"
        TOTAL_FREED=$((TOTAL_FREED + size_kb * 1024))
        return 0
    fi
    local before after freed
    before=$(get_dir_size "$dir")
    rm -rf "${dir:?}"/* 2>/dev/null || true
    after=$(get_dir_size "$dir")
    freed=$((before - after))
    [ "$freed" -lt 0 ] && freed=0
    TOTAL_FREED=$((TOTAL_FREED + freed * 1024))
    log_info "$desc をクリーンアップしました"
}

# データボリュームのパス（macOS）
DATA_VOLUME="${HOME}"
if [ -d /System/Volumes/Data ]; then
    DATA_VOLUME="/System/Volumes/Data"
fi

log_section "ディスククリーンアップスクリプト"
echo "安全に削除可能なキャッシュと一時ファイルをクリーンアップします。"
[ "$DRY_RUN" = true ] && log_warn "DRY-RUN モード: 実際には削除しません。"
[ "$YES_ALL" = true ] && log_warn "YES モード: 確認をスキップします。"
echo ""

# ---------------------------------------------------------------------------
# 1. Docker Build Cache
# ---------------------------------------------------------------------------
log_section "Docker Build Cacheのクリーンアップ"
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        # docker system df の表から Build Cache のサイズを取得
        BUILD_CACHE_LINE=$(docker system df 2>/dev/null | grep -i "Build Cache" || true)
        if [ -n "$BUILD_CACHE_LINE" ]; then
            log_info "Docker Build Cache が見つかりました: $BUILD_CACHE_LINE"
            if confirm "Docker Build Cache を削除しますか？"; then
                if [ "$DRY_RUN" = true ]; then
                    log_dry "docker builder prune -af を実行"
                else
                    docker builder prune -af 2>/dev/null || log_warn "Docker Build Cache の削除に失敗しました"
                    log_info "Docker Build Cache を削除しました（容量は VM 内のため集計外）"
                fi
            fi
        else
            log_info "Docker Build Cache は見つかりませんでした"
        fi
    else
        log_warn "Docker が実行されていません。スキップします。"
    fi
else
    log_info "Docker がインストールされていません。スキップします。"
fi

# ---------------------------------------------------------------------------
# 2. パッケージマネージャーキャッシュ
# ---------------------------------------------------------------------------
log_section "パッケージマネージャーキャッシュのクリーンアップ"

clean_dir "pnpm store" "$HOME/Library/pnpm/store" "削除すると次回のインストールが遅くなる可能性があります"

# npm cache（確認なしで実行が一般的）
if command -v npm &> /dev/null; then
    if [ -d "$HOME/.npm" ]; then
        log_info "npm cache をクリーンアップしています..."
        if [ "$DRY_RUN" = true ]; then
            log_dry "npm cache clean --force"
            TOTAL_FREED=$((TOTAL_FREED + $(get_dir_size "$HOME/.npm") * 1024))
        else
            BEFORE=$(get_dir_size "$HOME/.npm")
            npm cache clean --force 2>/dev/null || log_warn "npm cache のクリーンアップに失敗しました"
            AFTER=$(get_dir_size "$HOME/.npm")
            FREED=$((BEFORE - AFTER))
            [ "$FREED" -lt 0 ] && FREED=0
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "npm cache をクリーンアップしました"
        fi
    fi
fi

clean_dir "Gradle cache" "$HOME/.gradle/caches"
clean_dir "Maven cache" "$HOME/.m2/repository"

# ---------------------------------------------------------------------------
# 3. 開発ツールキャッシュ
# ---------------------------------------------------------------------------
log_section "開発ツールキャッシュのクリーンアップ"

clean_dir "pre-commit cache" "$HOME/.cache/pre-commit"
clean_dir "uv cache" "$HOME/.cache/uv"
clean_dir "puppeteer cache" "$HOME/.cache/puppeteer"
clean_dir "prisma cache" "$HOME/.cache/prisma"
clean_dir "ms-playwright cache" "$HOME/Library/Caches/ms-playwright"
clean_dir "node-gyp cache" "$HOME/Library/Caches/node-gyp"
clean_dir "TypeScript cache" "$HOME/Library/Caches/typescript"
clean_dir "pip cache" "$HOME/Library/Caches/pip"
clean_dir "Cursor compile cache" "$HOME/Library/Caches/cursor-compile-cache"

# Electron ShipIt / Cursor 更新キャッシュ（レポートで 718M）
for shipit in "$HOME/Library/Caches"/com.todesktop.*.ShipIt; do
    [ -d "$shipit" ] || continue
    clean_dir "Electron ShipIt cache ($(basename "$shipit"))" "$shipit"
done

# Ollama キャッシュ（モデルは削除せず、キャッシュのみ）
clean_dir "ollama cache" "$HOME/Library/Caches/ollama"

# ---------------------------------------------------------------------------
# 4. アプリケーションログとキャッシュ
# ---------------------------------------------------------------------------
log_section "アプリケーションログとキャッシュの削除"

clean_dir "Google Chrome cache" "$HOME/Library/Caches/Google"
clean_dir "Cursor logs" "$HOME/Library/Application Support/Cursor/logs"

# Library/Logs（30日以上前のログのみ）
if [ -d "$HOME/Library/Logs" ]; then
    LOGS_SIZE=$(get_dir_size "$HOME/Library/Logs")
    if [ "${LOGS_SIZE:-0}" -gt 0 ] 2>/dev/null; then
        log_info "Library/Logs: $(format_size $((LOGS_SIZE * 1024))) が見つかりました"
        log_warn "30日以上前のログファイルを削除します"
        if confirm "古いログファイルを削除しますか？"; then
            if [ "$DRY_RUN" = true ]; then
                log_dry "find ~/Library/Logs -type f -mtime +30 -delete"
            else
                BEFORE=$(get_dir_size "$HOME/Library/Logs")
                find "$HOME/Library/Logs" -type f -mtime +30 -delete 2>/dev/null || true
                AFTER=$(get_dir_size "$HOME/Library/Logs")
                FREED=$((BEFORE - AFTER))
                [ "$FREED" -lt 0 ] && FREED=0
                TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
                log_info "古いログファイルを削除しました"
            fi
        fi
    fi
fi

# Homebrew cache
if command -v brew &> /dev/null; then
    if [ -d "$HOME/Library/Caches/Homebrew" ]; then
        log_info "Homebrew cache をクリーンアップしています..."
        if [ "$DRY_RUN" = true ]; then
            log_dry "brew cleanup --prune=all"
            TOTAL_FREED=$((TOTAL_FREED + $(get_dir_size "$HOME/Library/Caches/Homebrew") * 1024))
        else
            BEFORE=$(get_dir_size "$HOME/Library/Caches/Homebrew")
            brew cleanup --prune=all 2>/dev/null || log_warn "Homebrew cache のクリーンアップに失敗しました"
            AFTER=$(get_dir_size "$HOME/Library/Caches/Homebrew")
            FREED=$((BEFORE - AFTER))
            [ "$FREED" -lt 0 ] && FREED=0
            TOTAL_FREED=$((TOTAL_FREED + FREED * 1024))
            log_info "Homebrew cache をクリーンアップしました"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 5. Xcode 関連
# ---------------------------------------------------------------------------
log_section "Xcode関連のクリーンアップ"

clean_dir "CoreSimulator cache" "$HOME/Library/Developer/CoreSimulator/Caches" \
    "削除すると次回のビルドが遅くなる可能性があります"

# ---------------------------------------------------------------------------
# 結果サマリー
# ---------------------------------------------------------------------------
log_section "クリーンアップ完了"
TOTAL_FREED_READABLE=$(format_size "$TOTAL_FREED")
log_info "合計で約 $TOTAL_FREED_READABLE の容量を解放しました（見込み）。"

echo ""
log_section "現在のディスク使用状況"
# ルートとデータボリュームの両方を表示
df -h / 2>/dev/null | tail -1 | awk '{print "  /:        " $5 " (" $3 " / " $2 ")"}'
df -h "$DATA_VOLUME" 2>/dev/null | tail -1 | awk '{print "  Data:     " $5 " (" $3 " / " $2 ")"}' || true
