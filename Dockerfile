# 使用官方 OpenSIPS 镜像作为基础镜像
FROM opensips/opensips:latest

# 设置维护者信息
LABEL maintainer="your_email@example.com"

# 安装构建 OpenSIPS 所需的依赖包
RUN apt-get update && apt-get install -y \
    build-essential \
    libmysqlclient-dev \
    libssl-dev \
    libpcap-dev \
    libcurl4-openssl-dev \
    libpcre3-dev \
    libexpat1-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# 克隆 OpenSIPS 源代码
RUN git clone https://github.com/OpenSIPS/opensips.git /opensips

# 设置工作目录
WORKDIR /opensips

# 配置 OpenSIPS，启用所需的模块
RUN make clean && make menuconfig \
    && make modules \
    && make install

# 清理构建文件
RUN rm -rf /opensips

# 将本地配置文件复制到容器中
COPY opensips.cfg /etc/opensips/opensips.cfg

# 设置容器启动时执行的命令
CMD ["opensips", "-f", "/etc/opensips/opensips.cfg", "-M", "1"]
