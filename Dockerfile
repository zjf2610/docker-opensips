# 基于Debian Bullseye构建
FROM debian:bullseye
LABEL maintainer="Razvan Crainea <razvan@opensips.org>"

# 环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    OPENSIPS_MODULES="db_mysql mi_http httpd maxfwd sl rr tm"

# 安装基础工具
RUN apt-get update -qq && apt-get install -y \
    gnupg2 ca-certificates wget

# 添加OpenSIPS官方APT仓库
RUN apt-key adv --fetch-keys https://apt.opensips.org/pubkey.gpg && \
    echo "deb https://apt.opensips.org bullseye 3.4-releases" > /etc/apt/sources.list.d/opensips.list

# 安装OpenSIPS核心包及模块依赖
RUN apt-get update -qq && apt-get install -y \
    opensips=3.4.1-1 \
    opensips-mysql-module-3.4 \
    opensips-http-modules-3.4 \
    libmariadb-dev \
    libcurl4-openssl-dev

# 配置OpenSIPS
RUN sed -i "s/stderror_enabled=no/stderror_enabled=yes/g" /etc/opensips/opensips.cfg && \
    sed -i "s/syslog_enabled=yes/syslog_enabled=no/g" /etc/opensips/opensips.cfg && \
    for module in ${OPENSIPS_MODULES}; do \
        echo "loadmodule \"$$module.so\"" >> /etc/opensips/opensips.cfg; \     done  # 暴露端口 EXPOSE 5060/udp 8080/tcp  # 启动命令 ENTRYPOINT ["/usr/sbin/opensips", "-F"] ```  ---  ### **关键修改说明** 1. **模块依赖声明**      通过 `OPENSIPS_MODULES` 环境变量明确声明需要加载的模块列表，支持运行时动态调整：    ```dockerfile    ENV OPENSIPS_MODULES="db_mysql mi_http httpd maxfwd sl rr tm"    ```  2. **APT仓库配置优化**      固定仓库版本为 `3.4-releases`，避免因仓库更新导致构建不稳定：    ```dockerfile    echo "deb https://apt.opensips.org bullseye 3.4-releases" > /etc/apt/sources.list.d/opensips.list    ```  3. **显式安装模块包**      通过 `opensips-mysql-module-3.4` 和 `opensips-http-modules-3.4` 安装指定模块：    ```dockerfile    opensips-mysql-module-3.4 \    opensips-http-modules-3.4    ```  4. **自动加载模块**      在构建阶段自动将模块加载指令写入配置文件：    ```dockerfile    for module in ${OPENSIPS_MODULES}; do \        echo "loadmodule \"$$module.so\"" >> /etc/opensips/opensips.cfg; \
   done
