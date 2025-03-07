# 基于Debian Bullseye
FROM debian:bullseye
LABEL maintainer="Your Name <your.email@example.com>"

# 环境变量配置
ENV DEBIAN_FRONTEND=noninteractive \
    OPENSIPS_MAJOR=3.5 \
    OPENSIPS_MODULES="db_mysql mi_http httpd maxfwd sl rr tm"

# 替换为阿里云镜像源（解决清华源偶发不可达问题）
RUN sed -i "s@http://deb.debian.org@https://mirrors.aliyun.com@g" /etc/apt/sources.list && \
    sed -i "s@http://security.debian.org@https://mirrors.aliyun.com/debian-security@g" /etc/apt/sources.list

# 安装基础工具（增加超时和重试参数）
RUN apt-get update -qq -o Acquire::Retries=5 -o Acquire::http::Timeout=30 --fix-missing && \
    apt-get install -y --no-install-recommends \
    gnupg2 \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 添加OpenSIPS官方APT仓库密钥（修复密钥导入逻辑）
RUN wget -qO - https://apt.opensips.org/opensips-org.gpg | gpg --dearmor > /usr/share/keyrings/opensips-org.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bullseye 3.5-releases" > /etc/apt/sources.list.d/opensips.list

# 安装OpenSIPS及模块
RUN apt-get update -qq -o Acquire::Retries=5 --fix-missing && \
    apt-get install -y --no-install-recommends \
    opensips${OPENSIPS_MAJOR} \
    opensips${OPENSIPS_MAJOR}-mysql-module \
    opensips${OPENSIPS_MAJOR}-http-modules \
    libmariadb-dev \
    libcurl4-openssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 动态加载模块配置
RUN sed -i "s/stderror_enabled=no/stderror_enabled=yes/g" /etc/opensips/opensips.cfg && \
    sed -i "s/syslog_enabled=yes/syslog_enabled=no/g" /etc/opensips/opensips.cfg && \
    for module in ${OPENSIPS_MODULES}; do \
        echo "loadmodule \"$$module.so\"" >> /etc/opensips/opensips.cfg; \
    done

EXPOSE 5060/udp 8080/tcp
ENTRYPOINT ["/usr/sbin/opensips", "-F"]
