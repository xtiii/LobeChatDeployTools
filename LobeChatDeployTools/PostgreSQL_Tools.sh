#!/bin/bash

clear

set -e # 如果任何命令返回非零值，则退出脚本

# 安装目录
INSTALL_DIR="/www/service/pgsql"
# PostgreSQL 版本
PGSQL_VERSION=16.1
CN_DOWN_URL="https://mirrors.aliyun.com/postgresql/source/v${PGSQL_VERSION}/postgresql-${PGSQL_VERSION}.tar.gz"
EN_DOWN_URL="https://ftp.postgresql.org/pub/source/v${PGSQL_VERSION}/postgresql-${PGSQL_VERSION}.tar.gz"

# 选择默认源
LOCATION="Default"

# 获取脚本所在的完整原始路径
SCRIPT_PATH=$(realpath "$0")
# 获取脚本所在的原始目录
# SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
# 获取脚本的文件名
SCRIPT_NAME=$(basename "$SCRIPT_PATH")

# 通过 Ping 检测下载链接
url_select() {
  aliyun="mirrors.aliyun.com"
  postgresql="ftp.postgresql.org"

  # Ping 的延迟限制
  timeout=0.5

  # 异步执行Ping测试第一个URL并获取延迟
  (ping -W $timeout -c 3 $aliyun | tail -1 | awk -F '/' '{print $5}' >latency1.txt) &

  # 异步执行Ping测试第二个URL并获取延迟
  (ping -W $timeout -c 3 $postgresql | tail -1 | awk -F '/' '{print $5}' >latency2.txt) &

  echo -e "正在为您选择源..."
  # 等待所有异步进程完成
  wait

  # 读取延迟值
  aliyun_latency=$(cat latency1.txt)
  postgresql_latency=$(cat latency2.txt)

  # 清理临时文件
  rm -rf latency1.txt latency2.txt

  # 比较两个URL的平均延迟
  if (($(echo "$aliyun_latency < $postgresql_latency" | bc -l))); then
    LOCATION="Aliyun"
    sed -i 's/^LOCATION="Default"$/LOCATION="Aliyun"/' $SCRIPT_NAME
    DOWN_URL=$CN_DOWN_URL
  else
    LOCATION="Postgre"
    sed -i 's/^LOCATION="Default"$/LOCATION="PostgreSQL"/' $SCRIPT_NAME
    DOWN_URL=$EN_DOWN_URL
  fi
}

# 自动选择国内外源
if [[ $LOCATION == "Aliyun" ]]; then
  DOWN_URL=$CN_DOWN_URL
elif [[ $LOCATION == "PostgreSQL" ]]; then
  DOWN_URL=$EN_DOWN_URL
else
  url_select
fi

# 安装 PostgreSQL
db_install() {
  sudo bash ./pgsql_install.sh $DOWN_URL $INSTALL_DIR $PGSQL_VERSION
}

# 检查 PostgreSQL
if [ -f ${INSTALL_DIR}/bin/psql ]; then
  DB_VERSION=$(su - postgres -c 'psql --version' | awk '{print $3}')
else
  # 读取用户输入
  read -rp "PostgreSQL 未安装，是否安装(y/n)：" choice
  case $choice in
  Y | y)
    echo "正在为您安装 PostgreSQL..."
    DB_VERSION=$PGSQL_VERSION
    db_install
    ;;
  *)
    echo "❌ 未安装，请先安装！"
    exit 1
    ;;
  esac
fi

init() {
  echo -e "当前 PostgreSQL 版本：${DB_VERSION}"
  echo -e " LobeChatDeployTools - PostgreSQL_Tools "
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
