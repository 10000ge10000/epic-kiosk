#!/bin/bash
# ============================================================
# Epic Kiosk - 自动驾驶领取系统
# ============================================================
# GitHub: https://github.com/10000ge10000/epic-kiosk
# 公益站点: https://epic.910501.xyz/
# ============================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 打印标题
print_header() {
    echo -e "${CYAN}"
    echo "Epic Kiosk - 自动驾驶领取系统"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${GREEN}▶ $1${NC}\n"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统架构
check_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            print_success "系统架构: x86_64"
            ;;
        aarch64|arm64)
            print_success "系统架构: ARM64"
            ;;
        *)
            print_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
}

# 检查 Docker 是否安装
check_docker() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version 2>/dev/null || echo "未知版本")
        print_success "Docker: $DOCKER_VERSION"
        return 0
    else
        return 1
    fi
}

# 检查 Docker Compose 是否可用
check_docker_compose() {
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "已安装")
        print_success "Docker Compose: $COMPOSE_VERSION"
        return 0
    else
        return 1
    fi
}

# 显示 Docker 安装命令
show_docker_install_commands() {
    echo ""
    echo -e "${YELLOW}请先安装 Docker，以下是一键安装命令：${NC}"
    echo ""
    echo -e "${CYAN}【国内服务器】${NC}"
    echo -e "  curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun"
    echo ""
    echo -e "${CYAN}【海外服务器】${NC}"
    echo -e "  curl -fsSL https://get.docker.com | bash"
    echo ""
    echo -e "${YELLOW}安装完成后，请重新运行此脚本${NC}"
    echo ""
}

# API Key 配置向导
configure_api_key() {
    print_step "配置 API Key"

    echo -e "${CYAN}硅基流动 (SiliconFlow) 是什么？${NC}"
    echo "  国内 AI 模型推理平台，提供 Qwen 等开源模型的 API 服务"
    echo -e "  特点：价格低、速度快、主力模型${RED}免费${NC}使用"
    echo ""
    echo -e "${GREEN}获取 API Key 步骤：${NC}"
    echo ""
    echo -e "${CYAN}1. 访问邀请链接${NC}"
    echo -e "   ${YELLOW}https://cloud.siliconflow.cn/i/OVI2n57p${NC}"
    echo "   （双方各得 ¥16 代金券）"
    echo ""
    echo -e "${CYAN}2. 注册账号${NC}"
    echo "   支持手机号/微信注册"
    echo ""
    echo -e "${CYAN}3. 创建 API Key${NC}"
    echo "   控制台 → API 密钥 → 创建新密钥"
    echo "   复制生成的密钥（以 sk- 开头）"
    echo ""

    # 输入 API Key（从 /dev/tty 读取，支持 curl | bash 管道运行）
    while true; do
        echo ""
        read -p "请输入你的 API Key (sk-xxx): " api_key < /dev/tty

        if [[ -z "$api_key" ]]; then
            print_error "API Key 不能为空"
            continue
        fi

        if [[ ! "$api_key" =~ ^sk- ]]; then
            print_warning "API Key 通常以 sk- 开头，请确认"
        fi

        echo ""
        echo -e "你输入的: ${YELLOW}${api_key}${NC}"
        read -p "确认无误? [Y/n]: " confirm_key < /dev/tty
        confirm_key=${confirm_key:-Y}

        if [[ "$confirm_key" =~ ^[Yy] ]]; then
            SILICONFLOW_API_KEY="$api_key"
            break
        fi
    done

    print_success "API Key 已设置"
}

# 克隆项目
clone_project() {
    print_step "获取项目代码"

    PROJECT_DIR="/opt/epic-kiosk"

    if [ -d "$PROJECT_DIR" ]; then
        print_warning "目录 $PROJECT_DIR 已存在"
        read -p "是否删除重新克隆? [y/N]: " reclone < /dev/tty
        reclone=${reclone:-N}

        if [[ "$reclone" =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_DIR"
        else
            print_info "使用现有目录"
            return 0
        fi
    fi

    # 检查 git
    if ! command -v git &> /dev/null; then
        print_info "安装 git..."
        if command -v apt-get &> /dev/null; then
            apt-get update -qq && apt-get install -y -qq git
        elif command -v yum &> /dev/null; then
            yum install -y -q git
        fi
    fi

    print_info "克隆项目..."
    git clone -b main https://github.com/10000ge10000/epic-kiosk.git "$PROJECT_DIR"

    print_success "项目克隆完成"
}

# 配置并启动服务
deploy_service() {
    print_step "部署服务"

    cd "$PROJECT_DIR"

    # 替换 API Key
    print_info "配置 API Key..."
    if [ -f "docker-compose.yml" ]; then
        sed -i "s|SILICONFLOW_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|SILICONFLOW_API_KEY=$SILICONFLOW_API_KEY|g" docker-compose.yml
    else
        print_error "docker-compose.yml 不存在"
        exit 1
    fi

    # 拉取镜像
    print_info "拉取镜像（首次需要几分钟）..."
    docker compose pull 2>&1 || {
        print_warning "部分镜像拉取失败，尝试本地构建..."
        docker compose up -d --build
    }

    # 启动服务
    print_info "启动服务..."
    docker compose up -d

    # 等待服务启动
    print_info "等待服务启动..."
    sleep 5

    # 检查服务状态
    if docker compose ps 2>/dev/null | grep -q "Up\|running"; then
        print_success "服务启动成功"
    else
        print_warning "服务状态异常，查看日志..."
        docker compose logs --tail 20
    fi
}

# 显示完成信息
show_complete() {
    # 只显示公网 IPv4 地址
    PUBLIC_IP=$(curl -4 -s --connect-timeout 3 ifconfig.me 2>/dev/null)

    echo ""
    echo -e "${GREEN}部署完成！${NC}"
    echo ""
    echo -e "${CYAN}访问地址:${NC}"
    if [[ -n "$PUBLIC_IP" && "$PUBLIC_IP" != "127.0.0.1" ]]; then
        echo -e "  公网: ${YELLOW}http://$PUBLIC_IP:18000${NC}"
    else
        echo -e "  公网: ${YELLOW}未检测到公网 IPv4，请检查服务器网络${NC}"
    fi
    echo ""
    echo -e "${CYAN}常用命令:${NC}"
    echo "  查看状态: docker compose ps"
    echo "  查看日志: docker logs epic-worker -f"
    echo "  重启服务: docker compose restart"
    echo ""
    echo -e "${CYAN}相关链接:${NC}"
    echo "  公益站点: https://epic.910501.xyz/"
    echo "  GitHub: https://github.com/10000ge10000/epic-kiosk"
    echo "  B 站: https://space.bilibili.com/59438380"
    echo ""
}

# 主函数
main() {
    print_header

    # 检查系统架构
    print_step "系统检查"
    check_arch

    # 检查 Docker
    print_info "检查 Docker..."
    if ! check_docker; then
        print_error "未检测到 Docker"
        show_docker_install_commands
        exit 1
    fi

    # 检查 Docker Compose
    print_info "检查 Docker Compose..."
    if ! check_docker_compose; then
        print_error "Docker Compose 不可用"
        print_info "请更新 Docker 到最新版本"
        exit 1
    fi

    # 配置 API Key
    configure_api_key

    # 克隆项目
    clone_project

    # 部署服务
    deploy_service

    # 完成
    show_complete
}

# 运行
main "$@"
