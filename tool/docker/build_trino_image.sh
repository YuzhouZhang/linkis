#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 指定并优先使用 Java 8 环境进行构建
if [ -d "/usr/lib/jvm/java-8-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
    export PATH="${JAVA_HOME}/bin:${PATH}"
elif [ -d "/usr/lib/jvm/java-1.8.0-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-amd64"
    export PATH="${JAVA_HOME}/bin:${PATH}"
fi

echo "当前构建使用的 Java 版本:"
java -version

echo "=========================================================="
echo "步骤 1: 编译 Trino 引擎插件 (linkis-engineconn-plugins/trino)"
echo "=========================================================="
cd "${PROJECT_ROOT}/linkis-engineconn-plugins/trino"
mvn clean package -DskipTests -Dspotless.check.skip=true -Dspotless.apply.skip=true

echo "=========================================================="
echo "步骤 2: 提取并解压插件物料到 plugins/ 目录"
echo "=========================================================="
PLUGINS_DIR="${SCRIPT_DIR}/plugins"
mkdir -p "${PLUGINS_DIR}"

if [ -f "${PROJECT_ROOT}/linkis-engineconn-plugins/trino/target/out.zip" ]; then
    echo "解压 Trino out.zip 到 plugins/ 目录..."
    unzip -q -o "${PROJECT_ROOT}/linkis-engineconn-plugins/trino/target/out.zip" -d "${PLUGINS_DIR}"
elif [ -d "${PROJECT_ROOT}/linkis-engineconn-plugins/trino/target/out/trino" ]; then
    echo "拷贝 Trino out 目录到 plugins/ ..."
    cp -r "${PROJECT_ROOT}/linkis-engineconn-plugins/trino/target/out/trino" "${PLUGINS_DIR}/"
else
    echo "ERROR: 未找到 Trino 插件编译产物 (target/out.zip 或 target/out/trino)!"
    exit 1
fi

# 同步 SQL 文件到构建上下文目录
cp -f "${PROJECT_ROOT}/tool/init_trino_metadata.sql" "${SCRIPT_DIR}/init_trino_metadata.sql"

echo "插件列表确认:"
ls -la "${PLUGINS_DIR}"
if [ -d "${PLUGINS_DIR}/trino" ]; then
    echo "Trino 插件目录结构:"
    find "${PLUGINS_DIR}/trino" -maxdepth 3
fi

echo "=========================================================="
echo "步骤 3: 构建 Docker 镜像"
echo "=========================================================="
cd "${SCRIPT_DIR}"
IMAGE_NAME="linkis-standalone:1.8.0-trino"

docker build -t "${IMAGE_NAME}" .

echo "=========================================================="
echo "步骤 4: 导出镜像为 tar 包"
echo "=========================================================="
# 优先使用环境变量指定的 EXPORT_DIR，默认适配 WSL 路径，若不存在则回退至当前 exports 目录
if [ -z "${EXPORT_DIR}" ]; then
    if [ -d "/mnt/d/Users/zhang/Downloads/wsl-docker-exporter/exports" ]; then
        EXPORT_DIR="/mnt/d/Users/zhang/Downloads/wsl-docker-exporter/exports"
    elif [ -d "d:/Users/zhang/Downloads/wsl-docker-exporter/exports" ]; then
        EXPORT_DIR="d:/Users/zhang/Downloads/wsl-docker-exporter/exports"
    else
        EXPORT_DIR="${SCRIPT_DIR}/exports"
    fi
fi

mkdir -p "${EXPORT_DIR}"
EXPORT_TAR="${EXPORT_DIR}/linkis-standalone-1.8.0-trino.tar"

echo "正在导出镜像到: ${EXPORT_TAR} ..."
docker save -o "${EXPORT_TAR}" "${IMAGE_NAME}"

echo ""
echo "=========================================================="
echo "🎉 构建与导出完成！"
echo "📦 镜像名称: ${IMAGE_NAME}"
echo "📁 导出文件: ${EXPORT_TAR}"
echo "=========================================================="
