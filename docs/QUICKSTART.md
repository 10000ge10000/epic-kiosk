# 🚀 快速开始

## 一键部署（仅需 3 步）

### 0️⃣ 准备 API Key

访问 [SiliconFlow 官网](https://cloud.siliconflow.cn/i/OVI2n57p) 注册并获取 API Key。

> 🆓 **为什么选择 SiliconFlow？**
> - 主力模型 **Qwen2.5-7B-Instruct 完全免费**
> - 验证码模型价格极低（¥0.5/百万 tokens）
> - 国内访问速度快，无需科学上网
> - 本项目专为该平台优化
>
> 👉 **使用邀请链接注册，双方各得 ¥16 代金券**

### 1️⃣ 克隆项目
```bash
git clone -b main https://github.com/10000ge10000/epic-kiosk.git
cd epic-kiosk
```

### 2️⃣ 配置 API Key
编辑 `docker-compose.yml`，找到第 68 行：
```yaml
- SILICONFLOW_API_KEY=sk-xxx  # 改成你的 SiliconFlow API Key
```

### 3️⃣ 启动服务
```bash
docker compose up -d
```

## ✅ 访问控制台

打开浏览器：`http://服务器IP:18000`

在 Web 界面添加 Epic 账号，系统会自动处理后续所有流程。

---

## 📝 说明

- **无需配置文件**：所有配置都在 `docker-compose.yml` 中
- **无需配置账号**：Epic 账号在 Web 界面添加
- **模型已优化**：双模型自动切换，无需手动配置
- **主力模型免费**：Qwen2.5-7B-Instruct 完全免费
- **专属优化**：针对 SiliconFlow 平台优化

---

## 🔍 查看日志

```bash
# 查看 Worker 日志
docker logs epic-worker -f

# 查看 Web 日志
docker logs epic-web -f
```

---

## 🛑 停止服务

```bash
docker compose down
```

---

更多详细信息请查看 [README.md](../README.md)
