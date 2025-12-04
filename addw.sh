cat > addw.sh << 'EOF'
#!/bin/bash

# tinyfilemanager 文件路径（固定路径）
FM_FILE="/var/www/html/fm.php"

if [ ! -f "$FM_FILE" ]; then
  echo "错误：找不到 $FM_FILE"
  exit 1
fi

# 交互式输入新用户名和密码
read -p "请输入新用户名： " NEW_USER
read -p "请输入新密码（建议长度 ≥12 位）： " NEW_PASS

# 如果没有输入密码，则使用默认密码 'admin'
NEW_PASS="${NEW_PASS:-admin}"

# 生成 bcrypt 哈希
HASH=$(php -r "echo password_hash('$NEW_PASS', PASSWORD_BCRYPT);")

# 删除旧的同名用户条目（如果存在）
sed -i "/'$NEW_USER' *=>/d" "$FM_FILE"

# 插入或替换用户条目
sed -i "/\$auth_users *= *array(/a \    '$NEW_USER' => '$HASH'," "$FM_FILE"

echo "----------------------------------"
echo "fm.php 用户已更新！"
echo "用户名：$NEW_USER"
echo "密码：$NEW_PASS"
echo "----------------------------------"
EOF

# 给脚本执行权限
chmod +x addw.sh

# 执行脚本
./addw.sh
