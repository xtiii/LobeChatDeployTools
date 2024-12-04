#!/bin/bash

set -e # 开启错误中止模式

trap 'echo "Error occurred at line $LINENO: $BASH_COMMAND"' ERR

#pgsql安装脚本
DOWN_URL=$1
INSTALL_DIR=$2
PGSQL_VERSION=$3

USERNAME="postgres"
PASSWORD="pg123456"

getCpuStat() {
  time1=$(cat /proc/stat | grep 'cpu ')
  sleep 1
  time2=$(cat /proc/stat | grep 'cpu ')
  cpuTime1=$(echo ${time1} | awk '{print $2+$3+$4+$5+$6+$7+$8}')
  cpuTime2=$(echo ${time2} | awk '{print $2+$3+$4+$5+$6+$7+$8}')
  runTime=$((${cpuTime2} - ${cpuTime1}))
  idelTime1=$(echo ${time1} | awk '{print $5}')
  idelTime2=$(echo ${time2} | awk '{print $5}')
  idelTime=$((${idelTime2} - ${idelTime1}))
  useTime=$(((${runTime} - ${idelTime}) * 3))
  [ ${useTime} -gt ${runTime} ] && cpuBusy="true"
  if [ "${cpuBusy}" == "true" ]; then
    cpuCore=$((${cpuInfo} / 2))
  else
    cpuCore=$((${cpuInfo} - 1))
  fi
}

cpuInfo=$(getconf _NPROCESSORS_ONLN)
if [ "${cpuInfo}" -ge "2" ]; then
  getCpuStat
else
  cpuCore="1"
fi

loongarch64Check=$(uname -m | grep -q loongarch64 && echo true || echo false)
if [ "${loongarch64Check}" = "true" ]; then
  loongarch64_dis="--disable-spinlocks"
  loongarch64_build="--build=arm-linux"
fi

#进入软件的制定安装目录
echo "进入目录/usr/local，下载pgsql文件"
cd /usr/local
#判断是否有postgre版本的安装包
if [ -d postgresql* ]; then
  rm -rf /usr/local/postgresql*
  echo "安装包删除成功"
fi
#判断是否有旧的编译文件
if [ -d /usr/local/pgsql ]; then
  rm -rf /usr/local/pgsql
  echo "旧的编译文件删除成功"
fi

#开始下载pgsql版本10.5并解压
if [ ! -d /usr/local/src ]; then
  mkdir /usr/local/src
fi

cd /usr/local/src
rm -rf post*
wget $DOWN_URL
if [ $? -eq 0 ]; then
  tar -xzvf "postgresql-${PGSQL_VERSION}.tar.gz" -C /usr/local/
fi

echo "pgsql文件解压成功"
#判断用户是否存在
user=${USERNAME}
group=${USERNAME}

# Ensure $group is set and non-empty
if [ -z "$group" ]; then
  echo "Error: group variable is empty."
  exit 1
fi

# Ensure /etc/group file is readable
if [ ! -r /etc/group ]; then
  echo "Error: /etc/group file is not readable or does not exist."
  exit 1
fi

# 如果组不存在，则创建该组
if ! grep -E "^$group:" /etc/group >/dev/null 2>&1; then
  echo "Group $group does not exist. Creating group..."
  groupadd "$group"
else
  echo "Group $group already exists."
fi

# 如果用户不存在，则创建用户
if ! grep -E "^$user:" /etc/passwd >/dev/null 2>&1; then
  echo "User $user does not exist. Creating user..."
  useradd -m "$user" -g "$group"
else
  echo "User $user already exists."
fi

echo "重命名postgresql并且进入安装目录"
mv /usr/local/post* /usr/local/pgsql
cd /usr/local/pgsql
#-------------------------------安装pgsql------------------------------------
echo "安装用得到的库文件及依赖"
sudo apt update
sudo apt install -y gcc make pkg-config libicu-dev zlib1g-dev
echo "开始执行configure配置"
# 判断${INSTALL_DIR}是否存在
if [ -d ${INSTALL_DIR} ]; then
  rm -rf ${INSTALL_DIR}
fi
mkdir -p ${INSTALL_DIR}
./configure --prefix=${INSTALL_DIR} --without-readline ${loongarch64_dis} ${loongarch64_build}
if [ $? == 0 ]; then
  echo "configure配置通过，开始进行make编译"
  make -j $cpuCore
  if [ $? == 0 ]; then
    echo "make编译通过，开始进行make install安装步骤"
    make install
    if [ $? != 0 ]; then
      echo "make install安装失败"
    fi
    echo "安装成功"
  else
    echo "make编译失败，检查错误。"
  fi
else
  echo "configure检查配置失败，请查看错误进行安装库文件"
fi
echo "开始进行pgsql的配置"
# 判断data是否存在
if [ -d ${INSTALL_DIR}/data ]; then
  rm -rf ${INSTALL_DIR}/data
fi
echo "给pgsql创建data目录"
mkdir -p ${INSTALL_DIR}/data
mkdir -p ${INSTALL_DIR}/logs
echo "修改用户组"
chown -R ${USERNAME}:${USERNAME} ${INSTALL_DIR}
chmod -R 700 ${INSTALL_DIR}/data

echo "添加环境变量,进入postgres用户目录"
cd /home/${USERNAME}
if [ -f /home/${USERNAME}/.bashrc ]; then
  /bin/cp /home/${USERNAME}/.bashrc /home/${USERNAME}/.bashrc.bak
  echo "export PGHOME=${INSTALL_DIR}" >>/home/${USERNAME}/.bashrc
  echo "export PGDATA=${INSTALL_DIR}/data" >>/home/${USERNAME}/.bashrc
  echo "export PG_CONFIG=\$PGHOME/bin/pg_config" >>/home/${USERNAME}/.bashrc
  echo "export PATH=${INSTALL_DIR}/bin:\$PATH " >>/home/${USERNAME}/.bashrc
  echo "MANPATH=\$PGHOME/share/man:\$MANPATH" >>/home/${USERNAME}/.bashrc
  echo "LD_LIBRARY_PATH=\$PGHOME/lib:\$LD_LIBRARY_PATH" >>/home/${USERNAME}/.bashrc
  source /home/${USERNAME}/.bashrc
fi
if [ -f /home/${USERNAME}/.profile ]; then
  /bin/cp /home/${USERNAME}/.profile /home/${USERNAME}/.profile.bak
  echo "export PGHOME=${INSTALL_DIR}" >>/home/${USERNAME}/.profile
  echo "export PGDATA=${INSTALL_DIR}/data" >>/home/${USERNAME}/.profile
  echo "export PG_CONFIG=\$PGHOME/bin/pg_config" >>/home/${USERNAME}/.profile
  echo "export PATH=${INSTALL_DIR}/bin:\$PATH " >>/home/${USERNAME}/.profile
  echo "MANPATH=\$PGHOME/share/man:\$MANPATH" >>/home/${USERNAME}/.profile
  echo "LD_LIBRARY_PATH=\$PGHOME/lib:\$LD_LIBRARY_PATH" >>/home/${USERNAME}/.profile
  source /home/${USERNAME}/.profile
fi

alias pg_start="su - postgres -c 'pg_ctl -D \$PGDATA -l \$PGHOME/logs/pgsql.log start'"
alias pg_stop="su - postgres -c 'pg_ctl -D \$PGDATA -l \$PGHOME/logs/pgsql.log stop'"

echo "切换至 ${USERNAME} 用户来初始化数据库"
su - ${USERNAME} -c "${INSTALL_DIR}/bin/initdb -D ${INSTALL_DIR}/data"
if [ $? -eq 0 ]; then
  echo "数据库初始化完成！"
else
  echo "数据库初始化失败！"
fi

# 启动 PostgreSQL
echo "启动PostgreSQL..."
su - ${USERNAME} -c 'pg_ctl -D $PGDATA -l $PGHOME/logs/pgsql.log start'
if [ $? -eq 0 ]; then
  echo "PostgreSQL正在运行..."
else
  echo "PostgreSQL启动失败！！！"
fi

echo "正在安装 pgvector..."
cd /tmp
git clone --branch v0.8.0 https://github.com/pgvector/pgvector.git
if [ $? -eq 0 ]; then
  chown -R ${USERNAME}:${USERNAME} pgvector
  cd pgvector
  echo "正在编译 pgvector..."
  su - ${USERNAME} -c "cd /tmp/pgvector && make && make install"
  if [ $? -eq 0 ]; then
    echo "启用 pgvector..."
    su - ${USERNAME} -c "psql -c 'CREATE EXTENSION vector;'"
  fi
fi

# 修改默认账户密码
su - ${USERNAME} -c "psql -c \"ALTER USER ${USERNAME} WITH PASSWORD '${PASSWORD}';\""
# 检查命令执行状态
if [ $? -eq 0 ]; then
  echo "用户 ${USERNAME} 的密码已成功修改。"
else
  echo "密码修改失败！"
fi

echo "进行必要的配置"
if [ -f "${INSTALL_DIR}/data/pg_hba.conf" ]; then
  # 在指定范围内将 trust 替换为 md5
  sed -i '/# "local" is for Unix domain socket connections only/,$ {s|trust|md5|g;}' "${INSTALL_DIR}/data/pg_hba.conf"
  # 在指定范围内将 127.0.0.1/32 替换为 0.0.0.0/0
  sed -i '/# "local" is for Unix domain socket connections only/,$ {s|127.0.0.1/32|0.0.0.0/0|g;}' "${INSTALL_DIR}/data/pg_hba.conf"
  # 在指定范围内将 ::1/128 替换为 ::/0
  sed -i '/# "local" is for Unix domain socket connections only/,$ {s|::1/128|::/0|g;}' "${INSTALL_DIR}/data/pg_hba.conf"
else
  echo "文件 ${INSTALL_DIR}/data/pg_hba.conf 不存在！"
fi

if [ -f "${INSTALL_DIR}/data/postgresql.conf" ]; then
  sed -i "s|#ssl = off|ssl = off|g" "${INSTALL_DIR}/data/postgresql.conf"
  sed -i "s|#port = 5432|port = 5432|g" "${INSTALL_DIR}/data/postgresql.conf"
  sed -i "s|#listen_addresses = 'localhost'|listen_addresses = '*'|g" "${INSTALL_DIR}/data/postgresql.conf"
  echo "启用慢查询SQL语句跟踪"
  cat >>${INSTALL_DIR}/data/postgresql.conf <<EOF
logging_collector = on
log_destination = 'stderr'
log_directory = '${INSTALL_DIR}/logs'
log_filename = 'postgresql-%Y-%m-%d.log'
log_statement = all
log_min_duration_statement = 5000
EOF
else
  echo "文件 ${INSTALL_DIR}/data/postgresql.conf 不存在！"
fi

su - ${USERNAME} -c "${INSTALL_DIR}/bin/postgres -D ${INSTALL_DIR}/data >>${INSTALL_DIR}/logs/pgsql.log 2>&1 &"

# 重启 PostgreSQL
echo "重启PostgreSQL..."
su - ${USERNAME} -c 'pg_ctl -D $PGDATA -l $PGHOME/logs/pgsql.log restart'
if [ $? -eq 0 ]; then
  echo "PostgreSQL正在运行..."
else
  echo "PostgreSQL重启失败！！！"
fi

echo "---------------------------------------------------------------------------------------"
echo "----------------------------SUCCESS INSTALLATION OF POSTGRESQL-------------------------"
echo "---------------------------------------------------------------------------------------"
echo "------------------- 数据库用户名：${USERNAME} - 数据库密码：${PASSWORD} -------------------"
