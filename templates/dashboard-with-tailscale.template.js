// 🚀 {{PROJECT_NAME}} - Tailscale統合ダッシュボード
// 作者: {{AUTHOR_NAME}}  
// 生成日: {{TIMESTAMP}}

const express = require('express');
const { execSync, spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const app = express();
const PORT = process.env.DEV_SERVER_PORT || 8080;

// JSON リクエスト解析
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

// ネットワーク情報取得
function getNetworkInfo() {
    const networkInterfaces = os.networkInterfaces();
    const addresses = [];
    
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
    
    return {
        addresses,
        hostname: os.hostname()
    };
}

// Tailscale状態取得
function getTailscaleStatus() {
    try {
        // Tailscale IP取得
        const ip = execSync('tailscale ip -4 2>/dev/null', { encoding: 'utf8' }).trim();
        
        // Tailscale状態取得
        const statusOutput = execSync('tailscale status --json 2>/dev/null', { encoding: 'utf8' });
        const status = JSON.parse(statusOutput);
        
        return {
            connected: true,
            ip: ip,
            hostname: status.Self?.HostName || 'unknown',
            tailnet: status.Self?.TailscaleIPs?.[0] || ip,
            peers: Object.keys(status.Peer || {}).length,
            lastSeen: status.Self?.LastSeen || new Date().toISOString()
        };
    } catch (e) {
        return {
            connected: false,
            error: e.message,
            ip: null,
            hostname: null,
            tailnet: null,
            peers: 0
        };
    }
}

// .env ファイル読み取り
function readEnvFile() {
    try {
        const envPath = path.join('/workspace', '.env');
        const envContent = fs.readFileSync(envPath, 'utf8');
        const env = {};
        
        envContent.split('\\n').forEach(line => {
            const [key, ...value] = line.split('=');
            if (key && value.length > 0) {
                env[key.trim()] = value.join('=').replace(/^"|"$/g, '');
            }
        });
        
        return env;
    } catch (e) {
        return {};
    }
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
    const tailscaleStatus = getTailscaleStatus();
    const envConfig = readEnvFile();
    
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
                max-width: 1400px;
                margin: 0 auto;
                padding: 20px;
            }
            
            .header {
                text-align: center;
                margin-bottom: 30px;
            }
            
            .title {
                font-size: 2.5rem;
                margin-bottom: 10px;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
            }
            
            .subtitle {
                font-size: 1.1rem;
                opacity: 0.9;
            }
            
            .dashboard-grid {
                display: grid;
                grid-template-columns: 1fr 400px;
                gap: 20px;
                margin-bottom: 30px;
            }
            
            .main-content {
                display: flex;
                flex-direction: column;
                gap: 20px;
            }
            
            .sidebar {
                display: flex;
                flex-direction: column;
                gap: 20px;
            }
            
            .card {
                background: rgba(255,255,255,0.1);
                backdrop-filter: blur(10px);
                border-radius: 15px;
                padding: 25px;
                border: 1px solid rgba(255,255,255,0.2);
            }
            
            .card-title {
                font-size: 1.3rem;
                margin-bottom: 15px;
                display: flex;
                align-items: center;
                gap: 10px;
            }
            
            .tailscale-card {
                ${tailscaleStatus.connected ? 'border-color: #4ade80;' : 'border-color: #f87171;'}
                position: relative;
            }
            
            .tailscale-status {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 15px;
            }
            
            .status-indicator {
                width: 12px;
                height: 12px;
                border-radius: 50%;
                background: ${tailscaleStatus.connected ? '#4ade80' : '#f87171'};
                box-shadow: 0 0 10px ${tailscaleStatus.connected ? '#4ade80' : '#f87171'};
            }
            
            .tailscale-info {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 10px;
                margin-bottom: 15px;
                font-size: 0.9rem;
            }
            
            .info-item {
                background: rgba(255,255,255,0.1);
                padding: 8px 12px;
                border-radius: 6px;
            }
            
            .services {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 20px;
            }
            
            .service-card {
                position: relative;
                transition: transform 0.3s ease;
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
                font-size: 1.2rem;
                font-weight: bold;
            }
            
            .service-links {
                display: flex;
                flex-wrap: wrap;
                gap: 8px;
            }
            
            .service-link {
                padding: 6px 12px;
                background: rgba(255,255,255,0.2);
                text-decoration: none;
                color: white;
                border-radius: 6px;
                font-size: 0.85rem;
                transition: all 0.2s ease;
            }
            
            .service-link:hover {
                background: rgba(255,255,255,0.3);
                transform: scale(1.05);
            }
            
            .btn {
                padding: 10px 20px;
                border: none;
                border-radius: 8px;
                cursor: pointer;
                font-size: 0.9rem;
                transition: all 0.2s ease;
                text-decoration: none;
                display: inline-block;
                text-align: center;
            }
            
            .btn-primary {
                background: #3b82f6;
                color: white;
            }
            
            .btn-primary:hover {
                background: #2563eb;
                transform: translateY(-1px);
            }
            
            .btn-success {
                background: #10b981;
                color: white;
            }
            
            .btn-danger {
                background: #ef4444;
                color: white;
            }
            
            .btn-warning {
                background: #f59e0b;
                color: white;
            }
            
            .btn-group {
                display: flex;
                gap: 8px;
                flex-wrap: wrap;
            }
            
            .input-group {
                margin-bottom: 15px;
            }
            
            .input-group label {
                display: block;
                margin-bottom: 5px;
                font-size: 0.9rem;
            }
            
            .input-group input {
                width: 100%;
                padding: 8px 12px;
                border: 1px solid rgba(255,255,255,0.3);
                border-radius: 6px;
                background: rgba(255,255,255,0.1);
                color: white;
                font-size: 0.9rem;
            }
            
            .input-group input::placeholder {
                color: rgba(255,255,255,0.6);
            }
            
            .network-info {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 10px;
            }
            
            .network-item {
                background: rgba(255,255,255,0.1);
                padding: 10px;
                border-radius: 8px;
                text-align: center;
            }
            
            .network-type {
                font-weight: bold;
                margin-bottom: 5px;
                font-size: 0.85rem;
            }
            
            .network-address {
                font-family: monospace;
                font-size: 0.8rem;
                opacity: 0.8;
            }
            
            .footer {
                text-align: center;
                opacity: 0.7;
                font-size: 0.8rem;
                margin-top: 20px;
            }
            
            @media (max-width: 1024px) {
                .dashboard-grid {
                    grid-template-columns: 1fr;
                }
                
                .sidebar {
                    order: -1;
                }
            }
            
            @media (max-width: 768px) {
                .title {
                    font-size: 1.8rem;
                }
                
                .container {
                    padding: 15px;
                }
                
                .tailscale-info {
                    grid-template-columns: 1fr;
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
            
            <div class="dashboard-grid">
                <div class="main-content">
                    <!-- ネットワーク情報 -->
                    <div class="card">
                        <h2 class="card-title">📡 ネットワークアクセス情報</h2>
                        <div class="network-info">
                            <div class="network-item">
                                <div class="network-type">🏠 ローカル</div>
                                <div class="network-address">localhost</div>
                            </div>
                            ${networkInfo.addresses.map(addr => `
                                <div class="network-item">
                                    <div class="network-type">📶 LAN</div>
                                    <div class="network-address">${addr.address}</div>
                                </div>
                            `).join('')}
                            ${tailscaleStatus.connected ? `
                                <div class="network-item">
                                    <div class="network-type">📱 Tailscale</div>
                                    <div class="network-address">${tailscaleStatus.ip}</div>
                                </div>
                            ` : `
                                <div class="network-item">
                                    <div class="network-type">📱 Tailscale</div>
                                    <div class="network-address">未接続</div>
                                </div>
                            `}
                        </div>
                    </div>
                    
                    <!-- サービス一覧 -->
                    <div class="card">
                        <h2 class="card-title">🛠️ サービス一覧</h2>
                        <div class="services">
                            ${services.map(service => `
                                <div class="service-card card">
                                    <div class="status-indicator" style="position: absolute; top: 15px; right: 15px; background: ${service.status ? '#4ade80' : '#f87171'}; box-shadow: 0 0 10px ${service.status ? '#4ade80' : '#f87171'};"></div>
                                    <div class="service-header">
                                        <span class="service-icon">${service.icon}</span>
                                        <div>
                                            <div class="service-name">${service.name}</div>
                                            <div style="font-size: 0.8rem; opacity: 0.8;">${service.description}</div>
                                        </div>
                                    </div>
                                    <div class="service-links">
                                        <a href="http://localhost:${service.port}" class="service-link" target="_blank">
                                            🏠 ローカル
                                        </a>
                                        ${networkInfo.addresses.map(addr => `
                                            <a href="http://${addr.address}:${service.port}" class="service-link" target="_blank">
                                                📶 ${addr.address}
                                            </a>
                                        `).join('')}
                                        ${tailscaleStatus.connected ? `
                                            <a href="http://${tailscaleStatus.ip}:${service.port}" class="service-link" target="_blank">
                                                📱 Tailscale
                                            </a>
                                        ` : ''}
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                </div>
                
                <div class="sidebar">
                    <!-- Tailscale制御パネル -->
                    <div class="card tailscale-card">
                        <div class="tailscale-status">
                            <h2 class="card-title">🔗 Tailscale</h2>
                            <div class="status-indicator"></div>
                        </div>
                        
                        ${tailscaleStatus.connected ? `
                            <div class="tailscale-info">
                                <div class="info-item">
                                    <strong>IP:</strong><br>
                                    ${tailscaleStatus.ip}
                                </div>
                                <div class="info-item">
                                    <strong>ホスト名:</strong><br>
                                    ${tailscaleStatus.hostname}
                                </div>
                                <div class="info-item">
                                    <strong>接続デバイス:</strong><br>
                                    ${tailscaleStatus.peers} 台
                                </div>
                                <div class="info-item">
                                    <strong>状態:</strong><br>
                                    ✅ 接続中
                                </div>
                            </div>
                            
                            <div class="btn-group">
                                <button class="btn btn-warning" onclick="restartTailscale()">
                                    🔄 再接続
                                </button>
                                <button class="btn btn-danger" onclick="stopTailscale()">
                                    ⏹️ 停止
                                </button>
                                <button class="btn btn-primary" onclick="showQR('http://${tailscaleStatus.ip}:3000')">
                                    📱 QRコード
                                </button>
                            </div>
                        ` : `
                            <p style="margin-bottom: 15px; opacity: 0.8;">
                                リモートアクセスを有効にするには、Tailscale Auth Keyが必要です。
                            </p>
                            
                            <div class="input-group">
                                <label>🔑 Auth Key:</label>
                                <input type="password" id="authKey" placeholder="tskey-auth-xxxxxxxxxx" 
                                       value="${envConfig.TAILSCALE_AUTH_KEY || ''}" />
                            </div>
                            
                            <div class="input-group">
                                <label>🏷️ ホスト名 (オプション):</label>
                                <input type="text" id="hostname" placeholder="my-project-dev" 
                                       value="${envConfig.TAILSCALE_HOSTNAME || '{{PROJECT_NAME}}-dev'}" />
                            </div>
                            
                            <div class="btn-group">
                                <button class="btn btn-primary" onclick="setupTailscale()">
                                    🚀 接続開始
                                </button>
                                <button class="btn btn-primary" onclick="window.open('https://login.tailscale.com/admin/settings/keys', '_blank')">
                                    🔑 Auth Key取得
                                </button>
                            </div>
                        `}
                    </div>
                    
                    <!-- システム情報 -->
                    <div class="card">
                        <h2 class="card-title">💻 システム情報</h2>
                        <div class="info-item" style="margin-bottom: 10px;">
                            <strong>ホスト名:</strong> ${networkInfo.hostname}
                        </div>
                        <div class="info-item" style="margin-bottom: 10px;">
                            <strong>起動時間:</strong> ${new Date().toLocaleString('ja-JP')}
                        </div>
                        <div class="info-item">
                            <strong>作者:</strong> {{AUTHOR_NAME}}
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="footer">
                <p>🚀 {{PROJECT_NAME}} Dashboard | 最終更新: ${new Date().toLocaleString('ja-JP')}</p>
            </div>
        </div>
        
        <script>
            // 30秒おきにページ自動リフレッシュ
            setTimeout(() => location.reload(), 30000);
            
            // Tailscale制御関数
            async function setupTailscale() {
                const authKey = document.getElementById('authKey').value;
                const hostname = document.getElementById('hostname').value;
                
                if (!authKey || authKey === 'tskey-auth-xxxxxxxxxxxxxxxxx') {
                    alert('有効なAuth Keyを入力してください');
                    return;
                }
                
                const btn = event.target;
                btn.disabled = true;
                btn.textContent = '🔄 接続中...';
                
                try {
                    const response = await fetch('/api/tailscale/setup', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ authKey, hostname })
                    });
                    
                    const result = await response.json();
                    
                    if (result.success) {
                        alert('✅ Tailscale接続成功！ページを再読み込みします。');
                        location.reload();
                    } else {
                        alert('❌ 接続失敗: ' + (result.error || '不明なエラー'));
                    }
                } catch (error) {
                    alert('❌ 接続エラー: ' + error.message);
                } finally {
                    btn.disabled = false;
                    btn.textContent = '🚀 接続開始';
                }
            }
            
            async function stopTailscale() {
                if (!confirm('Tailscaleを停止しますか？')) return;
                
                try {
                    const response = await fetch('/api/tailscale/stop', { method: 'POST' });
                    const result = await response.json();
                    
                    if (result.success) {
                        alert('✅ Tailscaleを停止しました');
                        location.reload();
                    } else {
                        alert('❌ 停止失敗: ' + result.error);
                    }
                } catch (error) {
                    alert('❌ エラー: ' + error.message);
                }
            }
            
            async function restartTailscale() {
                if (!confirm('Tailscaleを再接続しますか？')) return;
                
                try {
                    const response = await fetch('/api/tailscale/restart', { method: 'POST' });
                    const result = await response.json();
                    
                    if (result.success) {
                        alert('✅ 再接続しました');
                        location.reload();
                    } else {
                        alert('❌ 再接続失敗: ' + result.error);
                    }
                } catch (error) {
                    alert('❌ エラー: ' + error.message);
                }
            }
            
            // QRコード表示
            function showQR(url) {
                const qrWindow = window.open('', '_blank', 'width=300,height=350');
                qrWindow.document.write(\`
                    <html>
                        <head><title>📱 QRコード</title></head>
                        <body style="text-align:center; padding:20px; font-family:sans-serif;">
                            <h3>📱 QRコード</h3>
                            <img src="https://api.qrserver.com/v1/create-qr-code/?data=\${encodeURIComponent(url)}&size=200x200" alt="QR Code">
                            <p style="word-break:break-all; font-size:12px;">\${url}</p>
                            <button onclick="window.close()" style="padding:10px 20px; margin-top:10px;">閉じる</button>
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

// API: Tailscale セットアップ
app.post('/api/tailscale/setup', async (req, res) => {
    try {
        const { authKey, hostname } = req.body;
        
        if (!authKey) {
            return res.json({ success: false, error: 'Auth Key is required' });
        }
        
        // .env ファイル更新
        const envPath = path.join('/workspace', '.env');
        let envContent = '';
        
        try {
            envContent = fs.readFileSync(envPath, 'utf8');
        } catch (e) {
            envContent = '';
        }
        
        // Auth Key 更新
        if (envContent.includes('TAILSCALE_AUTH_KEY=')) {
            envContent = envContent.replace(
                /TAILSCALE_AUTH_KEY=.*/,
                \`TAILSCALE_AUTH_KEY="\${authKey}"\`
            );
        } else {
            envContent += \`\\nTAILSCALE_AUTH_KEY="\${authKey}"\`;
        }
        
        // ホスト名更新
        if (hostname) {
            if (envContent.includes('TAILSCALE_HOSTNAME=')) {
                envContent = envContent.replace(
                    /TAILSCALE_HOSTNAME=.*/,
                    \`TAILSCALE_HOSTNAME="\${hostname}"\`
                );
            } else {
                envContent += \`\\nTAILSCALE_HOSTNAME="\${hostname}"\`;
            }
        }
        
        fs.writeFileSync(envPath, envContent);
        
        // Tailscale 起動
        execSync('sudo tailscaled --state-dir=/var/lib/tailscale --socket=/run/tailscale/tailscaled.sock &', { stdio: 'ignore' });
        
        // 認証
        setTimeout(() => {
            try {
                const cmd = hostname 
                    ? \`sudo tailscale up --auth-key="\${authKey}" --hostname="\${hostname}"\`
                    : \`sudo tailscale up --auth-key="\${authKey}"\`;
                    
                execSync(cmd);
                console.log('✅ Tailscale setup completed');
            } catch (e) {
                console.error('❌ Tailscale setup failed:', e.message);
            }
        }, 2000);
        
        res.json({ success: true });
        
    } catch (error) {
        console.error('Tailscale setup error:', error);
        res.json({ success: false, error: error.message });
    }
});

// API: Tailscale 停止
app.post('/api/tailscale/stop', async (req, res) => {
    try {
        execSync('sudo tailscale down');
        res.json({ success: true });
    } catch (error) {
        console.error('Tailscale stop error:', error);
        res.json({ success: false, error: error.message });
    }
});

// API: Tailscale 再接続
app.post('/api/tailscale/restart', async (req, res) => {
    try {
        // 現在の設定を取得
        const envConfig = readEnvFile();
        const authKey = envConfig.TAILSCALE_AUTH_KEY;
        const hostname = envConfig.TAILSCALE_HOSTNAME;
        
        if (!authKey || authKey === 'tskey-auth-xxxxxxxxxxxxxxxxx') {
            return res.json({ success: false, error: 'Valid Auth Key not found' });
        }
        
        // 停止 → 再起動
        execSync('sudo tailscale down');
        
        setTimeout(() => {
            try {
                const cmd = hostname 
                    ? \`sudo tailscale up --auth-key="\${authKey}" --hostname="\${hostname}"\`
                    : \`sudo tailscale up --auth-key="\${authKey}"\`;
                    
                execSync(cmd);
                console.log('✅ Tailscale restart completed');
            } catch (e) {
                console.error('❌ Tailscale restart failed:', e.message);
            }
        }, 1000);
        
        res.json({ success: true });
        
    } catch (error) {
        console.error('Tailscale restart error:', error);
        res.json({ success: false, error: error.message });
    }
});

// API: システム情報
app.get('/api/info', (req, res) => {
    res.json({
        project: "{{PROJECT_NAME}}",
        description: "{{PROJECT_DESCRIPTION}}",
        author: "{{AUTHOR_NAME}}",
        status: "🚀 運用中",
        timestamp: new Date().toISOString(),
        network: getNetworkInfo(),
        tailscale: getTailscaleStatus(),
        services: {
            opencode: \`http://localhost:\${process.env.OPENCODE_PORT || 4095}\`,
            openchamber: \`http://localhost:\${process.env.OPENCHAMBER_PORT || 3000}\`,
            dashboard: \`http://localhost:\${PORT}\`
        }
    });
});

// ヘルスチェック
app.get('/health', (req, res) => {
    const tailscaleStatus = getTailscaleStatus();
    
    res.json({ 
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
        services: {
            opencode: checkServiceStatus(process.env.OPENCODE_PORT || 4095),
            openchamber: checkServiceStatus(process.env.OPENCHAMBER_PORT || 3000),
            tailscale: tailscaleStatus.connected
        }
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(\`🚀 {{PROJECT_NAME}} 統合ダッシュボードを起動しました\`);
    console.log(\`📍 http://localhost:\${PORT}\`);
    
    const networkInfo = getNetworkInfo();
    const tailscaleStatus = getTailscaleStatus();
    
    console.log(\`📡 アクセス可能なURL:\`);
    console.log(\`   🏠 ローカル: http://localhost:\${PORT}\`);
    
    networkInfo.addresses.forEach(addr => {
        console.log(\`   📶 LAN: http://\${addr.address}:\${PORT}\`);
    });
    
    if (tailscaleStatus.connected) {
        console.log(\`   📱 Tailscale: http://\${tailscaleStatus.ip}:\${PORT}\`);
    }
});