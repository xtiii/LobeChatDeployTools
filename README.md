# lcdt - LobeChatDeployTools

基于 [lobehub/lobe-chat](https://github.com/lobehub/lobe-chat) 的本地，无 Docker 部署方式

## 功能演示

![tools](https://raw.githubusercontent.com/xtiii/LobeChatDeployTools/main/Img/tools.jpg)

## 使用方法：

### 1. 首先安装 Node.js，以及 bun (依次执行以下命令)

以下演示 nvm 方式安装 Node.js
[更多安装方式点此查看](https://nodejs.org/en/download/package-manager)

```shell
# installs nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

# 注意：这个时候请查看输出信息，并执行输出信息内的命令

# download and install Node.js (you may need to restart the terminal)
nvm install 22
# verifies the right Node.js version is in the environment
node -v # should print `v22.11.0`
# verifies the right npm version is in the environment
npm -v # should print `10.9.0`

npm install -g bun

bun -v

# 输出版本号即安装成功
```

### 2. 运行脚本

国内源

```shell
wget -O lcdt.sh https://gitee.com/SoTime/LobeChatDeployTools/raw/main/lcdt.sh && chmod +x lcdt.sh && ./lcdt.sh
```

国外源

```shell
wget -O lcdt.sh https://raw.githubusercontent.com/xtiii/LobeChatDeployTools/main/lcdt.sh && chmod +x lcdt.sh && ./lcdt.sh
```


