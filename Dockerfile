FROM debian:bullseye
LABEL maintainer="Your Name <your.email@example.com>"

ENV DEBIAN_FRONTEND=noninteractive \
    OPENSIPS_MAJOR=3.5 \
    OPENSIPS_MODULES="db_mysql mi_http httpd maxfwd sl rr tm"

# 使用清华镜像源加速国内下载（关键优化）
RUN sed -i "s@http://deb.debian.org@https://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list && \
    sed -i "s@http://security.debian.org@https://mirrors.tuna.tsinghua.edu.cn/debian-security@g" /etc/apt/sources.list

RUN apt-get update -qq --fix-missing && \
    apt-get install -y --no-install-recommends \
    gnupg2 ca-certificates wget

# 修复密钥导入方式（避免网络问题）
RUN wget -qO - https://apt.opensips.org/opensips-org.gpg | apt-key add - && \
    echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bullseye 3.5-releases" > /etc/apt/sources.list.d/opensips.list

RUN apt-get update -qq --fix-missing -o Acquire::Retries=3 && \
    apt-get install -y --no-install-recommends \
    opensips${OPENSIPS_MAJOR} \
    opensips${OPENSIPS_MAJOR}-mysql-module \
    opensips${OPENSIPS_MAJOR}-http-modules \
    libmariadb-dev \
    libcurl4-openssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 动态加载模块配置
RUN sed -i "s/stderror_enabled=no/stderror_enabled=yes/g" /etc/opensips/opensips.cfg && \
    sed -i "s/syslog_enabled=yes/syslog_enabled=no/g" /etc/opensips/opensips.cfg && \
    for module in ${OPENSIPS_MODULES}; do \
        echo "loadmodule \"$$module.so\"" >> /etc/opensips/opensips.cfg; \
    done

EXPOSE 5060/udp 8080/tcp
ENTRYPOINT ["/usr/sbin/opensips", "-F"]
