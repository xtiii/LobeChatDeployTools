# lcdt - LobeChatDeployTools
基于 [lobehub/lobe-chat](https://github.com/lobehub/lobe-chat) 的本地，无 Docker 部署方式

## 功能演示
![tools](https://raw.githubusercontent.com/xtiii/LobeChatDeployTools/main/Img/tools.jpg)

## 使用方法：
### 1. 首先安装 Node.js，以及 bun (依次执行以下命令)
```shell
# installs fnm (Fast Node Manager)
curl -fsSL https://fnm.vercel.app/install | bash

# activate fnm
source ~/.bashrc

# download and install Node.js
fnm use --install-if-missing 22

# verifies the right Node.js version is in the environment
node -v # should print `v22.11.0`

# verifies the right npm version is in the environment
npm -v # should print `10.9.0`

npm install -g bun

bun -v

# 输出版本号即安装成功
```

### 2. 运行脚本
```shell
wget -O lcdt.sh https://raw.githubusercontent.com/xtiii/LobeChatDeployTools/main/lcdt.sh && chmod +x lcdt.sh && ./lcdt.sh
```


