# RedInk CI/CD 自动配置脚本
# 使用 GitHub CLI 一键配置部署所需的所有内容

param(
    [string]$SSHKeyPath = "D:\code\ai-content-platform\deployment\.github-actions-keys\id_rsa"
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# 检查命令是否存在
function Test-Command {
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# 标题
Clear-Host
Write-ColorOutput "╔═══════════════════════════════════════════╗" Cyan
Write-ColorOutput "║     🚀 RedInk CI/CD 自动配置向导         ║" Cyan
Write-ColorOutput "╚═══════════════════════════════════════════╝" Cyan
Write-Host ""

# 1. 检查 GitHub CLI
Write-ColorOutput "📋 步骤 1/6: 检查环境..." Yellow
if (-not (Test-Command "gh")) {
    Write-ColorOutput "❌ GitHub CLI 未安装！" Red
    Write-ColorOutput "正在安装 GitHub CLI..." Yellow
    
    if (Test-Command "winget") {
        winget install --id GitHub.cli -e --silent
        Write-ColorOutput "✅ GitHub CLI 安装完成，请重新打开终端后再运行此脚本" Green
    } else {
        Write-ColorOutput "请手动安装: https://cli.github.com" Red
    }
    exit 1
}

Write-ColorOutput "✅ GitHub CLI 已安装" Green

# 2. 检查登录状态
Write-ColorOutput "`n📋 步骤 2/6: 检查 GitHub 登录状态..." Yellow
$authStatus = gh auth status 2>&1 | Out-String

if ($authStatus -match "not logged|not authenticated") {
    Write-ColorOutput "需要登录 GitHub，即将打开浏览器..." Yellow
    gh auth login
} else {
    Write-ColorOutput "✅ 已登录 GitHub" Green
}

# 3. 收集配置信息
Write-ColorOutput "`n📋 步骤 3/6: 收集配置信息..." Yellow
Write-Host ""

Write-ColorOutput "请输入以下配置信息（按回车使用默认值）：" Cyan
Write-Host ""

# 服务器信息
$SERVER_HOST = Read-Host "🖥️  服务器 IP 或域名"
while ([string]::IsNullOrWhiteSpace($SERVER_HOST)) {
    Write-ColorOutput "❌ 服务器地址不能为空" Red
    $SERVER_HOST = Read-Host "🖥️  服务器 IP 或域名"
}

$SERVER_USER = Read-Host "👤 SSH 用户名 (默认: root)"
if ([string]::IsNullOrWhiteSpace($SERVER_USER)) { 
    $SERVER_USER = "root" 
}

$SERVER_PORT = Read-Host "🔌 SSH 端口 (默认: 22)"
if ([string]::IsNullOrWhiteSpace($SERVER_PORT)) { 
    $SERVER_PORT = "22" 
}

$DEPLOY_PATH = Read-Host "📁 部署路径 (默认: /opt/redink)"
if ([string]::IsNullOrWhiteSpace($DEPLOY_PATH)) { 
    $DEPLOY_PATH = "/opt/redink" 
}

# SSH 密钥路径
Write-Host ""
Write-ColorOutput "🔑 SSH 私钥配置" Cyan
if (-not [string]::IsNullOrWhiteSpace($SSHKeyPath)) {
    Write-ColorOutput "检测到默认密钥路径: $SSHKeyPath" Gray
    $useDefault = Read-Host "使用此路径? (Y/n)"
    if ($useDefault -eq "n" -or $useDefault -eq "N") {
        $SSHKeyPath = Read-Host "请输入 SSH 私钥完整路径"
    }
} else {
    $SSHKeyPath = Read-Host "请输入 SSH 私钥完整路径"
}

# 验证文件存在
while (-not (Test-Path $SSHKeyPath)) {
    Write-ColorOutput "❌ 文件不存在: $SSHKeyPath" Red
    $SSHKeyPath = Read-Host "请重新输入 SSH 私钥路径"
}

Write-ColorOutput "✅ SSH 私钥文件已找到" Green

# 4. 配置摘要
Write-Host ""
Write-ColorOutput "📋 步骤 4/6: 确认配置信息" Yellow
Write-Host ""
Write-ColorOutput "╔════════════════════════════════════════════╗" Cyan
Write-ColorOutput "  服务器地址: $SERVER_HOST" White
Write-ColorOutput "  SSH 用户:   $SERVER_USER" White
Write-ColorOutput "  SSH 端口:   $SERVER_PORT" White
Write-ColorOutput "  部署路径:   $DEPLOY_PATH" White
Write-ColorOutput "  SSH 密钥:   $SSHKeyPath" White
Write-ColorOutput "╚════════════════════════════════════════════╝" Cyan
Write-Host ""

$confirm = Read-Host "确认以上信息正确? (Y/n)"
if ($confirm -eq "n" -or $confirm -eq "N") {
    Write-ColorOutput "❌ 配置已取消" Red
    exit 0
}

# 5. 配置 GitHub Secrets
Write-Host ""
Write-ColorOutput "📋 步骤 5/6: 配置 GitHub Secrets..." Yellow
Write-Host ""

try {
    # 设置服务器信息
    Write-ColorOutput "⏳ 设置 SERVER_HOST..." Gray
    gh secret set SERVER_HOST -b"$SERVER_HOST"
    Write-ColorOutput "  ✓ SERVER_HOST" Green
    
    Write-ColorOutput "⏳ 设置 SERVER_USER..." Gray
    gh secret set SERVER_USER -b"$SERVER_USER"
    Write-ColorOutput "  ✓ SERVER_USER" Green
    
    Write-ColorOutput "⏳ 设置 SERVER_PORT..." Gray
    gh secret set SERVER_PORT -b"$SERVER_PORT"
    Write-ColorOutput "  ✓ SERVER_PORT" Green
    
    Write-ColorOutput "⏳ 设置 DEPLOY_PATH..." Gray
    gh secret set DEPLOY_PATH -b"$DEPLOY_PATH"
    Write-ColorOutput "  ✓ DEPLOY_PATH" Green
    
    Write-ColorOutput "⏳ 设置 SERVER_SSH_KEY..." Gray
    Get-Content $SSHKeyPath -Raw | gh secret set SERVER_SSH_KEY
    Write-ColorOutput "  ✓ SERVER_SSH_KEY" Green
    
    Write-Host ""
    Write-ColorOutput "✅ 所有 Secrets 配置完成！" Green
    
} catch {
    Write-ColorOutput "❌ 配置失败: $($_.Exception.Message)" Red
    Write-ColorOutput "请检查您是否有仓库的管理员权限" Yellow
    exit 1
}

# 6. 验证配置
Write-Host ""
Write-ColorOutput "📋 步骤 6/6: 验证配置..." Yellow
Write-Host ""

Write-ColorOutput "已配置的 Secrets:" Cyan
gh secret list

# 显示后续步骤
Write-Host ""
Write-ColorOutput "╔═══════════════════════════════════════════╗" Green
Write-ColorOutput "║          🎉 配置完成！                    ║" Green
Write-ColorOutput "╚═══════════════════════════════════════════╝" Green
Write-Host ""

Write-ColorOutput "📝 下一步操作：" Cyan
Write-Host ""

Write-ColorOutput "1️⃣  提交更改到 Git：" Yellow
Write-ColorOutput "   git add ." Gray
Write-ColorOutput "   git commit -m 'feat: 配置 CI/CD 自动部署'" Gray
Write-Host ""

Write-ColorOutput "2️⃣  推送到 GitHub 触发部署：" Yellow
Write-ColorOutput "   git push origin main" Gray
Write-Host ""

Write-ColorOutput "3️⃣  查看部署状态：" Yellow
Write-ColorOutput "   gh run watch" Gray
Write-ColorOutput "   或访问: https://github.com/$((gh repo view --json nameWithOwner -q .nameWithOwner))/actions" Gray
Write-Host ""

Write-ColorOutput "4️⃣  手动触发部署（可选）：" Yellow
Write-ColorOutput "   gh workflow run deploy.yml" Gray
Write-Host ""

Write-ColorOutput "📚 更多帮助文档：" Cyan
Write-ColorOutput "   - deployment/DEPLOYMENT.md" Gray
Write-ColorOutput "   - deployment/GITHUB_CLI_SETUP.md" Gray
Write-Host ""

# 询问是否立即推送
$pushNow = Read-Host "是否现在就提交并推送代码触发部署? (y/N)"
if ($pushNow -eq "y" -or $pushNow -eq "Y") {
    Write-Host ""
    Write-ColorOutput "📤 准备提交和推送..." Yellow
    
    try {
        # 检查是否有未提交的更改
        git add .
        git commit -m "feat: 配置 CI/CD 自动部署"
        git push origin main
        
        Write-Host ""
        Write-ColorOutput "✅ 代码已推送！部署即将开始..." Green
        Write-Host ""
        Write-ColorOutput "监控部署进度..." Cyan
        Start-Sleep -Seconds 3
        gh run watch
        
    } catch {
        Write-ColorOutput "⚠️  推送时出现问题: $($_.Exception.Message)" Yellow
        Write-ColorOutput "您可以手动执行: git push origin main" Gray
    }
} else {
    Write-ColorOutput "💡 准备好后，运行: git push origin main" Yellow
}

Write-Host ""
Write-ColorOutput "感谢使用 RedInk CI/CD 配置向导！" Cyan
