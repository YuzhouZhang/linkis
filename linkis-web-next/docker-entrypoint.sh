#!/bin/sh
set -e

# 默认网关地址为 http://linkis-standalone:9001
GATEWAY_URL=${LINKIS_GATEWAY_URL:-http://linkis-standalone:9001}

echo "=== Initializing Linkis-Web-Next ==="
echo "Configuring Gateway Proxy URL: ${GATEWAY_URL}"

# 替换 Nginx 配置文件中的网关地址占位符
sed -i "s|__LINKIS_GATEWAY_URL__|${GATEWAY_URL}|g" /etc/nginx/conf.d/default.conf

exec "$@"
