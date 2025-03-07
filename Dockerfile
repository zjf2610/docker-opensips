# 基于Debian Bullseye构建
FROM debian:bullseye
LABEL maintainer="Your Name <your.email@example.com>"

# 环境变量配置
ENV DEBIAN_FRONTEND=noninteractive \
    OPENSIPS_VERSION=3.5.4 \
    OPENSIPS_MODULES="db_mysql mi_http httpd maxfwd sl rr tm"

# 安装基础工具和依赖
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    gnupg2 ca-certificates wget

# 添加OpenSIPS官方APT仓库和密钥（参考官方APT配置）
RUN apt-key adv --fetch-keys https://apt.opensips.org/opensips-org.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bullseye 3.5-releases" > /etc/apt/sources.list.d/opensips.list

# 安装OpenSIPS核心包及模块
RUN apt-get update -qq --fix-missing && \
    apt-get install -y --no-install-recommends \
    opensips=${OPENSIPS_VERSION} \
    opensips-mysql-module-${OPENSIPS_VERSION%.*} \
    opensips-http-modules-${OPENSIPS_VERSION%.*} \
    libmariadb-dev \
    libcurl4-openssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 动态加载模块（参考模块配置）
RUN sed -i "s/stderror_enabled=no/stderror_enabled=yes/g" /etc/opensips/opensips.cfg && \
    sed -i "s/syslog_enabled=yes/syslog_enabled=no/g" /etc/opensips/opensips.cfg && \
    for module in ${OPENSIPS_MODULES}; do \
        echo "loadmodule \"$$module.so\"" >> /etc/opensips/opensips.cfg; \
    done

# 暴露端口（SIP默认端口5060/UDP，HTTP管理接口8080/TCP）
EXPOSE 5060/udp 8080/tcp

# 启动命令
ENTRYPOINT ["/usr/sbin/opensips", "-F"]
