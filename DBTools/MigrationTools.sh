#!/bin/bash

set -e  # 如果任何命令返回非零值，则退出脚本

# 定义 .env 文件路径
ENV_FILE="../.env"

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
DB_USER=$(echo $DATABASE_URL | sed -r 's~.*://([^:]+):.*~\1~')
DB_PASSWORD=$(echo $DATABASE_URL | sed -r 's~.*://[^:]+:([^@]+)@.*~\1~')
DB_HOST=$(echo $DATABASE_URL | sed -r 's~.*@([^:]+):.*~\1~')
DB_PORT=$(echo $DATABASE_URL | sed -r 's~.*:([0-9]+)/.*~\1~')
DB_NAME=$(echo $DATABASE_URL | sed -r 's~.*/([^/]+)$~\1~')

# 确保所有组件已成功提取
if [[ -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$DB_HOST" || -z "$DB_PORT" || -z "$DB_NAME" ]]; then
  echo "❌ Failed to parse DATABASE_URL!"
  exit 1
fi

# 为 PostgreSQL 设置 PGPASSWORD 环境变量以自动传递密码
export PGPASSWORD=$DB_PASSWORD

# 连接 PostgreSQL 并安装 PGVECTOR 扩展
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;"; then
  echo "❌ Failed to create or verify PGVECTOR extension."
  exit 1
fi

# 定义存储迁移 SQL 文件的文件夹
MIGRATIONS_FOLDER="./src/database/server/migrations"

# 检查迁移文件夹是否存在
if [[ ! -d $MIGRATIONS_FOLDER ]]; then
  echo "❌ Migrations folder $MIGRATIONS_FOLDER not found!"
  exit 1
fi

# 遍历并执行文件夹下的所有 SQL 文件
for file in $MIGRATIONS_FOLDER/*.sql; do
  if [[ -f $file ]]; then
    echo "Running migration for file: $file"
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file"; then
      echo "❌ Migration failed for file: $file. Rolling back!"
      exit 1
    fi
  else
    echo "❌ No SQL files found in $MIGRATIONS_FOLDER!"
    exit 1
  fi
done

clear

echo "✅ All migrations have been applied successfully!"

# 清理环境变量
unset PGPASSWORD
