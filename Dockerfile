# 基于已有 jdk21 镜像，替换为 JDK 21.0.8；含验证码/Java2D 所需字体依赖
FROM 10.142.144.70/hmc-caremate/jdk21:latest

LABEL maintainer="zhuxiuwei <zhuxiuwei@hh-medic.com>"

ARG TZ=Asia/Shanghai
ARG JDK_DIR=jdk-21.0.8
ARG APP_HOME=/hh-medic/app

USER root

# 删除镜像中已有的 JDK（先清理旧 JAVA_HOME，再清常见安装路径）
RUN if [ -n "${JAVA_HOME}" ] && [ -d "${JAVA_HOME}" ]; then rm -rf "${JAVA_HOME}"; fi \
 && rm -rf /usr/local/jdk* /usr/java/jdk* /opt/java/* /opt/jdk* /usr/lib/jvm/*

ENV TZ=${TZ} \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    JAVA_HOME=/usr/local/${JDK_DIR} \
    CLASSPATH=.:/usr/local/${JDK_DIR}/lib \
    PATH=/usr/local/${JDK_DIR}/bin:$PATH \
    DEBIAN_FRONTEND=noninteractive

# 基础运行依赖 + Java2D 字体库
# libfontmanager.so 依赖系统库 libfreetype.so.6（由 libfreetype6 提供）
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

# 构建上下文需提供 jdk-21.0.8_linux-x64_bin.tar.gz（与 Dockerfile 同级）
# ADD 会自动解压到 /usr/local/jdk-21.0.8
ADD jdk-21.0.8_linux-x64_bin.tar.gz /usr/local/

# 非 root 运行用户（兼容清理可能占用的 uid/gid 1000）
RUN userdel -r ubuntu 2>/dev/null || true \
 && groupdel ubuntu 2>/dev/null || true \
 && (getent group OPS_admin >/dev/null || getent group 1000 >/dev/null || groupadd -g 1000 OPS_admin) \
 && (id -u OPS_admin >/dev/null 2>&1 || id -u 1000 >/dev/null 2>&1 || useradd -u 1000 -g 1000 -m -s /bin/sh OPS_admin) \
 && mkdir -p ${APP_HOME} \
 && chown -R 1000:1000 ${APP_HOME}

USER OPS_admin
WORKDIR ${APP_HOME}
