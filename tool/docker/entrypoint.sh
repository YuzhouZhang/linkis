#!/bin/bash
set -e

MYSQL_HOST=${MYSQL_HOST:-test-mysql-init}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_DB=${MYSQL_DB:-linkis}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-123456}
SERVER_HEAP_SIZE=${SERVER_HEAP_SIZE:-512M}

echo "=========================================================="
echo "Initializing Linkis Environment with MySQL: ${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}"
echo "=========================================================="

CONF_DIR=/opt/linkis/conf
LINKIS_PROPERTIES=${CONF_DIR}/linkis.properties
LINKIS_ENV=${CONF_DIR}/linkis-env.sh
DB_SH=${CONF_DIR}/db.sh

# 1. 确保 .bash_profile 存在并包含环境配置
touch ~/.bash_profile
echo "export JAVA_HOME=${JAVA_HOME}" > ~/.bash_profile
echo "export LINKIS_HOME=/opt/linkis" >> ~/.bash_profile
echo "export LINKIS_CONF_DIR=/opt/linkis/conf" >> ~/.bash_profile
echo "export PATH=/opt/linkis/bin:/opt/linkis/sbin:\$PATH" >> ~/.bash_profile
source ~/.bash_profile

# 2. 等待 MySQL 就绪
echo "Checking MySQL connection to ${MYSQL_HOST}:${MYSQL_PORT}..."
MAX_RETRY=30
COUNT=0
while ! (echo > /dev/tcp/${MYSQL_HOST}/${MYSQL_PORT}) 2>/dev/null; do
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $MAX_RETRY ]; then
        echo "WARNING: MySQL ${MYSQL_HOST}:${MYSQL_PORT} not reachable after ${MAX_RETRY} attempts, continuing anyway..."
        break
    fi
    echo "Waiting for MySQL ${MYSQL_HOST}:${MYSQL_PORT}... (${COUNT}/${MAX_RETRY})"
    sleep 2
done

# 3. 注入 linkis-env.sh
cat << ENVEOF > "$LINKIS_ENV"
export LINKIS_VERSION=1.8.0
export LINKIS_HOME=/opt/linkis
export LINKIS_CONF_DIR=/opt/linkis/conf
export LINKIS_LOG_DIR=/opt/linkis/logs
export LINKIS_PUBLIC_MODULE=lib/linkis-commons/public-module
export ENGINE_CONN_HOME=/opt/linkis/lib/linkis-engineconn-plugins

export EUREKA_INSTALL_IP=127.0.0.1
export GATEWAY_INSTALL_IP=127.0.0.1
export MANAGER_INSTALL_IP=127.0.0.1
export ENTRANCE_INSTALL_IP=127.0.0.1
export ENGINECONNMANAGER_INSTALL_IP=127.0.0.1
export PUBLICSERVICE_INSTALL_IP=127.0.0.1

export EUREKA_PORT=20303
export GATEWAY_PORT=9001
export MANAGER_PORT=9101
export ENTRANCE_PORT=9104
export ENGINECONNMANAGER_PORT=9102
export PUBLICSERVICE_PORT=9105

export SERVER_HEAP_SIZE="${SERVER_HEAP_SIZE}"
export ENABLE_HDFS=false
export ENABLE_HIVE=false
export ENABLE_SPARK=false
ENVEOF

# 4. 生成 db.sh (用于 clear-server.sh)
cat << DBEOF > "$DB_SH"
dbType=mysql
MYSQL_HOST=${MYSQL_HOST}
MYSQL_PORT=${MYSQL_PORT}
MYSQL_DB=${MYSQL_DB}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
DBEOF

# 5. 配置 linkis.properties
if [ -f "$LINKIS_PROPERTIES" ]; then
    sed -i "s|wds.linkis.server.version=.*|wds.linkis.server.version=v1|g" "$LINKIS_PROPERTIES"
    sed -i "s|wds.linkis.server.mybatis.datasource.url=.*|wds.linkis.server.mybatis.datasource.url=jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}?characterEncoding=UTF-8\&useSSL=false\&allowPublicKeyRetrieval=true\&serverTimezone=Asia/Shanghai|g" "$LINKIS_PROPERTIES"
    sed -i "s|wds.linkis.server.mybatis.datasource.username=.*|wds.linkis.server.mybatis.datasource.username=${MYSQL_USER}|g" "$LINKIS_PROPERTIES"
    sed -i "s|wds.linkis.server.mybatis.datasource.password=.*|wds.linkis.server.mybatis.datasource.password=${MYSQL_PASSWORD}|g" "$LINKIS_PROPERTIES"
    sed -i "s|wds.linkis.server.mybatis.datasource.driver-class-name=.*|wds.linkis.server.mybatis.datasource.driver-class-name=com.mysql.cj.jdbc.Driver|g" "$LINKIS_PROPERTIES"
    grep -q "wds.linkis.engineconn.home" "$LINKIS_PROPERTIES" || echo "wds.linkis.engineconn.home=/opt/linkis/lib/linkis-engineconn-plugins" >> "$LINKIS_PROPERTIES"
    grep -q "wds.linkis.engineconn.plugin.home" "$LINKIS_PROPERTIES" || echo "wds.linkis.engineconn.plugin.home=/opt/linkis/lib/linkis-engineconn-plugins" >> "$LINKIS_PROPERTIES"
fi

# 同步配置到 /etc/linkis-conf
mkdir -p /etc/linkis-conf
cp -rn /opt/linkis/conf/* /etc/linkis-conf/ 2>/dev/null || true

# 6. 清理旧锁和 pid
rm -rf /opt/linkis/sbin/ext/*.pid /opt/linkis/logs/*.pid 2>/dev/null || true

# 7. 启动 Linkis 服务
echo "Executing /opt/linkis/sbin/linkis-start-all.sh..."
export LINKIS_HOME=/opt/linkis
export LINKIS_CONF_DIR=/opt/linkis/conf
/opt/linkis/sbin/linkis-start-all.sh || true

echo "Linkis startup sequence completed. Container is active and tailing logs..."
sleep 2

# 8. 保持前台常驻并输出日志
tail -F /opt/linkis/logs/*.out /opt/linkis/logs/*.log 2>/dev/null || tail -f /dev/null
