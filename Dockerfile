# 使用Debian Bullseye基础镜像
FROM debian:bullseye
LABEL maintainer="Your Name <your.email@example.com>"

# 环境变量配置
ENV DEBIAN_FRONTEND=noninteractive \
    OPENSIPS_MAJOR=3.5 \
    OPENSIPS_MODULES="db_mysql mi_http httpd maxfwd sl rr tm"

# 替换为清华APT镜像源（加速国内下载）
RUN sed -i "s@http://deb.debian.org@https://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list && \
    sed -i "s@http://security.debian.org@https://mirrors.tuna.tsinghua.edu.cn/debian-security@g" /etc/apt/sources.list

# 安装基础工具和依赖
RUN apt-get update -qq --fix-missing && \
    apt-get install -y --no-install-recommends \
    gnupg2 ca-certificates wget \
    build-essential pkg-config

# 添加OpenSIPS官方APT仓库和密钥
RUN wget -qO - https://apt.opensips.org/opensips-org.gpg | apt-key add - && \
    echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bullseye 3.5-releases" > /etc/apt/sources.list.d/opensips.list

# 安装OpenSIPS核心包及模块依赖
RUN apt-get update -qq --fix-missing -o Acquire::Retries=3 && \
    apt-get install -y --no-install-recommends \
    opensips${OPENSIPS_MAJOR} \
    opensips${OPENSIPS_MAJOR}-mysql-module \
    opensips${OPENSIPS_MAJOR}-http-modules \
    libmariadb-dev \
    libcurl4-openssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 动态加载模块到配置文件
RUN sed -i "s/stderror_enabled=no/stderror_enabled=yes/g" /etc/opensips/opensips.cfg && \
    sed -i "s/syslog_enabled=yes/syslog_enabled=no/g" /etc/opensips/opensips.cfg && \
    for module in ${OPENSIPS_MODULES}; do \
        echo "loadmodule \"$$module.so\"" >> /etc/opensips/opensips.cfg; \
    done

# 暴露端口
EXPOSE 5060/udp 8080/tcp

# 容器启动命令
ENTRYPOINT ["/usr/sbin/opensips", "-F"]
