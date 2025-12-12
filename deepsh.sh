# 1. 创建安装脚本
cat > install_nginx_custom.sh << 'SCRIPT_EOF'
#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否以root用户运行
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}错误：此脚本必须以root权限运行${NC}"
    exit 1
fi

# 显示欢迎信息
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               Nginx 一键安装配置脚本                    ║${NC}"
echo -e "${BLUE}║          支持自定义访问路径和SSL证书安装                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"

# 更新系统包列表
echo -e "${YELLOW}[1/9] 正在更新系统包列表...${NC}"
apt-get update -y

# 安装Nginx
echo -e "${YELLOW}[2/9] 正在安装Nginx...${NC}"
apt-get install -y nginx

# 检查Nginx是否安装成功
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}❌ Nginx安装失败！${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Nginx安装成功！${NC}"

# 交互式输入自定义网站目录
echo -e "${YELLOW}[3/9] 设置自定义网站目录${NC}"
read -p "请输入自定义网站目录的完整路径（例如：/vv/mywebsite）： " CUSTOM_DIR

# 交互式输入访问路径名称
echo -e "\n请输入用于访问该目录的URL路径名称（例如：输入'mysite'将使用'http://域名/mysite/'访问）："
read -p "> " URL_PATH

# 验证URL路径是否合法
if [[ ! "$URL_PATH" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}❌ 路径名称只能包含字母、数字、下划线和连字符！${NC}"
    exit 1
fi

# 创建自定义目录并设置权限
if [[ ! -d "$CUSTOM_DIR" ]]; then
    echo -e "${YELLOW}创建目录 $CUSTOM_DIR ...${NC}"
    mkdir -p "$CUSTOM_DIR"
fi

# 设置目录权限
chown -R www-data:www-data "$CUSTOM_DIR"
chmod -R 755 "$CUSTOM_DIR"

# 创建测试HTML文件
echo -e "${YELLOW}[4/9] 创建测试页面...${NC}"

# 默认目录的测试文件
DEFAULT_DIR="/var/www/html"
cat > "$DEFAULT_DIR/index.html" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>默认网站目录 - Nginx安装成功</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background-color: #f0f0f0;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            max-width: 600px;
            margin: 0 auto;
        }
        h1 {
            color: #333;
        }
        .info {
            background: #e8f4f8;
            padding: 15px;
            border-left: 4px solid #3498db;
            margin: 20px 0;
            text-align: left;
        }
        .path {
            font-family: monospace;
            background: #f7f7f7;
            padding: 5px 10px;
            border-radius: 4px;
        }
        a {
            color: #3498db;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Nginx 安装成功！</h1>
        <p>这是一个默认网站目录的测试页面</p>
        
        <div class="info">
            <strong>网站路径：</strong>
            <span class="path">/var/www/html</span>
        </div>
        
        <div class="info">
            <strong>服务器信息：</strong><br>
            服务器名称：<script>document.write(window.location.hostname)</script><br>
            系统：Debian<br>
            时间：<script>document.write(new Date().toLocaleString())</script>
        </div>
        
        <p><a href="/CUSTOM_PATH/">➡️ 点击这里访问自定义网站</a></p>
    </div>
</body>
</html>
HTML_EOF

# 替换自定义路径占位符
sed -i "s|/CUSTOM_PATH/|/$URL_PATH/|g" "$DEFAULT_DIR/index.html"

# 自定义目录的测试文件
cat > "$CUSTOM_DIR/index.html" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>自定义网站 - CUSTOM_PATH</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            padding: 40px;
            border-radius: 15px;
            max-width: 600px;
            margin: 0 auto;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        h1 {
            font-size: 2.5em;
            margin-bottom: 20px;
        }
        .path-display {
            background: rgba(255, 255, 255, 0.2);
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            font-family: 'Courier New', monospace;
            font-size: 1.1em;
            word-break: break-all;
        }
        .success-badge {
            background: #2ecc71;
            color: white;
            padding: 8px 20px;
            border-radius: 20px;
            display: inline-block;
            margin: 15px 0;
            font-weight: bold;
        }
        .nav-links a {
            color: white;
            background: rgba(255, 255, 255, 0.2);
            padding: 10px 20px;
            border-radius: 5px;
            text-decoration: none;
            margin: 0 10px;
            display: inline-block;
            transition: all 0.3s;
        }
        .nav-links a:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-badge">✅ 自定义网站运行正常</div>
        <h1>自定义网站目录</h1>
        <p>这个页面来自您自定义的网站目录</p>
        
        <div class="path-display">
            访问路径：/CUSTOM_PATH/<br>
            磁盘路径：CUSTOM_DIR
        </div>
        
        <div class="nav-links">
            <a href="/">返回默认网站</a>
            <a href="https://nginx.org" target="_blank">Nginx官网</a>
        </div>
        
        <div style="margin-top: 30px; font-size: 0.9em; opacity: 0.8;">
            服务器时间：<script>document.write(new Date().toLocaleString())</script>
        </div>
    </div>
</body>
</html>
HTML_EOF

# 替换自定义路径占位符
sed -i "s|CUSTOM_PATH|$URL_PATH|g" "$CUSTOM_DIR/index.html"
sed -i "s|CUSTOM_DIR|$CUSTOM_DIR|g" "$CUSTOM_DIR/index.html"

# 配置Nginx
echo -e "${YELLOW}[5/9] 配置Nginx...${NC}"

# 备份原始配置文件
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# 创建新的配置
cat > /etc/nginx/sites-available/default << 'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # 自定义目录访问配置
    location /URL_PATH/ {
        alias CUSTOM_DIR/;
        try_files $uri $uri/ /URL_PATH/index.html =404;
        
        # 确保正确的内容类型
        location ~* \.(?:html|htm)$ {
            add_header Content-Type text/html;
        }
        
        location ~* \.(?:css|js)$ {
            add_header Content-Type text/css;
        }
        
        location ~* \.(?:jpg|jpeg|png|gif|ico|svg)$ {
            add_header Content-Type image/jpeg;
        }
    }
}

# 可选：为自定义目录配置独立服务器块（监听不同端口）
server {
    listen 8080;
    listen [::]:8080;
    
    root CUSTOM_DIR;
    index index.html index.htm;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX_EOF

# 替换路径变量
sed -i "s|URL_PATH|$URL_PATH|g" /etc/nginx/sites-available/default
sed -i "s|CUSTOM_DIR|$CUSTOM_DIR|g" /etc/nginx/sites-available/default

# 测试Nginx配置
echo -e "${YELLOW}[6/9] 测试Nginx配置...${NC}"
if nginx -t; then
    echo -e "${GREEN}✅ Nginx配置测试通过！${NC}"
else
    echo -e "${RED}❌ Nginx配置测试失败，请检查配置${NC}"
    exit 1
fi

# 重启Nginx服务
echo -e "${YELLOW}[7/9] 重启Nginx服务...${NC}"
systemctl restart nginx
systemctl enable nginx

# 询问是否安装SSL证书
echo -e "${YELLOW}[8/9] SSL证书配置${NC}"
read -p "是否安装SSL证书（需要域名）？ [y/N]: " INSTALL_SSL

SSL_CONFIGURED=false
if [[ "$INSTALL_SSL" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}安装Certbot以获取SSL证书...${NC}"
    
    # 检查是否已安装Certbot
    if ! command -v certbot &> /dev/null; then
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # 获取域名信息
    echo -e "请输入您的域名（例如：example.com）："
    read -p "> " DOMAIN_NAME
    
    if [[ -n "$DOMAIN_NAME" ]]; then
        echo -e "${YELLOW}正在为 $DOMAIN_NAME 获取SSL证书...${NC}"
        
        # 尝试获取证书
        if certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "admin@$DOMAIN_NAME"; then
            echo -e "${GREEN}✅ SSL证书安装成功！${NC}"
            SSL_CONFIGURED=true
        else
            echo -e "${YELLOW}⚠️ SSL证书获取失败，请稍后手动运行：certbot --nginx${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ 未输入域名，跳过SSL安装${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ 跳过SSL证书安装${NC}"
fi

# 配置防火墙（如果启用了ufw）
echo -e "${YELLOW}[9/9] 配置防火墙...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 'Nginx HTTP'
    ufw allow 'Nginx HTTPS'
    echo -e "${GREEN}✅ 防火墙规则已添加${NC}"
fi

# 显示完成信息
SERVER_IP=$(hostname -I | awk '{print $1}')
if [[ -z "$SERVER_IP" ]]; then
    SERVER_IP="127.0.0.1"
fi

echo -e "\n${GREEN}✨ ✨ ✨ 安装配置完成！ ✨ ✨ ✨${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📁 目录配置：${NC}"
echo -e "  默认网站目录: ${GREEN}/var/www/html${NC}"
echo -e "  自定义网站目录: ${GREEN}$CUSTOM_DIR${NC}"
echo ""
echo -e "${YELLOW}🌐 访问方式：${NC}"
echo -e "  默认网站: ${GREEN}http://$SERVER_IP/${NC}"
echo -e "  自定义网站: ${GREEN}http://$SERVER_IP/$URL_PATH/${NC}"
echo -e "  独立端口: ${GREEN}http://$SERVER_IP:8080/${NC}"

if [ "$SSL_CONFIGURED" = true ]; then
    echo -e "  HTTPS网站: ${GREEN}https://$DOMAIN_NAME/${NC}"
    echo -e "  HTTPS自定义网站: ${GREEN}https://$DOMAIN_NAME/$URL_PATH/${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 服务状态：${NC}"
nginx_status=$(systemctl is-active nginx)
if [ "$nginx_status" = "active" ]; then
    echo -e "  ✅ Nginx服务状态: ${GREEN}运行中${NC}"
else
    echo -e "  ❌ Nginx服务状态: ${RED}未运行${NC}"
fi

echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
echo -e "  使用以下命令测试访问："
echo -e "  curl -I http://$SERVER_IP/"
echo -e "  curl -I http://$SERVER_IP/$URL_PATH/"
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
SCRIPT_EOF

# 2. 为脚本添加执行权限
chmod +x install_nginx_custom.sh

# 3. 显示脚本已创建
echo "✅ 脚本文件已创建：install_nginx_custom.sh"
echo "✅ 脚本权限已设置"
echo ""
echo "📋 脚本内容摘要："
echo "────────────────────────────────────"
echo "• 自动安装 Nginx"
echo "• 配置自定义网站目录"
echo "• 支持通过 /自定义路径/ 访问"
echo "• 可选 SSL 证书安装"
echo "• 创建测试 HTML 页面"
echo "────────────────────────────────────"
echo ""
echo "⚠️  注意：此脚本需要 root 权限运行"
echo ""
echo "🔧 请选择执行方式："
echo "1) 直接运行脚本（需要root权限）"
echo "2) 查看脚本内容"
echo "3) 退出"
echo ""
read -p "请输入选择 (1-3): " choice

case $choice in
    1)
        echo "🚀 正在执行安装脚本..."
        echo "────────────────────────────────────"
        sudo bash install_nginx_custom.sh
        ;;
    2)
        echo "📄 显示脚本内容（前50行）："
        echo "────────────────────────────────────"
        head -50 install_nginx_custom.sh
        echo "..."
        echo "────────────────────────────────────"
        echo "要查看完整脚本，请运行: cat install_nginx_custom.sh"
        ;;
    3)
        echo "👋 退出"
        exit 0
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac
