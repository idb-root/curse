# 陪诊 / 小诺健康

## 环境地址

### 测试环境（UAT）

| 系统 | 地址 |
| --- | --- |
| 陪诊系统 | https://cns-uat.cignacmbhealth.com/y29spoLkgu.txt |
| 小诺健康 | https://hss-uat.xiaonuohealth.com/y29spoLkgu.txt |

### 生产环境（PRD）

| 系统 | 地址 |
| --- | --- |
| 陪诊系统 | https://cns.cignacmbhealth.com/y29spoLkgu.txt |
| 小诺健康 | https://hss.xiaonuohealth.com/y29spoLkgu.txt |

## GitRunner CI 发布状态

### 测试环境（UAT）

| 类型 | 工程 | 角色 | 状态 |
| --- | --- | --- | --- |
| Java | `cns-admin-api` | 后台后端 | ✅ 已调试成功 |
| Java | `cns-app-api` | 后台后端 | ✅ 已调试成功 |
| Java | `hss-admin-api` | 用户端后端 | ✅ 已调试成功 |
| Java | `hss-app-api` | 用户端后端 | ✅ 已调试成功 |
| Node | `cns-admin-web` | 后台前端 | ✅ 已调试成功 |
| Node | `cns-app-web` | 后台前端 | ✅ 已调试成功 |
| Node | `hss-admin-web` | 用户端前端 | ✅ 已调试成功 |
| Node | `hss-app-web` | 用户端前端 | ✅ 已调试成功 |
| Node | `hss-holo` | 健康档案 | ✅ 已调试成功 |

> Java 全部 4 工程、Node 全部 5 工程的 CI 发布流程均已调试成功。

### 生产环境（PRD）

| 类型 | 工程 | 角色 | 状态 |
| --- | --- | --- | --- |
| Java | `cns-admin-api` | 后台后端 | ✅ 已调试成功 |
| Java | `cns-app-api` | 后台后端 | ✅ 已调试成功 |
| Java | `hss-admin-api` | 用户端后端 | ✅ 已调试成功 |
| Java | `hss-app-api` | 用户端后端 | ✅ 已调试成功 |
| Node | `cns-admin-web` | 后台前端 | 🔧 配置调试中 |
| Node | `cns-app-web` | 后台前端 | 🔧 配置调试中 |
| Node | `hss-admin-web` | 用户端前端 | 🔧 配置调试中 |
| Node | `hss-app-web` | 用户端前端 | 🔧 配置调试中 |
| Node | `hss-holo` | 健康档案 | 🔧 配置调试中 |

> Java 全部 4 工程的 CI 发布流程已调试成功；Node 全部 5 工程仍在配置调试中，目前暂无已知问题。
