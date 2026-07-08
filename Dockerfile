FROM 10.142.144.70/hmsc-edge/hmsc-img-elk-agent:hmsc-edge-agent_20231117_04_SZK202039_d281f

ARG JAR
ARG APP_NAME

# JAR 参数现在是简单文件名 app.jar，最终容器内文件名由 APP_NAME 控制
RUN mkdir -p /hh-medic/app

COPY ${JAR} /hh-medic/app/${APP_NAME}
ENV APP_JAR=/hh-medic/app/${APP_NAME}

EXPOSE 18000

RUN groupadd OPS_admin -g 1000 \
    && useradd OPS_admin -u 1000 -g 1000 \
    && chown -R OPS_admin /hh-medic/app

ENTRYPOINT ["sh", "-c", "exec java -jar \"$APP_JAR\""]
USER OPS_admin
