#!/bin/bash

# 红墨服务器部署脚本
# 该脚本用于在服务器上部署/更新红墨应用

set -e  # 遇到错误立即退出

# 配置变量
IMAGE_NAME="histonemax/redink:latest"
CONTAINER_NAME="redink"
COMPOSE_FILE="docker-compose.yml"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== 红墨部署脚本 ===${NC}"
echo -e "${YELLOW}开始时间: $(date)${NC}"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    exit 1
fi

# 检查 docker compose 是否可用
if ! docker compose version &> /dev/null; then
    echo -e "${RED}错误: docker compose 未安装${NC}"
    exit 1
fi

# 备份当前运行的容器（可选）
echo -e "${YELLOW}备份当前容器状态...${NC}"
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    docker commit $CONTAINER_NAME ${CONTAINER_NAME}_backup_$(date +%Y%m%d_%H%M%S) || true
fi

# 拉取最新镜像
echo -e "${YELLOW}拉取最新镜像...${NC}"
docker pull $IMAGE_NAME

# 停止并删除旧容器
echo -e "${YELLOW}停止旧容器...${NC}"
docker compose down

# 启动新容器
echo -e "${YELLOW}启动新容器...${NC}"
docker compose up -d

# 等待容器启动
echo -e "${YELLOW}等待容器启动...${NC}"
sleep 5

# 检查容器状态
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo -e "${GREEN}✅ 容器启动成功！${NC}"
    docker compose ps
else
    echo -e "${RED}❌ 容器启动失败！${NC}"
    docker compose logs --tail=50
    exit 1
fi

# 清理未使用的镜像
echo -e "${YELLOW}清理未使用的镜像...${NC}"
docker image prune -f

# 显示容器日志
echo -e "${GREEN}=== 最近的日志 ===${NC}"
docker compose logs --tail=20

echo -e "${GREEN}=== 部署完成 ===${NC}"
echo -e "${YELLOW}结束时间: $(date)${NC}"
