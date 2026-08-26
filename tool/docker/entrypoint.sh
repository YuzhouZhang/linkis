#!/bin/bash

MYSQL_HOST=${MYSQL_HOST:-test-mysql-init}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_DB=${MYSQL_DB:-linkis}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-123456}

echo "=========================================================="
echo "Initializing Linkis Environment with MySQL: ${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}"
echo "=========================================================="

CONF_DIR=/opt/linkis/conf
LINKIS_PROPERTIES=${CONF_DIR}/linkis.properties
LINKIS_ENV=${CONF_DIR}/linkis-env.sh

# 确保 .bash_profile 存在并包含环境配置
touch ~/.bash_profile
echo "export JAVA_HOME=${JAVA_HOME}" > ~/.bash_profile
echo "export LINKIS_HOME=/opt/linkis" >> ~/.bash_profile
echo "export LINKIS_CONF_DIR=/opt/linkis/conf" >> ~/.bash_profile
echo "export PATH=/opt/linkis/bin:/opt/linkis/sbin:\$PATH" >> ~/.bash_profile
source ~/.bash_profile

if [ -f "/opt/linkis/linkis-env.sh" ] && [ ! -f "$LINKIS_ENV" ]; then
    cp /opt/linkis/linkis-env.sh "$LINKIS_ENV"
fi

# 配置 linkis-env.sh 中的 MySQL 连接
if [ -f "$LINKIS_ENV" ]; then
    sed -i "s#^MYSQL_HOST=.*#MYSQL_HOST=${MYSQL_HOST}#g" "$LINKIS_ENV" 2>/dev/null || true
    sed -i "s#^MYSQL_PORT=.*#MYSQL_PORT=${MYSQL_PORT}#g" "$LINKIS_ENV" 2>/dev/null || true
    sed -i "s#^MYSQL_DB=.*#MYSQL_DB=${MYSQL_DB}#g" "$LINKIS_ENV" 2>/dev/null || true
    sed -i "s#^MYSQL_USER=.*#MYSQL_USER=${MYSQL_USER}#g" "$LINKIS_ENV" 2>/dev/null || true
    sed -i "s#^MYSQL_PASSWORD=.*#MYSQL_PASSWORD=${MYSQL_PASSWORD}#g" "$LINKIS_ENV" 2>/dev/null || true
    sed -i "s#^EUREKA_INSTALL_IP=.*#EUREKA_INSTALL_IP=127.0.0.1#g" "$LINKIS_ENV" 2>/dev/null || true
    sed -i "s#^GATEWAY_INSTALL_IP=.*#GATEWAY_INSTALL_IP=0.0.0.0#g" "$LINKIS_ENV" 2>/dev/null || true
fi

# 配置 linkis.properties
if [ -f "$LINKIS_PROPERTIES" ]; then
    sed -i "s#wds.linkis.server.mybatis.datasource.url=.*#wds.linkis.server.mybatis.datasource.url=jdbc:mysql://${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DB}?characterEncoding=UTF-8\&serverTimezone=Asia/Shanghai#g" "$LINKIS_PROPERTIES" 2>/dev/null || true
    sed -i "s#wds.linkis.server.mybatis.datasource.username=.*#wds.linkis.server.mybatis.datasource.username=${MYSQL_USER}#g" "$LINKIS_PROPERTIES" 2>/dev/null || true
    sed -i "s#wds.linkis.server.mybatis.datasource.password=.*#wds.linkis.server.mybatis.datasource.password=${MYSQL_PASSWORD}#g" "$LINKIS_PROPERTIES" 2>/dev/null || true
fi

# 清理旧锁和 pid
rm -rf /opt/linkis/sbin/ext/*.pid /opt/linkis/logs/*.pid 2>/dev/null || true

# 启动 Linkis 服务（不因检查报错中断容器）
echo "Executing /opt/linkis/sbin/linkis-start-all.sh..."
/bin/bash /opt/linkis/sbin/linkis-start-all.sh || true

echo "Linkis startup sequence completed. Container is active and tailing logs..."
sleep 3

# 保持前台常驻并输出日志
tail -F /opt/linkis/logs/*.out /opt/linkis/logs/*.log 2>/dev/null || tail -f /dev/null
