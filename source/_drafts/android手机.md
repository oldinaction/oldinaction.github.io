---
layout: "post"
title: "Android手机"
date: "2019-10-27 21:09"
categories: [extend]
tags: [android]
---

## 刷机

- 卡刷和线刷
    - 线刷是指使用USB线连接个人计算机，并在个人计算机上使用刷机软件进行刷机的行为，而卡刷则是把固件或者升级包拷贝到手机SD卡中进行刷机升级操作
    - 线刷和卡刷的本质区别在于recovery。刷了官方ROM的recovery.img，刷机方式就是线刷；刷了第三方中文recovery.img，刷机方式就是卡刷
    - 线刷是救砖必备
- Recovery模式
    - [android_bootable_recovery](https://github.com/omnirom/android_bootable_recovery) 未测试
    - 第三方可安装奇兔Recovery
    - 小米手机3自带Recovery系统是关机键+音量上键进入，然后通过音量键上下移动，关机键进行确认
- fastboot模式
    - 小米手机3是关机键+音量下键进入，通过线刷官方rom包可进入此模式刷机

### 小米手机3-移动版(M3 TD)

- 小米3是3G手机，国内三大移动运营商3G网络标准为：中国移动(`TD-SCDMA`)、中国联通(`WCDMA`)、中国电信(`CDMA2000`)
- 刷机需要注意手机型号
- 忘记小米账号密码解决方案：将小米手机系统刷到MIUI V6(5.x)之前(MIUI V6使用的是`android 4.4`，微信已经不支持安装，2019年)；或者刷成Flame系统，如`Flyme 5.1.12.16R beta`(android 5.1.x)、`Flyme 6.7.11.24R beta`(android 6.0，测试安装占用存储空间11G)

#### 手动刷机

- 参考：http://www.miui.com/shuaji-328.html
    - Recovery下更新zip包：就是进入Recovery模式(关机键+音量上键)
    - 线刷MIUI：连接USB，进入fastboot模式，并通过`MiFlash`选择电脑上的ROM包进行刷机(选择清除应用数据)。测试安装`MIUI 4.8.22`(android 4.4)成功
- ROM包官方只提供`MIUI 4.8.22`(android 4.4)版本的，历史版本可在[奇兔](http://www.7to.cn/)下载

#### 奇兔刷机

- 参考：http://www.7to.cn/
- 安装奇兔刷机电脑端 - 一键刷机 - 选择本地ROM或在线下载ROM - 执行刷机。此过程会自动安装`奇兔Recovery系统`
    - 实际操作未成功，提示ROM发送失败
    - **解决方案(测试安装Flyme 6.7.11.24R beta成功)**：可安装`奇兔Recovery系统`后，并将ROM放入到sdcard的根目录(连接电脑根目录即可)，进入Recovery模式，然后安装，选择ROM(adcard/0/xxx)

#### 安装第三方Recovery

- 参考：http://rom.7to.cn/jiaochengdetail/3935
- 卡刷模式安装第三方Recovery：下载Recovery包，并将其复制到sdcard，进入小米系统升级，点击菜单按键，选择Recovery安装包(adcard/0/xxx)，升级成功取消立即重启，然后在当前界面点击菜单键重启进入Recovery
- 在此Recovery模式下通过安装zip包安装`Flyme 6.7.11.24R beta`失败




