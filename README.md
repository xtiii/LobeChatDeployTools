# LobeChatDeployTools
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
### 2. 克隆 LobeChat 仓库
```shell
# 以下仓库每3小时和官方同步一次(你也可以将下面链接换成官方仓库)
git clone https://github.com/xtiii/LobeChat.git
cd ./LobeChat
```
### 3. 运行脚本
* 确保在 LobeChat **根目录**下执行以下命令

* 然后请根据脚本内的提示进行下一步操作
```shell
wget -O LobeChatTools.sh https://raw.githubusercontent.com/xtiii/LobeChatDeployTools/main/LobeChatTools.sh && chmod +x LobeChatTools.sh && ./LobeChatTools.sh
