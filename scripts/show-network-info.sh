#!/bin/bash
# 📱 ネットワークアクセス情報表示・QRコード生成
# LAN内デバイスから簡単アクセス

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}📱 ネットワークアクセス情報${NC}"
echo ""

# ネットワーク情報検出
detect_network_addresses() {
    echo -e "${CYAN}🔍 ネットワークアドレス検出中...${NC}"
    
    # Docker内部IP
    CONTAINER_IP=$(hostname -i 2>/dev/null | awk '{print $1}' || echo "未検出")
    
    # ホストのプライベートIP（複数の方法で試行）
    HOST_IPS=()
    
    # 方法1: ip route経由
    if IP1=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[^ ]+'); then
        HOST_IPS+=("$IP1")
    fi
    
    # 方法2: hostname -I 経由
    if command -v hostname &>/dev/null; then
        for ip in $(hostname -I 2>/dev/null); do
            if [[ "$ip" =~ ^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.) ]]; then
                [[ ! " ${HOST_IPS[@]} " =~ " $ip " ]] && HOST_IPS+=("$ip")
            fi
        done
    fi
    
    # 方法3: ip addr経由
    while IFS= read -r ip; do
        [[ ! " ${HOST_IPS[@]} " =~ " $ip " ]] && HOST_IPS+=("$ip")
    done < <(ip addr show 2>/dev/null | grep -oP 'inet \K(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)[\d.]+' || true)
    
    # Tailscale IP
    TAILSCALE_IP=""
    if command -v tailscale &>/dev/null && sudo tailscale status &>/dev/null; then
        TAILSCALE_IP=$(sudo tailscale ip -4 2>/dev/null || echo "")
    fi
    
    echo -e "${GREEN}   ✅ 検出完了${NC}"
}

# QRコード生成（qrencode使用）
generate_qr_code() {
    local url="$1"
    local title="$2"
    
    if command -v qrencode &>/dev/null; then
        echo -e "${PURPLE}📱 $title QRコード:${NC}"
        qrencode -t ANSIUTF8 "$url"
        echo ""
    elif command -v curl &>/dev/null; then
        # オンラインQRコード生成サービス利用
        echo -e "${PURPLE}📱 $title QRコード URL:${NC}"
        echo "   https://api.qrserver.com/v1/create-qr-code/?data=$(echo "$url" | sed 's/:/%3A/g' | sed 's/\//%2F/g')&size=200x200"
        echo ""
    fi
}

# 環境変数読み込み
if [[ -f "/workspace/.env" ]]; then
    source /workspace/.env 2>/dev/null || true
fi

# ポート設定
OPENCODE_PORT=${OPENCODE_PORT:-4095}
OPENCHAMBER_PORT=${OPENCHAMBER_PORT:-3000}
PROJECT_PORT=8080

detect_network_addresses

echo ""
echo -e "${GREEN}🌐 アクセス可能なアドレス一覧${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ローカルアクセス
echo -e "${BLUE}🏠 ローカル環境（同じマシン）:${NC}"
echo "   🎨 OpenChamber:     http://localhost:$OPENCHAMBER_PORT"
echo "   🤖 OpenCode CLI:    http://localhost:$OPENCODE_PORT"
echo "   🚀 プロジェクト:     http://localhost:$PROJECT_PORT"
echo ""

# LAN内アクセス
if [[ ${#HOST_IPS[@]} -gt 0 ]]; then
    echo -e "${CYAN}📶 LAN内デバイス（同じWiFi/ネットワーク）:${NC}"
    for host_ip in "${HOST_IPS[@]}"; do
        echo "   📍 ホストIP: $host_ip"
        echo "     🎨 OpenChamber:   http://$host_ip:$OPENCHAMBER_PORT"
        echo "     🤖 OpenCode CLI:  http://$host_ip:$OPENCODE_PORT"
        echo "     🚀 プロジェクト:   http://$host_ip:$PROJECT_PORT"
        echo ""
        
        # メインIPの場合はQRコード生成
        if [[ "$host_ip" == "${HOST_IPS[0]}" ]]; then
            generate_qr_code "http://$host_ip:$OPENCHAMBER_PORT" "OpenChamber (LAN)"
        fi
    done
else
    echo -e "${YELLOW}⚠️  LAN内アクセス用IPが検出できませんでした${NC}"
    echo ""
fi

# Tailscaleアクセス
if [[ -n "$TAILSCALE_IP" ]]; then
    echo -e "${PURPLE}📱 Tailscale（世界中どこからでも）:${NC}"
    echo "   📍 Tailscale IP: $TAILSCALE_IP"
    echo "     🎨 OpenChamber:   http://$TAILSCALE_IP:$OPENCHAMBER_PORT"
    echo "     🤖 OpenCode CLI:  http://$TAILSCALE_IP:$OPENCODE_PORT"
    echo "     🚀 プロジェクト:   http://$TAILSCALE_IP:$PROJECT_PORT"
    echo ""
    
    generate_qr_code "http://$TAILSCALE_IP:$OPENCHAMBER_PORT" "OpenChamber (Tailscale)"
else
    echo -e "${YELLOW}📱 Tailscale未設定 - リモートアクセス無効${NC}"
    echo "   💡 有効にするには: ./scripts/setup-tailscale.sh を実行"
    echo ""
fi

# サービス状態確認
echo -e "${BLUE}🔍 サービス状態確認${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_service_status() {
    local port=$1
    local name=$2
    
    if netstat -tuln 2>/dev/null | grep ":$port " &>/dev/null; then
        echo -e "   ✅ $name (ポート $port): ${GREEN}実行中${NC}"
        
        # HTTP応答確認
        if curl -s --max-time 3 "http://localhost:$port" &>/dev/null; then
            echo -e "      📡 HTTP応答: ${GREEN}正常${NC}"
        else
            echo -e "      📡 HTTP応答: ${YELLOW}応答なし${NC}"
        fi
    else
        echo -e "   ❌ $name (ポート $port): ${RED}停止中${NC}"
    fi
}

check_service_status $OPENCHAMBER_PORT "OpenChamber"
check_service_status $OPENCODE_PORT "OpenCode CLI"
check_service_status $PROJECT_PORT "プロジェクトアプリ"

# ファイアウォール情報
echo ""
echo -e "${YELLOW}🛡️  ファイアウォール注意事項${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "LAN内からアクセスできない場合："
echo "  1. ホストマシンのファイアウォール設定を確認"
echo "  2. ポート $OPENCHAMBER_PORT, $OPENCODE_PORT, $PROJECT_PORT の許可"
echo "  3. DevContainerのポートフォワーディング設定確認"
echo ""

# モバイル最適化ヒント
echo -e "${CYAN}📱 モバイル最適化ヒント${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "スマートフォンでの最適な使用方法："
echo "  1. 📱 ブラウザでOpenChamberにアクセス"
echo "  2. ➕ ホーム画面に追加（PWAアプリ化）"
echo "  3. 🎨 フルスクリーンで快適なAI開発体験"
echo "  4. 🔄 バックグラウンドで処理継続"
echo ""

echo -e "${GREEN}✅ ネットワーク情報表示完了${NC}"
echo ""
echo -e "${BLUE}💡 このスクリプトを定期実行:${NC}"
echo "   watch -n 30 ./scripts/show-network-info.sh"