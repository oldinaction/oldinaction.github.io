---
layout: "post"
title: "区块链"
date: "2021-02‎-26‎ ‏‎18:34"
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

## 架构

![blockchain-arch.png](/data/images/arch/blockchain-arch.png)

- 主流的区块链技术架构主要分为五层 [^4]
    - 数据层：是最底层的技术，主要实现了数据存储、账户信息、交易信息等模块，数据存储主要基于Merkle树，通过区块的方式和链式结构实现，而账户和交易基于数字签名、哈希函数和非对称加密技术等多种密码学算法和技术，来保证区块链中数据的安全性
    - 网络层：主要实现网络节点的连接和通讯，又称点对点技术，各个区块链节点通过网络进行通信
    - 共识层：是通过共识算法，让网络中的各个节点对全网所有的区块数据真实性正确性达成一致，防止出现拜占庭攻击、51攻击等区块链共识算法攻击
    - 激励层：主要是实现区块链代币的发行和分配机制，是公有链的范畴
    - 应用层：一般把区块链系统作为一个平台，在平台之上实现一些去中心化的应用程序或者智能合约，平台提供运行这些应用的虚拟机

## 虚拟货币

### 门罗币(XMR)

- [官网](https://web.getmonero.org/zh-cn/)、[Web端钱包](https://wallet.mymonero.com)
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




--- 

参考文章

[^1]: https://www.ruanyifeng.com/blog/2017/12/blockchain-tutorial.html (区块链入门教程)
[^2]: http://www.ruanyifeng.com/blog/2018/01/bitcoin-tutorial.html (比特币入门教程)
[^3]: https://www.infoq.cn/article/2018/09/how-choose-blockchain-framework
[^4]: https://www.codenong.com/cs106604338/ (基于java开发一套完整的区块链系统详细教程)
[^5]: http://www.wabi.com/news/24364.html

