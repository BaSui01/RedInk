# GitHub Actions 部署配置指南

本指南将帮助你配置 GitHub Actions 自动部署到服务器。

## 📋 前置要求

1. 一台 Linux 服务器（已安装 Docker 和 docker-compose）
2. 服务器 SSH 访问权限
3. GitHub 仓库管理员权限

## 🔐 第一步：准备服务器 SSH 密钥

### 方法1: 使用现有密钥（如果你已经有了）

如果你在 `D:\code\ai-content-platform\deployment\.github-actions-keys` 目录有准备好的密钥：

1. 找到私钥文件（通常名为 `id_rsa` 或 `deploy_key`）
2. 用文本编辑器打开并复制完整内容（包括 `-----BEGIN ... KEY-----` 和 `-----END ... KEY-----`）

### 方法2: 在服务器上生成新密钥

在服务器上执行以下命令：

```bash
# 生成 SSH 密钥对
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/github-actions -N ""

# 将公钥添加到授权列表
cat ~/.ssh/github-actions.pub >> ~/.ssh/authorized_keys

# 显示私钥（复制此内容）
cat ~/.ssh/github-actions
```

## 🔧 第二步：配置 GitHub Secrets

### 使用网页界面配置

1. 打开你的 GitHub 仓库
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret** 添加以下密钥：

| Secret 名称 | 说明 | 示例 |
|------------|------|------|
| `SERVER_HOST` | 服务器 IP 地址或域名 | `192.168.1.100` 或 `example.com` |
| `SERVER_USER` | SSH 登录用户名 | `root` 或 `ubuntu` |
| `SERVER_SSH_KEY` | SSH 私钥内容 | 完整的私钥文件内容 |
| `SERVER_PORT` | SSH 端口（可选，默认22） | `22` |
| `DEPLOY_PATH` | 服务器上的部署路径 | `/opt/redink` 或 `/home/user/redink` |
| `DOCKER_PASSWORD` | Docker Hub 密码 | 你的 Docker Hub 密码 |

### 使用 GitHub CLI 配置（推荐）

见下方 GitHub CLI 配置部分。

## 📁 第三步：在服务器上准备部署目录

在服务器上执行：

```bash
# 创建部署目录
mkdir -p /opt/redink
cd /opt/redink

# 创建必要的子目录
mkdir -p history images

# 创建 docker-compose.yml 文件（或从仓库下载）
# 确保文件存在且配置正确
```

将你的 `docker-compose.yml` 上传到服务器的部署目录。

## 🚀 第四步：测试部署

### 手动触发部署

1. 进入 GitHub 仓库
2. 点击 **Actions** 标签
3. 选择 **Build and Push Docker Image** workflow
4. 点击 **Run workflow** → **Run workflow**

### 自动触发部署

每次推送到 `main` 分支或创建 `v*` 标签时会自动触发：

```bash
# 推送代码触发部署
git push origin main

# 或创建版本标签触发部署
git tag v1.0.0
git push origin v1.0.0
```

## ✅ 验证部署

部署完成后，访问：

```
http://你的服务器IP:12398
```

## 🔍 常见问题

### 1. SSH 连接失败

**错误**: `Permission denied (publickey)`

**解决方案**:
- 确保私钥格式正确（包含开始和结束标记）
- 检查服务器 `~/.ssh/authorized_keys` 是否包含对应的公钥
- 验证 SSH 端口是否正确

```bash
# 在服务器上检查
cat ~/.ssh/authorized_keys
sudo systemctl status ssh
```

### 2. Docker 拉取失败

**错误**: `Error response from daemon: pull access denied`

**解决方案**:
- 确认 Docker Hub 用户名和密码正确
- 检查镜像名称是否正确

### 3. 容器启动失败

**解决方案**:
```bash
# 在服务器上检查日志
cd /opt/redink
docker-compose logs
```

### 4. 端口被占用

**错误**: `port is already allocated`

**解决方案**:
```bash
# 检查端口占用
sudo lsof -i :12398

# 修改 docker-compose.yml 中的端口映射
```

## 📝 安全建议

1. **使用专用部署密钥**: 不要使用个人 SSH 密钥
2. **限制 SSH 密钥权限**: 在服务器上配置 SSH 密钥只能执行部署相关命令
3. **使用非 root 用户**: 创建专门的部署用户
4. **定期轮换密钥**: 每 3-6 个月更换一次部署密钥
5. **启用防火墙**: 只开放必要的端口

## 🔄 部署流程说明

1. **触发**: 代码推送到 main 分支或创建标签
2. **构建**: GitHub Actions 构建 Docker 镜像
3. **推送**: 镜像推送到 Docker Hub
4. **部署**: SSH 到服务器，拉取最新镜像并重启容器
5. **验证**: 检查容器状态

## 📞 需要帮助？

如果遇到问题：
1. 检查 GitHub Actions 日志
2. 检查服务器上的 Docker 日志
3. 查看本文档的常见问题部分
