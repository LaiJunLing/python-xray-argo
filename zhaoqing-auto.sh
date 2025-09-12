#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif command -v python3 &> /dev/null; then
        python3 -c "import uuid; print(str(uuid.uuid4()))"
    else
        hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/urandom | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-\9\10-\11\12\13\14\15\16/' | tr '[:upper:]' '[:lower:]'
    fi
}

clear

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Python Xray Argo 一键部署脚本    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${BLUE}基于项目: ${YELLOW}https://github.com/laijunling/python-xray-argo${NC}"
echo -e "${GREEN}支持自动UUID生成、后台运行、节点信息输出${NC}"
echo
echo -e "${BLUE}检查并安装依赖...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}正在安装 Python3...${NC}"
    sudo apt-get update && sudo apt-get install -y python3 python3-pip
fi

if ! python3 -c "import requests" &> /dev/null; then
    echo -e "${YELLOW}正在安装 Python 依赖...${NC}"
    pip3 install requests
fi

PROJECT_DIR="python-xray-argo"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${BLUE}下载完整仓库...${NC}"
    if command -v git &> /dev/null; then
        git clone https://github.com/laijunling/python-xray-argo.git
    else
        echo -e "${YELLOW}Git未安装，使用wget下载...${NC}"
        wget -q https://github.com/laijunling/python-xray-argo/archive/refs/heads/main.zip -O python-xray-argo.zip
        if command -v unzip &> /dev/null; then
            unzip -q python-xray-argo.zip
            mv python-xray-argo-main python-xray-argo
            rm python-xray-argo.zip
        else
            echo -e "${YELLOW}正在安装 unzip...${NC}"
            sudo apt-get install -y unzip
            unzip -q python-xray-argo.zip
            mv python-xray-argo-main python-xray-argo
            rm python-xray-argo.zip
        fi
    fi
    
    if [ $? -ne 0 ] || [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}下载失败，请检查网络连接${NC}"
        exit 1
    fi
fi

cd "$PROJECT_DIR"

echo -e "${GREEN}依赖安装完成！${NC}"
echo

if [ ! -f "app.py" ]; then
    echo -e "${RED}未找到app.py文件！${NC}"
    exit 1
fi

cp app.py app.py.backup
echo -e "${YELLOW}已备份原始文件为 app.py.backup${NC}"

echo -e "${BLUE}=== 极速模式 ===${NC}"
echo

sed -i "s/UUID = os.environ.get('UUID', '[^']*')/UUID = os.environ.get('UUID', '226279dd-28b2-4b61-96be-a2a0b1afd522')/" app.py
echo -e "${GREEN}UUID 已设置为: 226279dd-28b2-4b61-96be-a2a0b1afd522{NC}"

sed -i "s/NAME = os.environ.get('NAME', '[^']*')/NAME = os.environ.get('NAME', '肇庆节点')/" app.py
echo -e "${GREEN}节点名称已设置为: 肇庆节点{NC}"

sed -i "s/CFIP = os.environ.get('CFIP', '[^']*')/CFIP = os.environ.get('CFIP', 'myanmar.visa.com')/" app.py
echo -e "${GREEN}优选IP已自动设置为: myanmar.visa.com${NC}"

echo
echo -e "${GREEN}极速配置完成！正在启动服务...${NC}"
echo


echo -e "${YELLOW}=== 当前配置摘要 ===${NC}"
echo -e "UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)"
echo -e "节点名称: $(grep "NAME = " app.py | head -1 | cut -d"'" -f4)"
echo -e "服务端口: $(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)"
echo -e "优选IP: $(grep "CFIP = " app.py | cut -d"'" -f4)"
echo -e "优选端口: $(grep "CFPORT = " app.py | cut -d"'" -f4)"
echo -e "订阅路径: $(grep "SUB_PATH = " app.py | cut -d"'" -f4)"
echo -e "${YELLOW}========================${NC}"
echo

echo -e "${BLUE}正在启动服务...${NC}"
echo -e "${YELLOW}当前工作目录：$(pwd)${NC}"
echo

nohup python3 app.py > app.log 2>&1 &
APP_PID=$!

echo -e "${GREEN}服务已在后台启动，PID: $APP_PID${NC}"
echo -e "${YELLOW}日志文件: $(pwd)/app.log${NC}"

echo -e "${BLUE}等待服务启动...${NC}"
sleep 10

if ps -p $APP_PID > /dev/null; then
    echo -e "${GREEN}服务运行正常${NC}"
else
    echo -e "${RED}服务启动失败，请检查日志${NC}"
    echo -e "${YELLOW}查看日志: tail -f app.log${NC}"
    exit 1
fi

SERVICE_PORT=$(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)
CURRENT_UUID=$(grep "UUID = " app.py | head -1 | cut -d"'" -f2)
SUB_PATH_VALUE=$(grep "SUB_PATH = " app.py | cut -d"'" -f4)

echo -e "${BLUE}等待节点信息生成...${NC}"
sleep 30

NODE_INFO=""
if [ -f ".cache/sub.txt" ]; then
    NODE_INFO=$(cat .cache/sub.txt)
elif [ -f "sub.txt" ]; then
    NODE_INFO=$(cat sub.txt)
fi

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}           部署完成！                   ${NC}"
echo -e "${GREEN}========================================${NC}"
echo

echo -e "${YELLOW}=== 服务信息 ===${NC}"
echo -e "服务状态: ${GREEN}运行中${NC}"
echo -e "进程PID: ${BLUE}$APP_PID${NC}"
echo -e "服务端口: ${BLUE}$SERVICE_PORT${NC}"
echo -e "UUID: ${BLUE}$CURRENT_UUID${NC}"
echo -e "订阅路径: ${BLUE}/$SUB_PATH_VALUE${NC}"
echo

echo -e "${YELLOW}=== 访问地址 ===${NC}"
if command -v curl &> /dev/null; then
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "获取失败")
    if [ "$PUBLIC_IP" != "获取失败" ]; then
        echo -e "订阅地址: ${GREEN}http://$PUBLIC_IP:$SERVICE_PORT/$SUB_PATH_VALUE${NC}"
        echo -e "管理面板: ${GREEN}http://$PUBLIC_IP:$SERVICE_PORT${NC}"
    fi
fi
echo -e "本地订阅: ${GREEN}http://localhost:$SERVICE_PORT/$SUB_PATH_VALUE${NC}"
echo -e "本地面板: ${GREEN}http://localhost:$SERVICE_PORT${NC}"
echo

if [ -n "$NODE_INFO" ]; then
    echo -e "${YELLOW}=== 节点信息 ===${NC}"
    DECODED_NODES=$(echo "$NODE_INFO" | base64 -d 2>/dev/null || echo "$NODE_INFO")
    echo -e "${GREEN}原始节点配置:${NC}"
    echo "$DECODED_NODES"
    echo
    echo -e "${GREEN}订阅链接 (Base64编码):${NC}"
    echo "$NODE_INFO"
    echo
else
    echo -e "${YELLOW}=== 节点信息 ===${NC}"
    echo -e "${RED}节点信息还未生成，请稍等几分钟后查看日志或手动访问订阅地址${NC}"
    echo
fi

echo -e "${YELLOW}=== 管理命令 ===${NC}"
echo -e "查看日志: ${BLUE}tail -f $(pwd)/app.log${NC}"
echo -e "停止服务: ${BLUE}kill $APP_PID${NC}"
echo -e "重启服务: ${BLUE}kill $APP_PID && nohup python3 app.py > app.log 2>&1 &${NC}"
echo -e "查看进程: ${BLUE}ps aux | grep python3${NC}"
echo

echo -e "${YELLOW}=== 重要提示 ===${NC}"
echo -e "${GREEN}服务正在后台运行，请等待Argo隧道建立完成${NC}"
echo -e "${GREEN}如果使用临时隧道，域名会在几分钟后出现在日志中${NC}"
echo -e "${GREEN}建议10-15分钟后再次查看订阅地址获取最新节点信息${NC}"
echo -e "${GREEN}可以通过日志查看详细的启动过程和隧道信息${NC}"
echo

echo -e "${GREEN}部署完成！感谢使用！${NC}"
