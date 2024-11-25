#!/bin/bash

set -e # 如果任何命令返回非零值，则退出脚本

# PSQL_PATH=$(which psql)
# echo $PSQL_PATH

# 检查 PostgreSQL 是否安装
if command -v psql >/dev/null 2>&1; then
  # 检查 PostgreSQL 的版本
  PG_VERSION=$(psql --version)
  echo "PostgreSQL version: $PG_VERSION"
else
  echo "❌ PostgreSQL is not installed."
  exit 1
fi

# 定义 .env 文件路径
ENV_FILE="./.env"

# 检查 .env 文件是否存在
if [[ ! -f $ENV_FILE ]]; then
  echo "❌ .env file not found!"
  exit 1
fi

# 提取 DATABASE_URL
DATABASE_URL=$(grep 'DATABASE_URL' $ENV_FILE | sed 's/DATABASE_URL=//')

# 确保 DATABASE_URL 不为空
if [[ -z "$DATABASE_URL" ]]; then
  echo "❌ DATABASE_URL is not set in .env file!"
  exit 1
fi

# 使用参数扩展和sed/awk提取组件
DB_USER=$(echo "$DATABASE_URL" | sed -r 's~.*://([^:]+):.*~\1~')
DB_PASSWORD=$(echo "$DATABASE_URL" | sed -r 's~.*://[^:]+:([^@]+)@.*~\1~')
DB_HOST=$(echo "$DATABASE_URL" | sed -r 's~.*@([^:]+):.*~\1~')
DB_PORT=$(echo "$DATABASE_URL" | sed -r 's~.*:([0-9]+)/.*~\1~')
DB_NAME=$(echo "$DATABASE_URL" | sed -r 's~.*/([^/]+)$~\1~')

# 确保所有组件已成功提取
if [[ -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$DB_HOST" || -z "$DB_PORT" || -z "$DB_NAME" ]]; then
  echo "❌ Failed to parse DATABASE_URL!"
  exit 1
fi

# Backup directory
BACKUP_DIR="/www"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"

# Export PGPASSWORD to avoid prompting
export PGPASSWORD=${DB_PASSWORD}

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Perform backup using pg_dump
pg_dump -U "${DB_USER}" -h "${DB_HOST}" -p "${DB_PORT}" -F p -b -v -f "${BACKUP_FILE}" "${DB_NAME}"

# Check if the command succeeded
if [ $? -eq 0 ]; then
  echo "Backup successful! File saved to ${BACKUP_FILE}"
else
  echo "Backup failed!"
fi

# 清除 PGPASSWORD 环境变量
unset PGPASSWORD

# sudo -E -u postgres $PSQL_PATH -c "\q"
