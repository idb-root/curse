#!/usr/bin/env bash
set -euo pipefail

DEPLOY_PATH="/app/apps/html/jar"

# Harbor 生产镜像仓库
HARBOR_HOST_PRD="csphere.cignacmb.com"
HARBOR_USER_PRD="jeck.mei@cignacmb.com"
HARBOR_PASSWORD_PRD="PRD_hmsc_edge@123"

# caremate
ADMINAPI_IMAGE="csphere.cignacmb.com/hmc-caremate/cns-admin-api:latest"
APPAPI_IMAGE="csphere.cignacmb.com/hmc-caremate/cns-app-api:latest"

ADMINAPI_JAR_NAME="caremate-admin-api.jar"
APPAPI_JAR_NAME="caremate-app-api.jar"

# xn-health（新增）
XN_ADMINAPI_IMAGE="csphere.cignacmb.com/hmc-caremate/hss-admin-api:latest"
XN_APPAPI_IMAGE="csphere.cignacmb.com/hmc-caremate/hss-app-api:latest"

XN_ADMINAPI_JAR_NAME="hmc-xn-health-admin-api.jar"
XN_APPAPI_JAR_NAME="hmc-xn-health-app-api.jar"

# 远端：改为多台
TARGETS=(
  "micr_admin@10.140.191.12"
  "micr_admin@10.140.191.13"
  "micr_admin@10.140.191.14"
)
TARGET_PATH="/app/apps/html/jar"

harbor_login() {
  echo "[本机] 登录 Harbor：$HARBOR_HOST_PRD"
  echo "$HARBOR_PASSWORD_PRD" | docker login "$HARBOR_HOST_PRD" \
    -u "$HARBOR_USER_PRD" --password-stdin
}

# 从镜像容器根目录 / 拷贝 jar 到本地目标文件
copy_jar_from_image() {
  local image="$1"
  local jar_name="$2"
  local dest="$3"
  local cid=""

  echo "[本机] 拉取镜像：$image"
  docker pull "$image"

  cid="$(docker create "$image")"
  echo "[本机] 从容器拷贝：/$jar_name -> $dest"
  if ! docker cp "$cid:/$jar_name" "$dest"; then
    docker rm -f "$cid" >/dev/null 2>&1 || true
    return 1
  fi
  docker rm -f "$cid" >/dev/null
}

deploy_one() {
  local image="$1"
  local jar_name="$2"

  local ts
  ts="$(date +%Y%m%d_%H%M%S)"

  mkdir -p "$DEPLOY_PATH"

  if [[ -f "$DEPLOY_PATH/$jar_name" ]]; then
    cp -a "$DEPLOY_PATH/$jar_name" "$DEPLOY_PATH/${jar_name}.bak_${ts}"
    echo "[本机] 已备份：$DEPLOY_PATH/${jar_name}.bak_${ts}"
  else
    echo "[本机] 未发现旧包，无需备份"
  fi

  local tmpfile
  tmpfile="$(mktemp -p "$DEPLOY_PATH" ".${jar_name}.tmp.XXXXXX")"
  trap "rm -f '$tmpfile'" RETURN

  harbor_login
  copy_jar_from_image "$image" "$jar_name" "$tmpfile"

  mv -f "$tmpfile" "$DEPLOY_PATH/$jar_name"
  chmod 0644 "$DEPLOY_PATH/$jar_name"
  echo "[本机] 已保存：$DEPLOY_PATH/$jar_name"

  # 对每台远端循环：备份 + 上传
  local target
  for target in "${TARGETS[@]}"; do
    echo "[远端] 准备备份：${target}:${TARGET_PATH}"
    ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
      "$target" \
      "set -e;
       mkdir -p '$TARGET_PATH';
       if [ -f '$TARGET_PATH/$jar_name' ]; then
         cp -a '$TARGET_PATH/$jar_name' '$TARGET_PATH/${jar_name}.bak_${ts}';
         echo '[远端] 已备份：$TARGET_PATH/${jar_name}.bak_${ts}';
       else
         echo '[远端] 未发现旧包，无需备份';
       fi"

    echo "[远端] 开始上传 -> ${target}:${TARGET_PATH}/$jar_name"
    scp -o BatchMode=yes -o StrictHostKeyChecking=no \
      "$DEPLOY_PATH/$jar_name" \
      "${target}:${TARGET_PATH}/$jar_name"

    echo "完成：已部署 $jar_name 到 $target"
  done
}

deploy_adminapi()     { deploy_one "$ADMINAPI_IMAGE"     "$ADMINAPI_JAR_NAME"; }
deploy_appapi()       { deploy_one "$APPAPI_IMAGE"       "$APPAPI_JAR_NAME"; }
deploy_xn_adminapi()  { deploy_one "$XN_ADMINAPI_IMAGE"  "$XN_ADMINAPI_JAR_NAME"; }
deploy_xn_appapi()    { deploy_one "$XN_APPAPI_IMAGE"    "$XN_APPAPI_JAR_NAME"; }

show_help() {
cat <<'EOF'
【脚本名称】deploy_server.sh

【功能】
从 Harbor 镜像容器根目录 / 拷贝指定 jar 包到本机目录，并同步上传到远端服务器目录；
本机与远端都会对旧包按时间戳进行备份（.bak_YYYYMMDD_HHMMSS）。

【用法】

1. 默认部署（caremate admin-api）：
   ./deploy_server.sh

2. 部署 caremate：
   ./deploy_server.sh adminapi      # caremate-admin-api.jar
   ./deploy_server.sh appapi        # caremate-app-api.jar

3. 部署 xn-health：
   ./deploy_server.sh xn-adminapi   # hmc-xn-health-admin-api.jar
   ./deploy_server.sh xn-appapi     # hmc-xn-health-app-api.jar

4. 查看帮助：
   ./deploy_server.sh help
   ./deploy_server.sh -h
   ./deploy_server.sh --help

【说明】
- 需要本机具备：docker / ssh / scp
- Harbor 登录使用脚本内 HARBOR_USER_PRD / HARBOR_PASSWORD_PRD
- 镜像映射：
  - adminapi     -> csphere.cignacmb.com/hmc-caremate/cns-admin-api:latest
  - appapi       -> csphere.cignacmb.com/hmc-caremate/cns-app-api:latest
  - xn-adminapi  -> csphere.cignacmb.com/hmc-caremate/hss-admin-api:latest
  - xn-appapi    -> csphere.cignacmb.com/hmc-caremate/hss-app-api:latest
- jar 从容器内路径 /${jar_name} 拷贝
- 远端为多台：TARGETS 数组
- 远端目录：TARGET_PATH
EOF
}

main() {
  local arg1="${1:-}"
  case "$arg1" in
    ""|"adminapi")        deploy_adminapi ;;
    "appapi")             deploy_appapi ;;
    "xn-adminapi")        deploy_xn_adminapi ;;
    "xn-appapi")          deploy_xn_appapi ;;
    "help"|"-h"|"--help") show_help ;;
    *) echo "参数不支持：$arg1"; echo "请执行 ./deploy_server.sh help 查看用法"; exit 2 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
