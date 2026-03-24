# Epic Kiosk - 自动驾驶领取系统

![Docker](https://img.shields.io/badge/Docker-Enabled-blue?logo=docker)
![Python](https://img.shields.io/badge/Python-3.12-yellow?logo=python)
![Status](https://img.shields.io/badge/Status-Stable-green)
![License](https://img.shields.io/badge/License-GPL--3.0-blue)

基于 Docker 的 Epic Games 免费游戏自动领取工具（Cookie-Only 模式），支持多账号托管、错峰调度。

> 公益站点：[https://epic.910501.xyz/](https://epic.910501.xyz/)

<p align="center">
  <img src="assets/image_2.png" alt="Epic Kiosk Dashboard" width="100%" style="max-width: 800px;">
</p>

---

## 核心功能

| 功能 | 说明 |
|------|------|
| 自动驾驶 | 一键启动，自动完成登录状态校验、游戏领取 |
| Cookie 托管 | 首次登录后保存 Cookie，后续无需重复登录 |
| 错峰调度 | 智能随机延迟，避免多账号同时触发风控 |
| 防滥用保护 | IP 限流 + 恶意账号检测 |
| 一键部署 | Docker Compose 本地编译，支持 x86/ARM |

---

## 快速开始

### 方式一：Linux 一键部署

适用于云服务器、VPS、Linux 主机：

```bash
curl -fsSL https://raw.githubusercontent.com/10000ge10000/epic-kiosk/main/install.sh | bash
```

脚本功能：
- 自动检测系统架构（x86_64 / ARM64）
- 自动安装 Docker 和 Docker Compose
- 自动克隆项目并启动

首次部署约需 5-10 分钟。

---

### 方式二：手动部署

适用于已有 Docker 环境的 Linux / macOS / Windows 主机。

**1. 克隆项目**

```bash
git clone https://github.com/10000ge10000/epic-kiosk.git
cd epic-kiosk
```

**2. 配置 Cookie-Only 环境变量**

创建 `.env` 文件

```bash
cp .env.example .env
# 编辑 .env 文件，至少配置以下字段
EPIC_EMAIL=your_email@example.com
COOKIE_ONLY_MODE=true
```

**3. 启动**

```bash
docker compose up -d --build
```

首次启动约需 5-10 分钟。

---

### 部署注意事项

1. **端口**：默认 `18000`，如需修改请编辑 `docker-compose.yml` 第 51 行
2. **访问地址**：`http://服务器IP:18000`
3. **首次使用**：先用同一 `EPIC_EMAIL` 在容器对应的浏览器会话目录完成一次手动登录

---

## 使用说明

### 添加账号
1. 输入 Epic 邮箱
2. 点击「启动引擎」
3. 系统仅校验会话 Cookie 并执行领取

### 查看资产
- 点击「资产清单」Tab 查看已领取游戏
- 点击游戏封面跳转 Epic 商店

### 删除账号
- 确认删除后点击红色删除按钮
- 系统将清除数据库记录和本地 Cookie 数据

---

## 配置说明

### Cookie-Only 模式（免 AI 验证码）

如你希望只使用“浏览器已登录会话（Cookie）”执行领取，不再触发账号密码登录流程，可配置：

```env
COOKIE_ONLY_MODE=true
```

启用后行为：
- 仅复用 `volumes/user_data/<EPIC_EMAIL>/` 下的浏览器会话
- 若会话失效，任务会返回 Cookie 无效（不会自动走邮箱+密码+验证码登录）
- 适合青龙面板等定时任务场景（先手动登录一次，再长期复用）

---

## 项目结构

```
epic-kiosk/
├── app/                    # 核心代码
│   ├── main.py             # FastAPI 后端
│   ├── worker.py           # 任务调度器
│   ├── deploy.py           # 浏览器自动化
│   └── services/           # 业务逻辑
├── templates/              # 前端页面
├── data/                   # 持久化数据
│   ├── images/             # 游戏海报
│   ├── user_data/          # 用户 Cookie
│   └── logs/               # 日志文件
├── docker-compose.yml      # 容器编排
├── install.sh              # 一键部署脚本
├── Dockerfile              # Web 镜像
└── Dockerfile.worker       # Worker 镜像
```

---

## 安全机制

### IP 保护
- 1 分钟内最多 3 次请求
- 超限后临时封禁 1 小时
- 同一 IP 提交超过 5 个不同账号将永久封禁

### 账号保护
- 同一邮箱任务互斥
- 已存储账号需会话校验
- 自动清理浏览器缓存（约 2MB/账号）

---

## 版本升级

已部署用户升级到最新版本：

```bash
cd /epic-kiosk
git pull
docker compose up -d --build
```

仅升级 Worker：

```bash
docker compose build worker && docker compose up -d worker
```

---

## 故障排查

### 常见问题

**Q: 按钮显示「Requires Base Game」？**

A: 该游戏需要先拥有基础游戏，属于 DLC，跳过即可。

**Q: 验证码一直失败？**

A: 检查 API Key 是否正确，余额是否充足。

**Q: 日志显示「游戏已在库中」？**

A: 该账号已领取过此游戏，正常现象。

**Q: 服务器 IP 被 Cloudflare 拦截？**

A: 数据中心 IP 可能被标记，建议配置住宅代理或使用公益站点。

### 查看日志

```bash
# Worker 日志（实时）
docker logs epic-worker --tail 50

# 日志文件（按日期分类）
ls data/logs/

# 查看当天运行时日志
cat data/logs/runtime-$(date +%Y-%m-%d).log | tail -50

# 查看当天错误日志
cat data/logs/error-$(date +%Y-%m-%d).log
```

### 重新构建

```bash
# 仅重新构建 Worker
docker compose build worker && docker compose up -d worker

# 重新构建所有服务
docker compose build --no-cache && docker compose up -d
```

---

## 相关文档

- [API Key 获取指南](docs/API_KEY_GUIDE.md)
- [快速开始指南](docs/QUICKSTART.md)
- [模型配置说明](docs/MODEL_CONFIG.md)

---

## 致谢

- 原项目：[QIN2DIM/epic-awesome-gamer](https://github.com/QIN2DIM/epic-awesome-gamer)
- AI 服务：[SiliconFlow](https://cloud.siliconflow.cn/i/OVI2n57p)

---

## 免责声明

本项目仅供学习和技术研究使用。请合理使用，遵守 Epic Games 服务条款。开发者不对因使用本项目导致的任何损失承担责任。

---

*Created by [一万](https://github.com/10000ge10000) | 公益站点：[epic.910501.xyz](https://epic.910501.xyz/)*
