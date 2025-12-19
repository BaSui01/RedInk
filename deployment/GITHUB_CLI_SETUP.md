# GitHub CLI 配置指南

GitHub CLI (gh) 是 GitHub 官方提供的命令行工具，可以方便地管理仓库、issue、PR 和 Secrets。

## 📦 安装 GitHub CLI

### Windows (推荐使用 winget)

```powershell
# 使用 winget 安装（Windows 10/11 自带）
winget install --id GitHub.cli

# 或使用 scoop
scoop install gh

# 或使用 Chocolatey
choco install gh
```

### macOS

```bash
brew install gh
```

### Linux

```bash
# Debian/Ubuntu
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Fedora/RHEL/CentOS
sudo dnf install gh
```

## 🔐 登录 GitHub

安装完成后，需要先登录：

```bash
# 交互式登录
gh auth login

# 按照提示选择：
# 1. GitHub.com
# 2. HTTPS
# 3. Yes (authenticate with browser)
# 4. 会打开浏览器进行授权
```

验证登录状态：

```bash
gh auth status
```

## 🎯 使用 GitHub CLI 配置 Secrets

### 1. 设置仓库 Secrets

```bash
# 进入你的项目目录
cd D:\code\RedInk

# 添加服务器 IP
gh secret set SERVER_HOST -b"你的服务器IP"

# 添加服务器用户名
gh secret set SERVER_USER -b"root"

# 添加服务器 SSH 端口（可选）
gh secret set SERVER_PORT -b"22"

# 添加部署路径
gh secret set DEPLOY_PATH -b"/opt/redink"

# 添加 Docker Hub 密码
gh secret set DOCKER_PASSWORD -b"你的DockerHub密码"

# 从文件添加 SSH 私钥
gh secret set SERVER_SSH_KEY < D:\code\ai-content-platform\deployment\.github-actions-keys\id_rsa

# 或者手动输入（会提示输入内容）
gh secret set SERVER_SSH_KEY
# 然后粘贴私钥内容，按 Ctrl+D (Linux/Mac) 或 Ctrl+Z (Windows) 结束
```

### 2. 查看已配置的 Secrets

```bash
# 列出所有 secrets（不显示值）
gh secret list

# 查看某个 secret 的信息
gh secret view SERVER_HOST
```

### 3. 删除 Secret

```bash
gh secret delete SECRET_NAME
```

### 4. 批量导入 Secrets

创建一个临时脚本来批量设置：

**Windows PowerShell** (`setup-secrets.ps1`):

```powershell
# 设置基本变量
$SERVER_HOST = "你的服务器IP"
$SERVER_USER = "root"
$SERVER_PORT = "22"
$DEPLOY_PATH = "/opt/redink"
$DOCKER_PASSWORD = "你的DockerHub密码"
$SSH_KEY_PATH = "D:\code\ai-content-platform\deployment\.github-actions-keys\id_rsa"

# 设置 secrets
gh secret set SERVER_HOST -b"$SERVER_HOST"
gh secret set SERVER_USER -b"$SERVER_USER"
gh secret set SERVER_PORT -b"$SERVER_PORT"
gh secret set DEPLOY_PATH -b"$DEPLOY_PATH"
gh secret set DOCKER_PASSWORD -b"$DOCKER_PASSWORD"

# 设置 SSH 密钥
Get-Content $SSH_KEY_PATH | gh secret set SERVER_SSH_KEY

Write-Host "✅ 所有 Secrets 配置完成！" -ForegroundColor Green
```

运行脚本：

```powershell
cd D:\code\RedInk
.\deployment\setup-secrets.ps1
```

**Linux/macOS** (`setup-secrets.sh`):

```bash
#!/bin/bash

# 设置基本变量
SERVER_HOST="你的服务器IP"
SERVER_USER="root"
SERVER_PORT="22"
DEPLOY_PATH="/opt/redink"
DOCKER_PASSWORD="你的DockerHub密码"
SSH_KEY_PATH="~/.ssh/deploy_key"

# 设置 secrets
gh secret set SERVER_HOST -b"$SERVER_HOST"
gh secret set SERVER_USER -b"$SERVER_USER"
gh secret set SERVER_PORT -b"$SERVER_PORT"
gh secret set DEPLOY_PATH -b"$DEPLOY_PATH"
gh secret set DOCKER_PASSWORD -b"$DOCKER_PASSWORD"
gh secret set SERVER_SSH_KEY < "$SSH_KEY_PATH"

echo "✅ 所有 Secrets 配置完成！"
```

## 🔄 其他有用的 GitHub CLI 命令

### 查看 Workflows

```bash
# 列出所有 workflows
gh workflow list

# 查看 workflow 运行历史
gh run list

# 查看最近一次运行的详情
gh run view

# 查看特定运行的日志
gh run view 1234567890

# 手动触发 workflow
gh workflow run "Build and Push Docker Image"
```

### 管理仓库

```bash
# 查看仓库信息
gh repo view

# 克隆仓库
gh repo clone owner/repo

# 创建仓库
gh repo create
```

### 管理 Issues 和 PR

```bash
# 列出 issues
gh issue list

# 创建 issue
gh issue create

# 列出 PRs
gh pr list

# 查看 PR
gh pr view 123
```

## 🚀 快速配置脚本（推荐）

保存以下内容为 `setup-deployment.ps1`：

```powershell
# RedInk GitHub Actions 部署配置脚本

Write-Host "🚀 RedInk 部署配置向导" -ForegroundColor Cyan
Write-Host ""

# 检查 gh cli 是否安装
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI 未安装！" -ForegroundColor Red
    Write-Host "请先安装: winget install --id GitHub.cli" -ForegroundColor Yellow
    exit 1
}

# 检查是否已登录
$authStatus = gh auth status 2>&1
if ($authStatus -match "not logged") {
    Write-Host "请先登录 GitHub..." -ForegroundColor Yellow
    gh auth login
}

Write-Host "✅ GitHub CLI 已就绪" -ForegroundColor Green
Write-Host ""

# 收集配置信息
Write-Host "请输入以下配置信息：" -ForegroundColor Cyan
Write-Host ""

$SERVER_HOST = Read-Host "服务器 IP 或域名"
$SERVER_USER = Read-Host "SSH 用户名 (默认: root)" 
if ([string]::IsNullOrWhiteSpace($SERVER_USER)) { $SERVER_USER = "root" }

$SERVER_PORT = Read-Host "SSH 端口 (默认: 22)"
if ([string]::IsNullOrWhiteSpace($SERVER_PORT)) { $SERVER_PORT = "22" }

$DEPLOY_PATH = Read-Host "部署路径 (默认: /opt/redink)"
if ([string]::IsNullOrWhiteSpace($DEPLOY_PATH)) { $DEPLOY_PATH = "/opt/redink" }

$DOCKER_PASSWORD = Read-Host "Docker Hub 密码" -AsSecureString
$DOCKER_PASSWORD_TEXT = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($DOCKER_PASSWORD))

$SSH_KEY_PATH = Read-Host "SSH 私钥文件路径"

# 验证文件存在
if (!(Test-Path $SSH_KEY_PATH)) {
    Write-Host "❌ SSH 私钥文件不存在: $SSH_KEY_PATH" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "开始配置 GitHub Secrets..." -ForegroundColor Cyan

try {
    gh secret set SERVER_HOST -b"$SERVER_HOST"
    Write-Host "✓ SERVER_HOST" -ForegroundColor Green
    
    gh secret set SERVER_USER -b"$SERVER_USER"
    Write-Host "✓ SERVER_USER" -ForegroundColor Green
    
    gh secret set SERVER_PORT -b"$SERVER_PORT"
    Write-Host "✓ SERVER_PORT" -ForegroundColor Green
    
    gh secret set DEPLOY_PATH -b"$DEPLOY_PATH"
    Write-Host "✓ DEPLOY_PATH" -ForegroundColor Green
    
    gh secret set DOCKER_PASSWORD -b"$DOCKER_PASSWORD_TEXT"
    Write-Host "✓ DOCKER_PASSWORD" -ForegroundColor Green
    
    Get-Content $SSH_KEY_PATH | gh secret set SERVER_SSH_KEY
    Write-Host "✓ SERVER_SSH_KEY" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "🎉 所有配置完成！" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步：" -ForegroundColor Cyan
    Write-Host "1. 提交代码: git add . && git commit -m 'feat: add deployment config'" -ForegroundColor Yellow
    Write-Host "2. 推送到 GitHub: git push origin main" -ForegroundColor Yellow
    Write-Host "3. 查看部署状态: gh run watch" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ 配置失败: $_" -ForegroundColor Red
    exit 1
}
```

运行脚本：

```powershell
cd D:\code\RedInk
.\deployment\setup-deployment.ps1
```

## 📝 验证配置

配置完成后，验证所有 secrets：

```bash
gh secret list
```

应该看到：
- ✓ SERVER_HOST
- ✓ SERVER_USER
- ✓ SERVER_PORT
- ✓ DEPLOY_PATH
- ✓ DOCKER_PASSWORD
- ✓ SERVER_SSH_KEY

## 🎯 触发部署

```bash
# 推送代码自动触发
git push origin main

# 手动触发
gh workflow run "Build and Push Docker Image"

# 实时查看运行状态
gh run watch
```

## 🔍 常见问题

### 1. GitHub CLI 命令无法识别

**解决方案**: 
```powershell
# 重启终端或刷新环境变量
refreshenv  # 如果使用 Chocolatey
# 或重新打开 PowerShell
```

### 2. 无法读取文件内容

**解决方案**:
```powershell
# 确保文件路径正确且文件存在
Test-Path "D:\code\ai-content-platform\deployment\.github-actions-keys\id_rsa"

# 使用绝对路径
Get-Content "D:\path\to\file" | gh secret set SECRET_NAME
```

### 3. 权限不足

**错误**: `HTTP 403: Resource not accessible by integration`

**解决方案**:
- 确保你有仓库的管理员权限
- 重新登录: `gh auth login -h github.com`

## 📚 更多资源

- [GitHub CLI 官方文档](https://cli.github.com/manual/)
- [GitHub Secrets 文档](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
