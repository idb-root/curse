# Ubuntu + JDK 21 基础运行镜像
FROM ubuntu:24.04

LABEL maintainer="zhuxiuwei <zhuxiuwei@hh-medic.com>"

ARG TZ=Asia/Shanghai
ARG JDK_DIR=jdk-21.0.8
ARG APP_HOME=/hh-medic/app

# 时区 + 语言环境 + Java 环境变量（合并，减少层）
ENV TZ=${TZ} \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    JAVA_HOME=/usr/local/${JDK_DIR} \
    CLASSPATH=.:/usr/local/${JDK_DIR}/lib \
    PATH=/usr/local/${JDK_DIR}/bin:$PATH \
    DEBIAN_FRONTEND=noninteractive

# 安装基础依赖：时区、UTF-8 语言环境、常用证书，
# 以及 Java2D/验证码绘制所需的字体库（libfontmanager.so 依赖 libfreetype.so.6）
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        fontconfig \
        fonts-dejavu-core \
        libfreetype6 \
        locales \
        tzdata \
 && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo "${TZ}" > /etc/timezone \
 && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
 && fc-cache -f \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# 安装 JDK 21（ADD 会自动解压 tar.gz 到 /usr/local/）
# 构建前请将 jdk-21.0.8_linux-x64_bin.tar.gz 放在与 Dockerfile 同级目录
ADD jdk-21.0.8_linux-x64_bin.tar.gz /usr/local/

# 创建用户/组，并确保应用目录存在
# Ubuntu 24.04 默认已有 uid/gid 1000 的 ubuntu 用户，需先移除
RUN userdel -r ubuntu 2>/dev/null || true \
 && groupdel ubuntu 2>/dev/null || true \
 && groupadd -g 1000 OPS_admin \
 && useradd -u 1000 -g 1000 -m -s /bin/sh OPS_admin \
 && mkdir -p ${APP_HOME} \
 && chown -R OPS_admin:OPS_admin ${APP_HOME}

USER OPS_admin
WORKDIR ${APP_HOME}
