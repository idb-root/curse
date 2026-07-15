# Ubuntu + JDK 21 运行时基础镜像
FROM ubuntu:24.04

LABEL maintainer="zhuxiuwei <zhuxiuwei@hh-medic.com>"

ARG TZ=Asia/Shanghai
ARG JDK_DIR=jdk-21.0.8
ARG APP_HOME=/hh-medic/app
ARG DEBIAN_FRONTEND=noninteractive

# 时区 + 语言环境 + Java 环境变量（合并，减少层）
ENV TZ=${TZ} \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    JAVA_HOME=/usr/local/${JDK_DIR} \
    CLASSPATH=.:/usr/local/${JDK_DIR}/lib \
    PATH=/usr/local/${JDK_DIR}/bin:$PATH

# 时区 + locale（Ubuntu 需安装 tzdata / locales）
RUN apt-get update \
 && apt-get install -y --no-install-recommends tzdata locales \
 && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo "${TZ}" > /etc/timezone \
 && locale-gen en_US.UTF-8 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# 安装 JDK 21（ADD 会自动解压 tar.gz 到 /usr/local/）
# 构建前请将 jdk-21.0.8_linux-x64_bin.tar.gz 放在 Dockerfile 同目录
ADD jdk-21.0.8_linux-x64_bin.tar.gz /usr/local/

# 创建用户/组（Ubuntu 24.04 默认已有 uid/gid 1000 的 ubuntu，需先移除）
RUN userdel -r ubuntu 2>/dev/null || true \
 && groupdel ubuntu 2>/dev/null || true \
 && groupadd -g 1000 OPS_admin \
 && useradd -u 1000 -g 1000 -m -s /bin/sh OPS_admin \
 && mkdir -p ${APP_HOME} \
 && chown -R OPS_admin:OPS_admin ${APP_HOME}

USER OPS_admin
WORKDIR ${APP_HOME}
