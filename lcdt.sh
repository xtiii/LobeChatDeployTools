#!/bin/bash

clear

set -e # 如果任何命令返回非零值，则退出脚本

# 检查 node.js
if [ "$(command -v node)" ]; then
  NODE_VERSION=$(node -v)
else
  echo "❌ Node.js 未安装！请自行配置"
  exit 1
fi

# 检查 npm
if [ "$(command -v npm)" ]; then
  NPM_VERSION=$(npm -v)
else
  echo "❌ npm 未安装！请自行配置"
  exit 1
fi

# 检查 bun
if [ "$(command -v bun)" ]; then
  BUN_VERSION=$(bun -v)
else
  echo "❌ bun 未安装！请执行：npm install -g bun"
  exit 1
fi

# 检查 git
if ! [ "$(command -v git)" ]; then
  echo "❌ git 未安装！正在为您安装..."
  sudo apt-get install git -y
fi

# 获取脚本所在的完整原始路径
SCRIPT_PATH=$(realpath "$0")
# 获取脚本所在的原始目录
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
# 获取脚本的文件名
SCRIPT_NAME=$(basename "$SCRIPT_PATH")

# 定义仓库地址
STOREHOSE_URL="https://raw.githubusercontent.com/xtiii/LobeChatDeployTools/main"

# 定义 src 文件夹名
SRC_DIR="$SCRIPT_DIR/src"
# 定义 package.json 文件名
PACKAGE_FILE="$SCRIPT_DIR/package.json"
# 定义部署工具的存放目录名
DEPLOYTOOLS_DIR="LobeChatDeployTools"

# 安装依赖
install() {
  echo "开始安装依赖"
  NODE_FILE="./node_modules"
  if [ -d "$NODE_FILE" ]; then
    rm -rf "$NODE_FILE"
  fi
  bun install || true
}

# 构建程序
build() {
  echo "开始构建程序"
  echo "注意：如果最后出现 db:migrate 相关错误，无需理会，执行本程序提供的 数据库迁移 即可！"
  NEXT_FILE="./.next"
  if [ -d "$NEXT_FILE" ]; then
    rm -rf "$NEXT_FILE"
  fi
  # 如构建时被 Killed 请加大 4096 的值(最好为 1024 的倍数)
  NODE_OPTIONS=--max-old-space-size=4096 bun run build || true
  rm -rf ./.next/cache
  init
}

# 运行程序
run() {
  echo "开始运行程序"
  # 默认端口
  DEFAULT_PORN=3210
  read -pr "请输入指定端口号(1 - 65535)，默认：${DEFAULT_PORN}: " PORN
  # 如果用户未输入内容，使用默认端口
  if [ -z "$port" ]; then
    PORN=$DEFAULT_PORN
  fi
  bun run start -H 0.0.0.0 -p "$PORN"
}

# 更新程序
update() {
  echo "开始更新程序，这可能需要一些时间！"
  OUTPUT=$(git pull)
  if [[ $OUTPUT == *"up to date"* || $OUTPUT == *"最新"* ]]; then
    echo "🎉 已经是最新版本！"
  else
    echo "检测到更新，开始更新并自动部署！"
    install
    build
  fi
}

# 数据库操作
goto_db() {
  SCRIPT_URL="$STOREHOSE_URL/$DEPLOYTOOLS_DIR/$DB_SCRIPT_NAME"
  if [ ! -d ./$DEPLOYTOOLS_DIR ]; then
    mkdir -p ./$DEPLOYTOOLS_DIR
  fi
  if [ ! -f ./$DEPLOYTOOLS_DIR/$DB_SCRIPT_NAME ]; then
    wget -q -O "./$DEPLOYTOOLS_DIR/$DB_SCRIPT_NAME" "$SCRIPT_URL"
    chmod +x "./$DEPLOYTOOLS_DIR/$DB_SCRIPT_NAME"
  fi
  ./$DEPLOYTOOLS_DIR/$DB_SCRIPT_NAME || true
}

# 更新脚本
update_script() {
  SCRIPT_URL="$STOREHOSE_URL/LobeChatDeployTools.sh"
  wget -O "$SCRIPT_NAME" "$SCRIPT_URL"
  sudo ln -sf "$SCRIPT_DIR/$SCRIPT_NAME" /usr/local/bin/lcdt
}

# 删除脚本
delete_script() {
  # 读取用户输入
  read -pr "是否彻底删除此脚本(y/n): " choice
  case $choice in
  Y | y)
    clear
    rm -rf /usr/local/bin/lcdt
    rm -rf ./"$DEPLOYTOOLS_DIR"
    rm -rf ./"$SCRIPT_NAME"
    echo "期待与您再次相遇，再见~"
    exit 0
    ;;
  *)
    init
    ;;
  esac
}

# 不在 LobeChat 根目录
no_lobechat() {
  echo "❌ 当前不在 LobeChat 的根目录"
  # 读取用户输入
  read -pr "是否从 Git 克隆 LobeChat (y/n): " choice
  case $choice in
  Y | y)
    clear
    # 读取用户输入
    DEFAULT_CLONE_PATH="/www/wwwroot"
    read -pr "您要将 LobeChat 克隆到哪个目录，默认：$DEFAULT_CLONE_PATH" CLONE_PATH
    # 如果没有输入，使用默认路径
    if [ -z "$CLONE_PATH" ]; then
      CLONE_PATH="$DEFAULT_CLONE_PATH"
    fi
    # 输出确认
    echo -e "您的设置路径是：$CLONE_PATH"
    echo -e "正在从 xtiii/LobeChat 克隆..."
    echo -e "该仓库每三小时与官方仓库同步一次，请放心使用。"
    if [ ! -d "$CLONE_PATH" ]; then
      mkdir -p "$CLONE_PATH"
      cd "$CLONE_PATH"
      git clone https://github.com/xtiii/LobeChat.git || true
    fi
    mv -f "$SCRIPT_PATH" /www/wwwroot/LobeChat/"$SCRIPT_NAME"
    cd "$CLONE_PATH"/LobeChat && ./"$SCRIPT_NAME"
    exit 0
    ;;
  *)
    clear
    echo "❌ 请确保当前目录为 LobeChat 的根目录！"
    exit 0
    ;;
  esac
}

# 检查符号链接是否存在
link() {
  if [ ! -L /usr/local/bin/lcdt ]; then
    # 如果符号链接不存在，创建它
    sudo ln -s "$SCRIPT_PATH" /usr/local/bin/lcdt
  fi
}

# 入口
init() {
  link
  while true; do
    # 获取当前工作目录
    CURRENT_DIR=$(pwd)
    echo -e " LobeChat 所在目录：$CURRENT_DIR"
    echo -e " LobeChatDeployTools 所在目录：$SCRIPT_PATH"
    echo -e "如果你是第一次构建 \033[32mLobeChat\033[0m 请先 安装依赖 再 构建程序"
    echo -e " 1 -> 安装依赖"
    echo -e " 2 -> 构建程序"
    echo -e " 3 -> 运行程序"
    echo -e " 4 -> 更新程序"
    echo -e " 5 -> 数据库迁移"
    echo -e " 6 -> 数据库备份"
    echo -e " 7 -> 更新此脚本"
    echo -e " 8 -> 删除此脚本"
    echo -e " 0 -> 退出程序"
    echo -e "Ps: 在任意地方输入 \033[32mlcdt\033[0m 命令即可运行此脚本~"

    # 读取用户输入
    read -pr "请输入待执行的编号: " choice

    case $choice in
    1)
      clear
      install
      ;;
    2)
      clear
      build
      ;;
    3)
      clear
      run
      ;;
    4)
      clear
      update
      ;;
    5)
      clear
      echo "开始数据库迁移"
      DB_SCRIPT_NAME="MigrationTools.sh"
      goto_db
      ;;
    6)
      clear
      echo "开始数据库备份"
      DB_SCRIPT_NAME="BackupTools.sh"
      goto_db
      ;;
    7)
      clear
      echo "开始更新脚本"
      update_script
      ;;
    8)
      clear
      echo "开始删除脚本"
      delete_script
      ;;
    *)
      exit 0
      ;;
    esac
  done
}

# 检查当前目录
if [ ! -d "$SRC_DIR" ] || [ ! -f "$PACKAGE_FILE" ]; then
  no_lobechat
fi

# 开始
clear
echo -e "\033[47;34m建议的内存大小：8G\033[0m"
echo -e "当前环境：\033[32mnode:$NODE_VERSION\033[0m  \033[34mnpm:v$NPM_VERSION\033[0m  \033[36mbun:v$BUN_VERSION\033[0m"
init
