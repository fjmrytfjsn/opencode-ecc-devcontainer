// 🎨 {{PROJECT_NAME}} - ダッシュボード付きメインアプリケーション
// 作者: {{AUTHOR_NAME}}
// 生成日: {{TIMESTAMP}}

const express = require('express');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { execSync } = require('child_process');

const app = express();
const PORT = process.env.DEV_SERVER_PORT || 8080;

// 静的ファイル提供
app.use(express.static('public'));

// ネットワーク情報取得関数
function getNetworkInfo() {
    const networkInterfaces = os.networkInterfaces();
    const addresses = [];
    
    // プライベートIP取得
    for (const [name, interfaces] of Object.entries(networkInterfaces)) {
        for (const iface of interfaces) {
            if (iface.family === 'IPv4' && !iface.internal) {
                if (iface.address.match(/^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/) ) {
                    addresses.push({
                        interface: name,
                        address: iface.address,
                        type: 'LAN'
                    });
                }
            }
        }
    }
    
    // Tailscale IP取得（可能であれば）
    let tailscaleIP = null;
    try {
        tailscaleIP = execSync('tailscale ip -4 2>/dev/null', { encoding: 'utf8' }).trim();
    } catch (e) {
        // Tailscale未設定の場合は無視
    }
    
    return {
        addresses,
        tailscaleIP,
        hostname: os.hostname()
    };
}

// サービス状態確認
function checkServiceStatus(port) {
    try {
        const result = execSync(`netstat -tuln | grep ":${port} "`, { encoding: 'utf8' });
        return result.length > 0;
    } catch (e) {
        return false;
    }
}

// メインダッシュボード
app.get('/', (req, res) => {
    const networkInfo = getNetworkInfo();
    const services = [
        {
            name: 'OpenChamber',
            description: 'AI チャットインターフェース',
            port: process.env.OPENCHAMBER_PORT || 3000,
            icon: '🎨',
            status: checkServiceStatus(process.env.OPENCHAMBER_PORT || 3000)
        },
        {
            name: 'OpenCode CLI',
            description: 'AI エージェント実行エンジン',
            port: process.env.OPENCODE_PORT || 4095,
            icon: '🤖',
            status: checkServiceStatus(process.env.OPENCODE_PORT || 4095)
        }
    ];
    
    // HTML レスポンス生成
    const html = `
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>🚀 {{PROJECT_NAME}} ダッシュボード</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                color: white;
            }
            
            .container {
                max-width: 1200px;
                margin: 0 auto;
                padding: 20px;
            }
            
            .header {
                text-align: center;
                margin-bottom: 40px;
            }
            
            .title {
                font-size: 3rem;
                margin-bottom: 10px;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
            }
            
            .subtitle {
                font-size: 1.2rem;
                opacity: 0.9;
            }
            
            .services {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 20px;
                margin-bottom: 40px;
            }
            
            .service-card {
                background: rgba(255,255,255,0.1);
                backdrop-filter: blur(10px);
                border-radius: 15px;
                padding: 25px;
                border: 1px solid rgba(255,255,255,0.2);
                transition: transform 0.3s ease;
                position: relative;
            }
            
            .service-card:hover {
                transform: translateY(-5px);
                background: rgba(255,255,255,0.15);
            }
            
            .service-header {
                display: flex;
                align-items: center;
                margin-bottom: 15px;
            }
            
            .service-icon {
                font-size: 2rem;
                margin-right: 15px;
            }
            
            .service-name {
                font-size: 1.3rem;
                font-weight: bold;
            }
            
            .service-description {
                margin-bottom: 20px;
                opacity: 0.8;
            }
            
            .service-links {
                display: flex;
                flex-wrap: wrap;
                gap: 10px;
            }
            
            .service-link {
                padding: 8px 15px;
                background: rgba(255,255,255,0.2);
                text-decoration: none;
                color: white;
                border-radius: 8px;
                font-size: 0.9rem;
                transition: all 0.2s ease;
            }
            
            .service-link:hover {
                background: rgba(255,255,255,0.3);
                transform: scale(1.05);
            }
            
            .status-indicator {
                position: absolute;
                top: 15px;
                right: 15px;
                width: 12px;
                height: 12px;
                border-radius: 50%;
                background: ${services[0].status ? '#4ade80' : '#f87171'};
                box-shadow: 0 0 10px ${services[0].status ? '#4ade80' : '#f87171'};
            }
            
            .network-info {
                background: rgba(255,255,255,0.1);
                backdrop-filter: blur(10px);
                border-radius: 15px;
                padding: 25px;
                border: 1px solid rgba(255,255,255,0.2);
                margin-bottom: 30px;
            }
            
            .network-title {
                font-size: 1.5rem;
                margin-bottom: 20px;
                display: flex;
                align-items: center;
            }
            
            .network-list {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 15px;
            }
            
            .network-item {
                background: rgba(255,255,255,0.1);
                padding: 15px;
                border-radius: 10px;
            }
            
            .network-type {
                font-weight: bold;
                margin-bottom: 5px;
            }
            
            .network-address {
                font-family: monospace;
                font-size: 0.9rem;
                opacity: 0.8;
            }
            
            .footer {
                text-align: center;
                opacity: 0.7;
                font-size: 0.9rem;
            }
            
            @media (max-width: 768px) {
                .title {
                    font-size: 2rem;
                }
                
                .services {
                    grid-template-columns: 1fr;
                }
                
                .container {
                    padding: 15px;
                }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1 class="title">🚀 {{PROJECT_NAME}}</h1>
                <p class="subtitle">{{PROJECT_DESCRIPTION}}</p>
            </div>
            
            <div class="network-info">
                <h2 class="network-title">📡 ネットワークアクセス情報</h2>
                <div class="network-list">
                    <div class="network-item">
                        <div class="network-type">🏠 ローカル</div>
                        <div class="network-address">localhost</div>
                    </div>
                    ${networkInfo.addresses.map(addr => `
                        <div class="network-item">
                            <div class="network-type">📶 LAN (${addr.interface})</div>
                            <div class="network-address">${addr.address}</div>
                        </div>
                    `).join('')}
                    ${networkInfo.tailscaleIP ? `
                        <div class="network-item">
                            <div class="network-type">📱 Tailscale</div>
                            <div class="network-address">${networkInfo.tailscaleIP}</div>
                        </div>
                    ` : ''}
                </div>
            </div>
            
            <div class="services">
                ${services.map(service => `
                    <div class="service-card">
                        <div class="status-indicator" style="background: ${service.status ? '#4ade80' : '#f87171'}; box-shadow: 0 0 10px ${service.status ? '#4ade80' : '#f87171'};"></div>
                        <div class="service-header">
                            <span class="service-icon">${service.icon}</span>
                            <span class="service-name">${service.name}</span>
                        </div>
                        <div class="service-description">${service.description}</div>
                        <div class="service-links">
                            <a href="http://localhost:${service.port}" class="service-link">
                                🏠 ローカル
                            </a>
                            ${networkInfo.addresses.map(addr => `
                                <a href="http://${addr.address}:${service.port}" class="service-link">
                                    📶 ${addr.address}
                                </a>
                            `).join('')}
                            ${networkInfo.tailscaleIP ? `
                                <a href="http://${networkInfo.tailscaleIP}:${service.port}" class="service-link">
                                    📱 Tailscale
                                </a>
                            ` : ''}
                        </div>
                    </div>
                `).join('')}
            </div>
            
            <div class="footer">
                <p>作者: {{AUTHOR_NAME}} | 起動時刻: ${new Date().toLocaleString('ja-JP')}</p>
            </div>
        </div>
        
        <script>
            // 5秒おきにページを自動リフレッシュ（サービス状態更新）
            setTimeout(() => {
                location.reload();
            }, 30000);
            
            // QRコード表示機能
            function showQR(url) {
                const qrWindow = window.open('', '_blank', 'width=300,height=350');
                qrWindow.document.write(\`
                    <html>
                        <head><title>QR Code</title></head>
                        <body style="text-align:center; padding:20px; font-family:sans-serif;">
                            <h3>📱 QRコード</h3>
                            <img src="https://api.qrserver.com/v1/create-qr-code/?data=\${encodeURIComponent(url)}&size=200x200" alt="QR Code">
                            <p style="word-break:break-all; font-size:12px;">\${url}</p>
                            <button onclick="window.close()">閉じる</button>
                        </body>
                    </html>
                \`);
            }
        </script>
    </body>
    </html>
    `;
    
    res.send(html);
});

// API エンドポイント：システム情報
app.get('/api/info', (req, res) => {
    res.json({
        project: "{{PROJECT_NAME}}",
        description: "{{PROJECT_DESCRIPTION}}",
        author: "{{AUTHOR_NAME}}",
        status: "🚀 運用中",
        timestamp: new Date().toISOString(),
        network: getNetworkInfo(),
        services: {
            opencode: \`http://localhost:\${process.env.OPENCODE_PORT || 4095}\`,
            openchamber: \`http://localhost:\${process.env.OPENCHAMBER_PORT || 3000}\`,
            dashboard: \`http://localhost:\${PORT}\`
        }
    });
});

// ヘルスチェック
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
        services: {
            opencode: checkServiceStatus(process.env.OPENCODE_PORT || 4095),
            openchamber: checkServiceStatus(process.env.OPENCHAMBER_PORT || 3000)
        }
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(\`🚀 {{PROJECT_NAME}} ダッシュボードを起動しました\`);
    console.log(\`📍 http://localhost:\${PORT}\`);
    
    // ネットワーク情報表示
    const networkInfo = getNetworkInfo();
    console.log(\`📡 アクセス可能なURL:\`);
    console.log(\`   🏠 ローカル: http://localhost:\${PORT}\`);
    
    networkInfo.addresses.forEach(addr => {
        console.log(\`   📶 LAN: http://\${addr.address}:\${PORT}\`);
    });
    
    if (networkInfo.tailscaleIP) {
        console.log(\`   📱 Tailscale: http://\${networkInfo.tailscaleIP}:\${PORT}\`);
    }
});