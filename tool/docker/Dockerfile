FROM eclipse-temurin:8-jdk-focal

ARG LINKIS_VERSION=1.8.0
ARG MYSQL_JDBC_VERSION=8.0.28

ENV LINKIS_HOME=/opt/linkis
ENV LINKIS_CONF_DIR=/opt/linkis/conf
ENV LINKIS_LOG_DIR=/opt/linkis/logs
ENV PATH=$LINKIS_HOME/bin:$LINKIS_HOME/sbin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    tar \
    unzip \
    sudo \
    procps \
    net-tools \
    iputils-ping \
    vim \
    openssh-client \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

# 将默认 sh 软链接指向 bash（解决 dash 不兼容 Linkis 启动脚本问题）
RUN ln -sf /bin/bash /bin/sh

RUN useradd -m -s /bin/bash -u 10001 hadoop \
    && echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && touch /home/hadoop/.bash_profile \
    && chown hadoop:hadoop /home/hadoop/.bash_profile

WORKDIR /opt

# 下载并解压 Linkis 1.8.0 二进制包
RUN curl -fSL "https://archive.apache.org/dist/linkis/${LINKIS_VERSION}/apache-linkis-${LINKIS_VERSION}-bin.tar.gz" -o linkis-bin.tar.gz \
    && mkdir -p ${LINKIS_HOME} \
    && tar -zxf linkis-bin.tar.gz -C ${LINKIS_HOME} --strip-components=1 \
    && rm linkis-bin.tar.gz \
    && cp ${LINKIS_HOME}/linkis-env.sh ${LINKIS_HOME}/conf/linkis-env.sh 2>/dev/null || true

# 下载 MySQL Connector 驱动并分发到公共模块与各微服务 lib
RUN curl -fSL "https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_JDBC_VERSION}/mysql-connector-java-${MYSQL_JDBC_VERSION}.jar" -o /opt/mysql-connector.jar \
    && mkdir -p ${LINKIS_HOME}/lib/linkis-commons/public-module/ \
    && cp /opt/mysql-connector.jar ${LINKIS_HOME}/lib/linkis-commons/public-module/ \
    && mkdir -p ${LINKIS_HOME}/lib/linkis-spring-cloud-services/linkis-mg-gateway/ \
    && cp /opt/mysql-connector.jar ${LINKIS_HOME}/lib/linkis-spring-cloud-services/linkis-mg-gateway/ \
    && mkdir -p ${LINKIS_HOME}/lib/linkis-spring-cloud-services/linkis-mg-eureka/ \
    && cp /opt/mysql-connector.jar ${LINKIS_HOME}/lib/linkis-spring-cloud-services/linkis-mg-eureka/ \
    && mkdir -p ${LINKIS_HOME}/lib/linkis-public-enhancements/linkis-ps-publicservice/ \
    && cp /opt/mysql-connector.jar ${LINKIS_HOME}/lib/linkis-public-enhancements/linkis-ps-publicservice/ \
    && mkdir -p ${LINKIS_HOME}/lib/linkis-computation-governance/linkis-cg-linkismanager/ \
    && cp /opt/mysql-connector.jar ${LINKIS_HOME}/lib/linkis-computation-governance/linkis-cg-linkismanager/ \
    && mkdir -p ${LINKIS_HOME}/lib/linkis-computation-governance/linkis-cg-entrance/ \
    && cp /opt/mysql-connector.jar ${LINKIS_HOME}/lib/linkis-computation-governance/linkis-cg-entrance/ \
    && mkdir -p ${LINKIS_HOME}/lib/linkis-computation-governance/linkis-cg-engineconnmanager/ \
    && cp /opt/mysql-connector.jar ${LINKIS_HOME}/lib/linkis-computation-governance/linkis-cg-engineconnmanager/ \
    && mkdir -p ${LINKIS_HOME}/lib/linkis-computation-governance/linkis-client/ \
    && cp /opt/mysql-connector.jar ${LINKIS_HOME}/lib/linkis-computation-governance/linkis-client/ \
    && rm /opt/mysql-connector.jar

# 软链接兼容 /appcom/Install/LinkisInstall
RUN mkdir -p /appcom/Install \
    && ln -sfn ${LINKIS_HOME} /appcom/Install/LinkisInstall

# 拷贝插件包目录（如果存在）与 Trino 初始化 SQL
COPY plugins/ ${LINKIS_HOME}/lib/linkis-engineconn-plugins/
COPY init_trino_metadata.sql ${LINKIS_HOME}/conf/init_trino_metadata.sql

# 创建必要目录并赋予权限
RUN mkdir -p ${LINKIS_LOG_DIR} \
    && mkdir -p /etc/linkis-conf \
    && mkdir -p /data/dss/bml/hadoop/20260827 \
    && cp -rn ${LINKIS_HOME}/conf/* /etc/linkis-conf/ 2>/dev/null || true \
    && chown -R hadoop:hadoop ${LINKIS_HOME} /etc/linkis-conf /appcom /home/hadoop /data \
    && chmod -R 775 ${LINKIS_HOME} /etc/linkis-conf /appcom /home/hadoop /data \
    && chmod a+x ${LINKIS_HOME}/bin/* \
    && chmod a+x ${LINKIS_HOME}/sbin/*

COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

USER hadoop
WORKDIR ${LINKIS_HOME}

EXPOSE 9001 20301 20302 20303 20304 20305

ENTRYPOINT ["/opt/entrypoint.sh"]
