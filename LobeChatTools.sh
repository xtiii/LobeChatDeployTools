#!/bin/bash

clear

set -e  # 如果任何命令返回非零值，则退出脚本

# 检查 node.js
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node -v)
else
    echo "❌ Node.js 未安装！请自行配置"
	exit 1
fi

# 检查 npm
if command -v npm >/dev/null 2>&1; then
    NPM_VERSION=$(npm -v)
else
    echo "❌ npm 未安装！请自行配置"
	exit 1
fi

# 检查 bun
if command -v bun >/dev/null 2>&1; then
    BUN_VERSION=$(bun -v)
else
    echo "❌ bun 未安装！请执行：npm install -g bun"
	exit 1
fi

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
	default_port=3210
	read -p "请输入指定端口号(1 - 65535)，默认：${default_port}: " port
	# 如果用户未输入内容，使用默认端口
	if [ -z "$port" ]; then
		port=$default_port
	fi
	bun run start -H 0.0.0.0 -p $port
}

# 更新程序
update() {
	echo "开始更新程序，这可能需要一些时间！"
	git pull origin main
	install
	build
}

# 数据库迁移
migration() {
	SCRIPT_URL="http://example.com/path/to/your/script.sh"
	SCRIPT_NAME="MigrationTools.sh"
	# 如果目标目录不存在，则创建
	if [ ! -d $DEPLOYTOOLS_DIR ]; then
		mkdir -p $DEPLOYTOOLS_DIR
	fi
	if [ ! -f $DEPLOYTOOLS_DIR/$SCRIPT_NAME ]; then
		wget -q -O "$DEPLOYTOOLS_DIR/$SCRIPT_NAME" "$SCRIPT_URL"
		chmod +x "$DEPLOYTOOLS_DIR/$SCRIPT_NAME"
	fi
	$DEPLOYTOOLS_DIR/$SCRIPT_NAME || true
}

# 数据库备份
backup() {
	SCRIPT_URL="http://example.com/path/to/your/script.sh"
	SCRIPT_NAME="BackupTools.sh"
	if [ ! -d $DEPLOYTOOLS_DIR ]; then
		mkdir -p $DEPLOYTOOLS_DIR
	fi
	if [ ! -f $DEPLOYTOOLS_DIR/$SCRIPT_NAME ]; then
		wget -q -O "$DEPLOYTOOLS_DIR/$SCRIPT_NAME" "$SCRIPT_URL"
		chmod +x "$DEPLOYTOOLS_DIR/$SCRIPT_NAME"
	fi
	$DEPLOYTOOLS_DIR/$SCRIPT_NAME || true
}

# 获取当前脚本所在目录
SCRIPT_DIR=$(dirname "$0")
# 将目录路径转换为绝对路径
SCRIPT_DIR=$(cd "$SCRIPT_DIR" && pwd)

# 定义部署工具的存放目录
DEPLOYTOOLS_DIR="./DeployTools"

# 定义 src 文件夹路径
SRC_DIR="./src"
# 定义 package.json 文件路径
PACKAGE_FILE="./package.json"

# 初始化目标目录为当前目录
TARGET_DIR=""

# 检查当前目录
if [ -d $SRC_DIR ] && [ -f $PACKAGE_FILE ]; then
    TARGET_DIR="./"
# 检查上级目录
elif [ -d ../$SRC_DIR ] && [ -f ../$PACKAGE_FILE ]; then
    TARGET_DIR="../"
else
    echo "❌ 请确认当前目录或者上级目录为 LobeChat 的根目录"
    exit 1
fi

# 切换到目标目录
cd "$TARGET_DIR"

# 入口
init() {
	while true; do
		echo -e "当前脚本执行目录：$SCRIPT_DIR"
		echo -e "如果你是第一次构建 \033[32mLobeChat\033[0m 请先 安装依赖 再 构建程序"
		echo -e " 1 -> 安装依赖"
		echo -e " 2 -> 构建程序"
		echo -e " 3 -> 运行程序"
		echo -e " 4 -> 更新程序"
		echo -e " 5 -> 数据库迁移"
		echo -e " 6 -> 数据库备份"
		echo -e " 0 -> 退出程序"

		# 读取用户输入
		read -p "请输入待执行的编号: " choice

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
				migration
				;;
			6)
				clear
				echo "开始数据库备份"
				backup
				;;
			*)
				exit 0
				;;
		esac
	done
}



# 开始
clear
echo -e "\033[47;34m建议的服务器内存大小：8G\033[0m"
echo -e "当前环境：\033[32mnode:$NODE_VERSION\033[0m  \033[34mnpm:v$NPM_VERSION\033[0m  \033[36mbun:v$BUN_VERSION\033[0m"
init


