#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== 1. 准备插件目录 (plugins/) ==="
PLUGINS_DIR="${SCRIPT_DIR}/plugins"
mkdir -p "${PLUGINS_DIR}"

echo "正在收集 linkis-engineconn-plugins 下编译出的 out.zip 插件包..."
find "${PROJECT_ROOT}/linkis-engineconn-plugins" -name "out.zip" | while read -r zip_path; do
    echo "解压插件: ${zip_path}"
    unzip -q -o "${zip_path}" -d "${PLUGINS_DIR}"
done

echo "插件列表:"
ls -la "${PLUGINS_DIR}"

echo "=== 2. 开始构建 Docker 镜像 ==="
cd "${SCRIPT_DIR}"
IMAGE_TAG="linkis:with-jdbc"
STANDALONE_TAG="linkis-standalone:latest"

docker build -t "${IMAGE_TAG}" -t "${STANDALONE_TAG}" .

echo "=== 3. 镜像构建完成 ==="
docker images | grep -E "linkis.*with-jdbc|linkis-standalone"

echo ""
echo "启动容器示例:"
echo "docker run -d --name linkis-standalone --network wrenai_wren -p 9001:9001 -e MYSQL_HOST=test-mysql-init -e MYSQL_PORT=3306 -e MYSQL_DB=linkis -e MYSQL_USER=root -e MYSQL_PASSWORD=123456 linkis-standalone:latest"
