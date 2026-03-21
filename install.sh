#!/bin/bash
# ============================================================
# Epic Kiosk 一键部署脚本
# ============================================================
# GitHub: https://github.com/10000ge10000/epic-kiosk
# 公益站点: https://epic.910501.xyz/
# ============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          Epic Kiosk - 自动驾驶领取系统                      ║"
    echo "║          一键部署脚本 v1.0                                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统架构
check_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            ARCH_TYPE="x86_64"
            print_success "系统架构: x86_64 (Intel/AMD)"
            ;;
        aarch64|arm64)
            ARCH_TYPE="arm64"
            print_success "系统架构: ARM64 (树莓派/甲骨文ARM等)"
            ;;
        *)
            print_error "不支持的系统架构: $ARCH"
            exit 1
            ;;
    esac
}

# 检查操作系统
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        print_success "操作系统: $PRETTY_NAME"
    else
        print_warning "无法检测操作系统版本"
        OS="unknown"
    fi
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_warning "建议使用 root 用户运行此脚本"
        print_info "正在尝试使用 sudo..."
        if command -v sudo &> /dev/null; then
            exec sudo bash "$0" "$@"
        else
            print_error "请使用 root 用户或安装 sudo"
            exit 1
        fi
    fi
}

# 安装 Docker
install_docker() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        print_success "Docker 已安装: $DOCKER_VERSION"
        return 0
    fi

    print_step "安装 Docker"

    # 询问用户是否安装
    echo -e "${YELLOW}检测到系统未安装 Docker${NC}"
    read -p "是否自动安装 Docker? [Y/n]: " install_choice
    install_choice=${install_choice:-Y}

    if [[ ! "$install_choice" =~ ^[Yy]$ ]]; then
        print_error "Docker 是必需的，请手动安装后重试"
        print_info "安装指南: https://docs.docker.com/engine/install/"
        exit 1
    fi

    print_info "正在安装 Docker..."

    # 使用官方安装脚本
    curl -fsSL https://get.docker.com | sh

    # 启动 Docker 服务
    systemctl enable docker
    systemctl start docker

    # 将当前用户加入 docker 组（如果不是 root）
    if [ "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
        print_info "已将用户 $SUDO_USER 加入 docker 组"
        print_warning "请重新登录以生效 docker 组权限"
    fi

    print_success "Docker 安装完成!"
}

# 安装 Docker Compose
install_docker_compose() {
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version)
        print_success "Docker Compose 已安装: $COMPOSE_VERSION"
        return 0
    fi

    print_info "Docker Compose 未安装，正在安装..."

    # Docker Compose V2 已经作为 Docker 插件安装
    # 如果上面的检查失败，说明可能是 Docker 版本太旧
    print_error "Docker Compose 不可用，请更新 Docker 到最新版本"
    print_info "或手动安装: apt install docker-compose-plugin"
    exit 1
}

# API Key 配置向导
configure_api_key() {
    print_step "配置 SiliconFlow API Key"

    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                 API Key 获取指南                           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${YELLOW}为什么选择 SiliconFlow？${NC}"
    echo "  ✓ 主力模型 Qwen2.5-7B-Instruct 完全免费"
    echo "  ✓ 验证码模型价格极低（¥0.5/百万 tokens）"
    echo "  ✓ 国内访问速度快，无需科学上网"
    echo "  ✓ ¥16 代金券 ≈ 1500+ 次领取任务"
    echo ""

    # 询问是否已有 API Key
    read -p "是否已准备好 SiliconFlow API Key? [y/N]: " has_key
    has_key=${has_key:-N}

    if [[ ! "$has_key" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${GREEN}请按以下步骤获取 API Key：${NC}"
        echo ""
        echo -e "${CYAN}步骤 1: 访问邀请链接${NC}"
        echo -e "  ${YELLOW}https://cloud.siliconflow.cn/i/OVI2n57p${NC}"
        echo "  （使用邀请链接，双方各得 ¥16 代金券）"
        echo ""
        echo -e "${CYAN}步骤 2: 注册账号${NC}"
        echo "  - 点击右上角「注册」"
        echo "  - 支持手机号/微信/邮箱注册"
        echo ""
        echo -e "${CYAN}步骤 3: 实名认证${NC}"
        echo "  - 登录后进入「账户设置」→「实名认证」"
        echo "  - 需要上传身份证正反面照片"
        echo "  - 认证通过后才能创建 API Key"
        echo ""
        echo -e "${CYAN}步骤 4: 创建 API Key${NC}"
        echo "  - 进入「API 密钥」页面"
        echo "  - 点击「创建新密钥」"
        echo "  - 复制生成的密钥（以 sk- 开头）"
        echo ""
        echo -e "${RED}⚠️ 重要提示: API Key 只显示一次，请立即保存！${NC}"
        echo ""

        read -p "完成上述步骤后按回车继续..."
    fi

    # 输入 API Key
    while true; do
        echo ""
        read -p "请输入你的 SiliconFlow API Key (sk-xxx): " api_key

        if [[ -z "$api_key" ]]; then
            print_error "API Key 不能为空"
            continue
        fi

        if [[ ! "$api_key" =~ ^sk- ]]; then
            print_warning "API Key 通常以 sk- 开头，请确认输入正确"
        fi

        # 确认 API Key
        echo ""
        echo -e "你输入的 API Key: ${YELLOW}${api_key}${NC}"
        read -p "确认无误? [Y/n]: " confirm_key
        confirm_key=${confirm_key:-Y}

        if [[ "$confirm_key" =~ ^[Yy]$ ]]; then
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
        read -p "是否删除并重新克隆? [y/N]: " reclone
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
        apt-get update && apt-get install -y git
    fi

    print_info "克隆项目..."
    git clone -b main https://github.com/10000ge10000/epic-kiosk.git "$PROJECT_DIR"

    print_success "项目克隆完成"
}

# 配置并启动服务
deploy_service() {
    print_step "配置并启动服务"

    cd "$PROJECT_DIR"

    # 替换 API Key
    print_info "配置 API Key..."
    sed -i "s|SILICONFLOW_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|SILICONFLOW_API_KEY=$SILICONFLOW_API_KEY|g" docker-compose.yml

    # 拉取镜像（ghcr.io 公开镜像无需登录）
    print_info "拉取 Docker 镜像（首次需要几分钟）..."
    docker compose pull

    # 启动服务
    print_info "启动服务..."
    docker compose up -d

    # 等待服务启动
    print_info "等待服务启动..."
    sleep 5

    # 检查服务状态
    if docker compose ps | grep -q "Up"; then
        print_success "服务启动成功!"
    else
        print_error "服务启动失败，请检查日志"
        docker compose logs
        exit 1
    fi
}

# 显示部署完成信息
show_complete() {
    # 获取服务器 IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                 部署完成！                                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}访问地址:${NC}"
    echo -e "  本地: ${YELLOW}http://localhost:18000${NC}"
    if [ -n "$SERVER_IP" ]; then
        echo -e "  局域网: ${YELLOW}http://$SERVER_IP:18000${NC}"
    fi
    echo ""
    echo -e "${CYAN}常用命令:${NC}"
    echo "  查看状态: docker compose ps"
    echo "  查看日志: docker logs epic-worker -f"
    echo "  停止服务: docker compose down"
    echo "  重启服务: docker compose restart"
    echo ""
    echo -e "${CYAN}相关链接:${NC}"
    echo "  公益站点: https://epic.910501.xyz/"
    echo "  GitHub: https://github.com/10000ge10000/epic-kiosk"
    echo "  B 站频道: https://space.bilibili.com/59438380"
    echo ""
    echo -e "${GREEN}感谢使用 Epic Kiosk!${NC}"
}

# 主函数
main() {
    print_header

    # 系统检查
    print_step "系统环境检查"
    check_arch
    check_os

    # 安装依赖
    install_docker
    install_docker_compose

    # 配置
    configure_api_key
    clone_project

    # 部署
    deploy_service

    # 完成
    show_complete
}

# 运行主函数
main "$@"
