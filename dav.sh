cat > dav.sh <<'EOF'
#!/bin/bash
set -e

echo "====================================================="
echo " 一键安装 WebDAV + tinyfilemanager + HTTPS"
echo " 中文提示 · WebDAV下载 · tinyfilemanager增加/删除/移动文件"
echo "====================================================="

# ===== 交互式输入 =====
read -p "请输入你的域名（必须解析到本机）： " DOMAIN
read -p "请输入 WebDAV 用户名： " DAV_USER
read -s -p "请输入 WebDAV 密码： " DAV_PASS
echo
# ======================

WEB_DIR="/dav"
FM_ALIAS="/fm.php"
WEB_USER="www-data"
WEB_GROUP="www-data"
FM_URL="https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php"

# 安装必要软件
echo "安装 Nginx (带 WebDAV 模块)、PHP、WebDAV、Certbot..."
apt update
apt install -y nginx-extras php-fpm apache2-utils certbot python3-certbot-nginx

# 创建 WebDAV 根目录
mkdir -p $WEB_DIR
chown $WEB_USER:$WEB_GROUP $WEB_DIR
chmod 755 $WEB_DIR

# 设置 WebDAV 用户认证
htpasswd -cb /etc/nginx/.dav_passwd $DAV_USER $DAV_PASS

# 配置 Nginx HTTP 站点（临时用于证书申请）
NGINX_CONF="/etc/nginx/sites-available/webdav_tin.conf"
cat > $NGINX_CONF <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/html;

    location /dav/ {
        alias $WEB_DIR/;
        dav_methods PUT DELETE MKCOL COPY MOVE;
        dav_ext_methods PROPFIND OPTIONS;
        create_full_put_path on;
        autoindex on;
        auth_basic "WebDAV";
        auth_basic_user_file /etc/nginx/.dav_passwd;
    }

    location $FM_ALIAS {
        root /var/www/html;
        index fm.php;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
EOL

# 启用站点并测试
ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# 自动申请 HTTPS 证书
echo "申请 Let’s Encrypt 证书..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# 下载 tinyfilemanager
cd /var/www/html
wget -O fm.php $FM_URL
chown $WEB_USER:$WEB_GROUP fm.php
chmod 644 fm.php

# 配置 tinyfilemanager 根目录为 /dav
sed -i "s|\\\$root_path = __DIR__;|\\\$root_path = '$WEB_DIR';|g" fm.php
sed -i "s|\\\$root_url = '';|\\\$root_url = '/dav';|g" fm.php

echo "====================================================="
echo "安装完成！"
echo "WebDAV 地址（HTTPS）： https://$DOMAIN/dav/"
echo "网页管理器地址（HTTPS）： https://$DOMAIN$FM_ALIAS （直接管理 /dav）"
echo "WebDAV 用户名/密码：$DAV_USER / 你输入的密码"
echo "tinyfilemanager 默认用户名/密码：admin / admin@123（可在 fm.php 内修改）"
echo "证书自动续签已启用"
echo "====================================================="
EOF

chmod +x dav.sh
echo "脚本生成完成，可使用 ./dav.sh 运行安装"
./dav.sh
