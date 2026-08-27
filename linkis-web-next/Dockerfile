# ==========================================
# 阶段 1: 前端静态资源打包构建
# ==========================================
FROM node:18-alpine AS builder

WORKDIR /app

# 优先拷贝 package 依赖文件以利用 Docker 缓存
COPY package*.json ./

# 安装依赖
RUN npm install --legacy-peer-deps

# 拷贝全量源码
COPY . .

# 执行生产打包
RUN npx vite build

# ==========================================
# 阶段 2: Nginx 生产环境托管
# ==========================================
FROM nginx:1.26-alpine

# 拷贝构建好的前端静态产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 拷贝 Nginx 配置模板与 Entrypoint 脚本
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
