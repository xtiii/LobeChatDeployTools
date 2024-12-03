#!/bin/bash

clear

set -e # 如果任何命令返回非零值，则退出脚本

# PostgreSQL 版本
pgsql_version=16.1

cn_down_url="https://mirrors.aliyun.com/postgresql/source/v${pgsql_version}/postgresql-${pgsql_version}.tar.gz"
en_down_url="https://ftp.postgresql.org/pub/source/v${pgsql_version}/postgresql-${pgsql_version}.tar.gz"

# 安装目录
install_dir="/www/service/pgsql"

# 选择默认源
location="Default"

# 获取脚本所在的完整原始路径
SCRIPT_PATH=$(realpath "$0")
# 获取脚本所在的原始目录
# SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
# 获取脚本的文件名
SCRIPT_NAME=$(basename "$SCRIPT_PATH")

# 通过 Ping 检测下载链接
urlSelect() {
  ALIYUN="mirrors.aliyun.com"
  POSTGRE="ftp.postgresql.org"

  # Ping 的延迟限制
  TIMEOUT=0.5

  # 异步执行Ping测试第一个URL并获取延迟
  (ping -W $TIMEOUT -c 3 $ALIYUN | tail -1 | awk -F '/' '{print $5}' >latency1.txt) &

  # 异步执行Ping测试第二个URL并获取延迟
  (ping -W $TIMEOUT -c 3 $POSTGRE | tail -1 | awk -F '/' '{print $5}' >latency2.txt) &

  echo -e "正在为您选择源..."
  # 等待所有异步进程完成
  wait

  # 读取延迟值
  ALIYUN_LATENCY=$(cat latency1.txt)
  POSTGRE_LATENCY=$(cat latency2.txt)

  # 清理临时文件
  rm -rf latency1.txt latency2.txt

  # 比较两个URL的平均延迟
  if (($(echo "$ALIYUN_LATENCY < $POSTGRE_LATENCY" | bc -l))); then
    location="Aliyun"
    sed -i 's/^LOCATION="Default"$/LOCATION="Aliyun"/' $SCRIPT_NAME
    down_url=$cn_down_url
  else
    location="Postgre"
    sed -i 's/^LOCATION="Default"$/LOCATION="Postgre"/' $SCRIPT_NAME
    down_url=$en_down_url
  fi
}

# 自动选择国内外源
if [[ $location == "Aliyun" ]]; then
  down_url=$cn_down_url
elif [[ $location == "Postgre" ]]; then
  down_url=$en_down_url
else
  urlSelect
fi

# 安装 PostgreSQL
db_install() {
  bash ./pgsql_install.sh $down_url $install_dir $pgsql_version
}

# 检查 PostgreSQL
if [ "$(command -v psql)" ]; then
  DB_VERSION=$(psql --version)
else
  # 读取用户输入
  read -rp "PostgreSQL 未安装，是否安装(y/n)：" choice
  case $choice in
  Y | y)
    echo "正在为您安装 PostgreSQL..."
    db_install
    ;;
  *)
    echo "❌ 未安装，请先安装！"
    exit 1
    ;;
  esac
fi

init() {
  echo -e "当前 PostgreSQL 版本：$DB_VERSION"
  echo -e " LobeChat 所在目录：$CURRENT_DIR"
  echo -e " LobeChatDeployTools - PostgreSQL_Tools "
  echo -e "如果你是第一次构建 \033[32mLobeChat\033[0m 请先 安装依赖 再 构建程序"
  echo -e " 1 -> 安装 PostgreSQL"
  echo -e " 2 -> 构建程序"
  echo -e " 3 -> 运行程序"
  echo -e " 4 -> 更新程序"
  echo -e " 5 -> 数据库迁移"
  echo -e " 6 -> 数据库备份"
  echo -e " 7 -> 更新此脚本"
  echo -e " 8 -> 删除此脚本"
  echo -e " 9 -> \033[32mPostgreSQL\033[0m"
  echo -e " 0 -> 退出程序"
  echo -e "Ps: 在任意地方输入 \033[32mlcdt\033[0m 命令即可运行此脚本~"

  # 读取用户输入
  read -rp "请输入待执行的编号：" choice
}

init
