# RedInk CI/CD 快速开始指南

## 🚀 一键配置（推荐）

我已经为你准备了自动化配置脚本，只需运行：

```powershell
cd D:\code\RedInk
.\deployment\setup-cicd.ps1
```

脚本会自动完成：
1. ✅ 检查并安装 GitHub CLI
2. ✅ 登录 GitHub
3. ✅ 交互式收集配置信息
4. ✅ 配置所有必需的 GitHub Secrets
5. ✅ 验证配置
6. ✅ 可选：立即推送触发部署

## 📋 配置信息准备

运行脚本前，请准备好以下信息：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| **服务器 IP** | 你的服务器地址 | `192.168.1.100` |
| **SSH 用户名** | SSH 登录用户 | `root` |
| **SSH 端口** | SSH 端口号 | `22` |
| **部署路径** | 服务器上的项目路径 | `/opt/redink` |
| **SSH 私钥** | 私钥文件完整路径 | `D:\code\ai-content-platform\deployment\.github-actions-keys\id_rsa` |

## 🔧 手动配置（备选方案）

如果你想手动配置，可以按照以下步骤：

### 1. 安装 GitHub CLI

```powershell
winget install --id GitHub.cli
```

### 2. 登录 GitHub

```powershell
gh auth login
```

### 3. 设置 Secrets

```powershell
# 设置服务器信息
gh secret set SERVER_HOST -b"你的服务器IP"
gh secret set SERVER_USER -b"root"
gh secret set SERVER_PORT -b"22"
gh secret set DEPLOY_PATH -b"/opt/redink"

# 设置 SSH 私钥
Get-Content "D:\code\ai-content-platform\deployment\.github-actions-keys\id_rsa" | gh secret set SERVER_SSH_KEY
```

### 4. 验证配置

```powershell
gh secret list
```

## 🎯 部署流程

### 自动部署（推荐）

推送代码到 main 分支自动触发：

```bash
git add .
git commit -m "feat: your changes"
git push origin main
```

### 手动部署

```powershell
# 触发 workflow
gh workflow run deploy.yml

# 查看运行状态
gh run watch
```

## 📊 监控部署

### 实时监控

```powershell
# 查看最新运行
gh run watch

# 查看所有运行
gh run list

# 查看特定运行的日志
gh run view <run-id> --log
```

### 网页查看

访问：`https://github.com/你的用户名/RedInk/actions`

## 🏗️ 工作原理

新的 CI/CD 流程：

```
代码推送 → GitHub Actions
    ↓
SSH 连接到服务器
    ↓
克隆/更新代码
    ↓
本地构建 Docker 镜像
    ↓
停止旧容器
    ↓
启动新容器
    ↓
清理旧镜像和备份
    ↓
完成部署 ✅
```

**优势：**
- ❌ 不需要 Docker Hub
- ✅ 直接在服务器构建和部署
- ✅ 更快的部署速度
- ✅ 自动备份旧版本
- ✅ 自动清理旧镜像

## 📁 项目结构

```
D:\code\RedInk\
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD 配置文件
├── deployment/
│   ├── setup-cicd.ps1          # 自动配置脚本 ⭐
│   ├── deploy.sh               # 服务器部署脚本
│   ├── QUICKSTART.md          # 本文件 ⭐
│   ├── DEPLOYMENT.md          # 详细部署文档
│   └── GITHUB_CLI_SETUP.md    # GitHub CLI 详细指南
├── docker-compose.yml          # Docker Compose 配置
└── Dockerfile                  # Docker 镜像配置
```

## 🔍 故障排除

### 问题1: GitHub CLI 未安装

```powershell
winget install --id GitHub.cli
# 然后重启终端
```

### 问题2: SSH 连接失败

检查服务器上的公钥配置：

```bash
# 在服务器上执行
cat ~/.ssh/authorized_keys
```

确保对应的公钥已添加。

### 问题3: 部署失败

查看详细日志：

```powershell
gh run view --log
```

或在服务器上检查：

```bash
cd /opt/redink/redink
docker-compose logs
```

### 问题4: 权限不足

确保：
- 你有 GitHub 仓库的管理员权限
- 服务器用户有 Docker 权限
- 部署目录有写入权限

## 🎯 下一步

1. ✅ 运行 `.\deployment\setup-cicd.ps1`
2. ✅ 按提示输入配置信息
3. ✅ 推送代码触发部署
4. ✅ 访问 `http://你的服务器:12398`

## 💡 提示

- 首次部署需要在服务器上安装 Docker 和 git
- 确保服务器的 12398 端口已开放
- 可以使用 `git tag v1.0.0` 创建版本标签
- 部署历史会保留最近 3 个备份版本

## 📚 更多文档

- [详细部署指南](./DEPLOYMENT.md)
- [GitHub CLI 完整教程](./GITHUB_CLI_SETUP.md)

---

**需要帮助？** 查看日志或联系技术支持。
