#!/bin/bash
set -e

echo "=== 1. 初始化 hadoop 用户环境与配置 ==="
mkdir -p /home/hadoop
touch /home/hadoop/.bash_profile

mkdir -p /appcom/Install
ln -sfn /opt/linkis /appcom/Install/LinkisInstall

mkdir -p /etc/linkis-conf
cp -rn /opt/linkis/conf/* /etc/linkis-conf/ 2>/dev/null || true

echo "=== 2. 分发 MySQL 驱动 ==="
JAR=$(find /opt/linkis /tmp /root -name "*mysql-connector*.jar" 2>/dev/null | head -n 1)
if [ -n "$JAR" ]; then
  mkdir -p /opt/linkis/lib/linkis-commons/public-module
  cp "$JAR" /opt/linkis/lib/linkis-commons/public-module/ 2>/dev/null || true
  for dir in /opt/linkis/lib/linkis-computation-governance/* /opt/linkis/lib/linkis-public-enhancements/* /opt/linkis/lib/linkis-spring-cloud-services/*; do
    if [ -d "$dir" ]; then
      cp "$JAR" "$dir/" 2>/dev/null || true
    fi
  done
fi

echo "=== 3. 注入环境变量与配置 ==="
for env in /opt/linkis/conf/linkis-env.sh /etc/linkis-conf/linkis-env.sh; do
  cat << "ENVEOF" > "$env"
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

export SERVER_HEAP_SIZE="512M"
export ENABLE_HDFS=false
export ENABLE_HIVE=false
export ENABLE_SPARK=false
ENVEOF
done

# 生成 db.sh 供 clear-server.sh 和相关脚本使用
cat << "DBEOF" > /opt/linkis/conf/db.sh
dbType=mysql
MYSQL_HOST=test-mysql-init
MYSQL_PORT=3306
MYSQL_DB=linkis
MYSQL_USER=root
MYSQL_PASSWORD=123456
DBEOF
cp /opt/linkis/conf/db.sh /etc/linkis-conf/db.sh 2>/dev/null || true

for cfg in /opt/linkis/conf/linkis.properties /etc/linkis-conf/linkis.properties; do
  sed -i "s|wds.linkis.server.version=.*|wds.linkis.server.version=v1|g" "$cfg"
  sed -i "s|wds.linkis.server.mybatis.datasource.url=.*|wds.linkis.server.mybatis.datasource.url=jdbc:mysql://test-mysql-init:3306/linkis?characterEncoding=UTF-8\&useSSL=false\&allowPublicKeyRetrieval=true\&serverTimezone=Asia/Shanghai|g" "$cfg"
  sed -i "s|wds.linkis.server.mybatis.datasource.username=.*|wds.linkis.server.mybatis.datasource.username=root|g" "$cfg"
  sed -i "s|wds.linkis.server.mybatis.datasource.password=.*|wds.linkis.server.mybatis.datasource.password=123456|g" "$cfg"
  sed -i "s|wds.linkis.filesystem.hdfs.root.path=.*|wds.linkis.filesystem.hdfs.root.path=file:///tmp/linkis/|g" "$cfg"
  sed -i "s|wds.linkis.filesystem.root.path=.*|wds.linkis.filesystem.root.path=file:///tmp/linkis/|g" "$cfg"
  grep -q "wds.linkis.entrance.config.log.path" "$cfg" || echo "wds.linkis.entrance.config.log.path=file:///tmp/linkis/logs" >> "$cfg"
  grep -q "wds.linkis.resultSet.store.path" "$cfg" || echo "wds.linkis.resultSet.store.path=file:///tmp/linkis/resultset" >> "$cfg"
  grep -q "wds.linkis.engineconn.bml.upload.failed.enable" "$cfg" || echo "wds.linkis.engineconn.bml.upload.failed.enable=false" >> "$cfg"
  sed -i "s|wds.linkis.bml.is.hdfs=.*|wds.linkis.bml.is.hdfs=false|g" "$cfg"
  grep -q "wds.linkis.bml.local.prefix" "$cfg" || echo "wds.linkis.bml.local.prefix=/opt/linkis/data/bml" >> "$cfg"
done

mkdir -p /opt/linkis/data/bml /tmp/linkis/logs /tmp/linkis/resultset
echo "=== 4. 调整目录权限 ==="
chown -R hadoop:root /opt/linkis /etc/linkis-conf /var/logs/linkis /home/hadoop /appcom 2>/dev/null || true
chmod -R 775 /opt/linkis /etc/linkis-conf /var/logs/linkis /home/hadoop /appcom 2>/dev/null || true

# 杀掉残留的 java 进程
pkill -9 java 2>/dev/null || true
sleep 2

echo "=== 5. 启动 Linkis 全部微服务 ==="
export LINKIS_HOME=/opt/linkis
export LINKIS_CONF_DIR=/opt/linkis/conf
/opt/linkis/sbin/linkis-start-all.sh
