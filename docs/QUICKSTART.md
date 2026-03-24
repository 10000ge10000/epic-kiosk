# 🚀 快速开始

## 一键部署（仅需 1 条命令）

```bash
# 直接一键部署（Cookie-Only）
curl -fsSL https://raw.githubusercontent.com/10000ge10000/epic-kiosk/main/install.sh | bash
```

脚本会自动完成：
- ✅ 检测系统架构
- ✅ 克隆项目代码
- ✅ 生成基础配置
- ✅ 本地编译镜像
- ✅ 启动服务

---

## 手动部署（3 步）

### 1️⃣ 克隆项目
```bash
git clone https://github.com/10000ge10000/epic-kiosk.git
cd epic-kiosk
```

### 2️⃣ 配置 Cookie-Only
创建 `.env`：
```bash
cp .env.example .env
```

并至少写入：
```env
EPIC_EMAIL=your_email@example.com
COOKIE_ONLY_MODE=true
```

### 3️⃣ 构建并启动
```bash
docker compose up -d --build
```

> ⏱️ 首次构建约需 5-10 分钟（下载依赖 + 编译镜像）

---

## ✅ 访问控制台

打开浏览器：`http://服务器IP:18000`

首次请先让对应账号在会话目录完成一次手动登录，后续定时任务将复用 Cookie。

---

## 📝 说明

- **配置简单**：主要在 `.env` 中配置 `EPIC_EMAIL` 和 `COOKIE_ONLY_MODE`
- **无需配置账号**：Epic 账号在 Web 界面添加
- **Cookie-Only**：不执行账号密码自动登录，仅复用会话
- **无 AI 依赖**：不再要求验证码模型 API Key

---

## 🔍 查看日志

```bash
# 查看 Worker 日志
docker logs epic-worker -f

# 查看 Web 日志
docker logs epic-web -f

# 查看所有服务状态
docker compose ps
```

---

## 🛑 停止服务

```bash
docker compose down
```

---

## 🔄 更新项目

```bash
cd epic-kiosk
git pull
docker compose up -d --build
```

---

更多详细信息请查看 [README.md](../README.md)
