---
layout: "post"
title: "软件测试"
date: "2019-09-26 22:04"
categories: [extend]
tags: [test]
---

## 简介

### Web端UI自动化测试

- 常见UI自动化测试框架
    - [Selenium](https://www.selenium.dev/)
        - 支持多平台，支持多浏览器，多语言(C、 java、ruby、python、或都是C#)
        - 支持分布式
    - [Cypress](https://www.cypress.io/) 基于JS开源
        - 支持代理，但是无法使用socks5代理
    - [CodeceptJS](https://codecept.io/) 基于JS开源
        - 支持不同的helper：WebDriver，Puppeteer，Protractor，Nightmare，Testcafe
            - `WebDriver` 就像是一个媒介，代码驱动webdriver。不同浏览器有不同的webdriver，例如火狐的FirefoxDriver，谷歌的 ChromeDriver
                - 对应有一个测试框架为WebDriver，之后被Selenium2集成
            - `Puppeteer` 是一个 Node 库，提供接口来控制 headless Chrome。Headless Chrome是一种不使用 Chrome 来运行 Chrome 浏览器的方式
        - 支持web也支持mobile
        - 提供了现成的codeceptjs-resemblehelper以实现视觉上的回归测试
        - 支持API测试，包括REST和GraphQL
        - 可使用socks5等代理
    - jenkins插件
        - `cucumber reports` 测试报告可视化插件
        - `Allure Jenkins Plugin` 测试报告可视化插件
- 实践
    - 让UI测试更稳定，开发时把页面的关键组件元素加上ID 属性，用唯一的ID去定位元素就稳定多了
    - 项目还需要有高度可视化或者能及时通知测试状态的方式。如可使用Jenkins自带的 Build Monitor View，将对项目pipeline的监控投影到电视上，并配置相应的提示音

### 移动端测试

- [夜神安卓模拟器(支持Mac/Windows)](https://www.yeshen.com/)

#### UI自动化测试

- 业界UI测试工具发展迅速，目前有Robotium、Appium、Espresso、UIAutomator、Calabash等等，其中在Android中应用最广泛的当属UIAutomator、Robotium、Appium
- [Airtest(网易)](https://airtest.doc.io.netease.com/)、autojs

|                    | UIAutomator | Robotium    | Appium           |
| ------------------ | ----------- | ----------- | ---------------- |
| 支持平台            | Android     | Android，H5  | Android，iOS，H5 |
| 脚本语言            | Java        | Java         | Almost any       |
| 是否支持无源码测试    | Yes         | Yes          | Yes              |
| 支持 API 级别       | 16+         | All          | All              |

#### 真机测试

- 参考：https://tech.meituan.com/2018/07/19/cloud-phone.html
- `OpenSTF` 开发真机测试平台
  - minicap、minitouch
- 相关组件

  ![设备界面同步和用户的操作同步组件](/data/images/arch/test-mobile.png)
  - [scrcpy](https://github.com/Genymobile/scrcpy)

### 后端代码测试

- Java代码测试
    - `Junit`参考[junit.md](/_posts/java/junit.md)
    - `TestNG` 是Java中的一个测试框架，类似于JUnit和NUnit，功能都差不多，只是功能更加强大，使用也更方便

### 性能测试

- `jmeter`

#### httpd-tools(ab)

- 测试

```bash
## 安装
yum install httpd-tools

## 测试案例
# -n：总请求次数
# -c：并发次数（最小默认为1且不能大于总请求次数，如：10个请求，10个并发，实际就是1人请求1次；默认最大并发数是20000，一些秒杀项目中可修改源码进行提高此值来进行测试）
# -p：post参数文档路径（如下文中 post_data 中的数据如 `key1=value1&key2=value2` 或`{"name": "smalle"}`）
# -T：Content-type 类型，再使用POST/PUT时可进行指定，默认是 text/plain
# -H：Header内容
ab -n1000 -c10  http://study.163.com/
ab -n 10 -c 10 -p /tmp/post_data_file -T application/json -H 'X-TOKEN: 12345678' http://192.168.1.100/test

## 测试结果
Requests per second # **吞吐率。**服务器并发处理能力的量化描述，单位是reqs/s，指的是某个并发用户数下单位时间内处理的请求数。计算公式：总请求数 / 处理完成这些请求数所花费的时间
Time per request(上) # 用户平均请求等待时间
Time per request(下) # 服务器平均请求处理时间
```
- 测试结果

```bash
# ab -n1000 -c10  http://study.163.com/
Server Software:        nginx
Server Hostname:        study.163.com
Server Port:            80

Document Path:          /               # 请求的URL中的根绝对路径
Document Length:        178 bytes       # 页面的大小

Concurrency Level:      10              # 并发数
Time taken for tests:   1.846 seconds   # 整个测试耗时
Complete requests:      1000            # 总共完成的请求数量
Failed requests:        0               # 失败数
Write errors:           0
Non-2xx responses:      1000
Total transferred:      363000 bytes            # 测试过程中产生的网络传输总量
HTML transferred:       178000 bytes            # 测试过程中产生的HTML传输量
Requests per second:    541.65 [\#/sec] (mean)  # **表示服务器吞吐量，每秒事务数**。括号中的 mean 表示这是一个平均值
Time per request:       18.462 [ms] (mean)      # **表示用户请求的平均响应时间**
Time per request:       1.846 [ms] (mean, across all concurrent requests) # 表示服务器请求平均处理时间，即实际运行时间的平均值
Transfer rate:          192.01 [Kbytes/sec] received # 表示这些请求在单位时间内从服务器获取的数据长度，可以帮助排除是否存在网络流量过大导致响应时间延长的问题

Connection Times (ms) # min最小值、mean平均值、[+/-sd]方差、median中位数、maxz最大值
              min  mean[+/-sd] median   max
Connect:        5    9   1.9      8      14 # socket链路建立消耗，代表网络状况好
Processing:     5    9   1.9      9      16 # 写入缓冲区消耗+链路消耗+服务器消耗
Waiting:        5    9   1.9      9      16 # 写入缓冲区消耗+链路消耗+服务器消耗+读取数据消耗
Total:         10   18   3.7     17      28 # 单个事务总时间

Percentage of the requests served within a certain time (ms)
  50%     17 # 其中50％的用户响应时间小于 17ms
  66%     19
  75%     22
  80%     22
  90%     23
  95%     24 # 其中95％的用户响应时间小于 26ms
  98%     25
  99%     26
 100%     28 (longest request)
```
- 测试案例

```bash
## 2C4G SpringBoot应用非常简单的数据库查询
# 并发数    平均响应      10s内完成比例     失败次数
100         0.69s       100%(小于2s)    0
200         8s          100%(小于9s)    0
300         60s         80%(小于7s)     43
1000        60s         66%(小于7s)	    108
```

### 其他框架

- 移动App兼容性测试工具Spider

## Selenium

- 相关组件
    - Selenium：web自动化测试工具集，包括IDE、Grid、RC(selenium 1.0)、WebDriver(selenium 2.0)等
    - Selenium IDE：浏览器的一个插件，提供简单的脚本录制、编辑与回放功能
    - Selenium Grid：是用来对测试脚步做分布式处理，现在已经集成到selenium server 中了

## puppeteer

- 基于Node实现
- https://puppeteer.bootcss.com/
- [将自己在CSDN上的文章下载到本地并上传到掘金](https://github.com/accforgit/blog-data/tree/master/%E5%B0%86%E8%87%AA%E5%B7%B1%E5%9C%A8CSDN%E4%B8%8A%E7%9A%84%E6%96%87%E7%AB%A0%E4%B8%8B%E8%BD%BD%E5%88%B0%E6%9C%AC%E5%9C%B0%E5%B9%B6%E4%B8%8A%E4%BC%A0%E5%88%B0%E6%8E%98%E9%87%91)

## Cypress

## CodeceptJS

## appium移动端自动化测试框架

- 介绍
  - 官网：http://appium.io/
  - Appium 的核心一个是暴露 REST API 的 WEB 服务器。它接受来自客户端的连接，监听命令并在移动设备（支持Android，iOS，H5）上执行，答复 HTTP 响应来描述执行结果
- 安装
  - 需要安装Java JDK 、Android SDK
  - appium服务端安装：`npm install -g appium`（v1.18.0，需要node > 10），安装成功后可执行`appium`查看（或者基于Appium Desktop启动）
  - [Appium Desktop](https://github.com/appium/appium-desktop) 服务器图形管理工具安装（可选）
  - 客户端：如通过python在写测试脚本的时候可以使用库`pip install Appium-Python-Client`

### 简单案例参考

- 参考：https://blog.csdn.net/u013314786/article/details/105768650
- 安装[夜神模拟器 v6.6.1.2](https://www.yeshen.com/)
  - 查看设备
    - `adb connect 127.0.0.1:62001`
    - `adb devices`
    - 需要保证模拟器版本和Android SDK的adb.exe版本一直，可将模拟器的adb.exe覆盖掉Android SDK的
  - 在模拟器上安装测试[apk](https://github.com/lixk/apptest/blob/master/%E6%B5%8B%E8%AF%95apk/com.youdao.calculator-2.0.0.apk)
- 基础信息获取

    ```bash
    # 获取模拟器或手机的Android内核版本号，或者直接在手机或模拟器上查看
    adb shell getprop ro.build.version.release # 5.1.1
    # 获取deviceName设备名称。如果是真机，在'设置->关于手机->设备名称'里查看，或者`adb devices -l`中model的值；如果是模拟器，夜神模拟器为`127.0.0.1:62001`
    # （%ANDROID_HOME%/platform-tools下运行）获取appPackage名（package: name=的值）和appActivity（launchable activity name=的值）
    aapt dump badging D:/apk/com.youdao.calculator-2.0.0.apk # com.youdao.calculator 和 com.youdao.calculator.activities.MainActivity
    ```
- 启动Appium Desktop
  - 启动服务器 - 显示`Appium REST http interface listener started on 0.0.0.0:4723`则启动成功
- 查看元素标识（id/xpath）
  - Appium Desktop - File - New Session Window
  - 自动设定 - 所需功能 - JSON Representation（复制下列代码） - 保存 - 启动会话（会连接到模拟器并显示出app界面）

    ```json
    // platformName定义为 Android | IOS
    {
        "platformName": "Android",
        "platformVersion": "5.1.1",
        "deviceName": "127.0.0.1:62001",
        "appPackage": "com.youdao.calculator",
        "appActivity": "com.youdao.calculator.activities.MainActivity",
        "resetKeyboard": true,
        "unicodeKeyboard": true
    }
    ```
- 测试脚本参考[github](https://github.com/oldinaction/smpython/tree/master/D03TestAppium/test_appium)
  - 启动测试脚本也会连接模拟器，然后生成测试报告

## OpenSTF移动设备共享平台

- 介绍
  - [github](https://github.com/openstf/stf)
  - [官网](https://openstf.io/) 停止维护
    - 第三方维护版: https://github.com/DeviceFarmer/stf
  - 类似
    - https://sonic-cloud.cn/
  - Smartphone Test Farm（简称STF）是一个web应用程序，主要用于从指定的浏览器中远程调试智能手机、智能手表等，可远程调试超过160多台设备
  - [百度MTC的远程真机调试](https://mtc.baidu.com/)、Testin的云真机、腾讯WeTest的云真机、[阿里MQC的远程真机租用](https://emas.console.aliyun.com/entrance)都是基于STF进行改进的 [^1]
  - 免费真机云测
    - 华为云调试：部分机型每天会赠送一定的优惠时长(300min)
      - 支持本地上传APK应用
  - 缺点：存在Android部分设备易掉线、IOS高版本不兼容、操作卡顿等现象
- 原理
  - 通过adb连接Android设备
  - STF获取移动设备屏幕：基于minicap（STF开源）组件截取Android设备屏幕，并将突破以socket方式发给stf服务端，然后stf服务端通过wesocket转发给web端进行显示
  - STF将touch动作同步给移动设备：基于minitouch（STF开源）组件
- 安装 [^2]

```bash
## 安装（最好顺序启动）。此案例是在Windows-Docker中按照
# 启动数据库（RethinkDB为文档型数据库），启动后可访问查看：http://192.168.99.101:8090/
docker run -d --name rethinkdb -v /d/temp/docker/rethinkdb:/data --net host rethinkdb:latest rethinkdb --bind all --cache-size 8192 --http-port 8090
# 启动adb服务
docker run -d --name adbd --privileged -v /d/temp/docker/usb:/dev/bus/usb --net host sorccu/adb:latest
# 启动sft。`stf local ...` 启动一个完整的本地开发环境（会调用stf provider）
# --public-ip 为容器宿主机IP，即开启外部网络访问；--allow-remote 允许远程设备（Android机连接PC-B，然后PC-B与此STF通信，从而控制移动设备；由于网络等原因实际操作中不建议开启）
docker run -d --name stf --net host openstf/stf:latest stf local --public-ip 192.168.99.101 --allow-remote

## 进入stf容器进行设置（`ps -ef`查看已启动的进程）
docker exec -it stf bash
# `stf provider ...` 启动provider单元
# --name机器名称（即docker宿主机-虚拟机名称default，也可通过docker logs stf查看日志得知） 
# --connect-sub 和 --connect-push 均为基于 ZeroMQ（嵌入式库） 进行通信的。且地址就用127.0.0.1，不要输入内网地址，否则容易出现`Providing all 0 of 1 device(s); ignoring "127.0.0.1:62001"`导致设备连接不上（如果PC-A、PC-B均安装了stf和adb来部署集群，如果在PC-B上运行这个命令可考虑使用内网地址）
stf provider --name default --min-port 7400 --max-port 7700 --connect-sub tcp://127.0.0.1:7114 --connect-push tcp://127.0.0.1:7116 --group-timeout 20000 --public-ip 192.168.99.101 --storage-url http://localhost:7100/ --adb-host 192.168.99.1 --adb-port 5037 --vnc-initial-size 600x800 --allow-remote # 测试时，每次启动stf都需要执行此命令

## 启动adb
# 由于本案例使用的是在windows+Docker+模拟器搭建的，因此需要对 adb server 并对外暴露 5037 端口（如果普通启动则是仅在127.0.0.1上监听设备连接，此时需要暴露到内网；如果是linux等基于docker安装stf，移动设备连接linux即可，无需对外暴露端口；如果是linux-A安装了stf，linux-B安装了adb，则linux-B上的设备要被stf连接，则linux-B也要对外暴露5037端口）
adb nodaemon server -a -P 5037 # adb 1.0.32以上的，启动后命令行不要关闭。如果启动失败，可以`adb kill-server`停止进程后重新运行
# adb -a -P 5037 fork-server server # adb 1.0.32以上的

## 启动模拟器，或者手机连接上STF机器才可查看到设备：需要在开发者中心，开启USB调试，某些手机还需要启动 USB安装、USB点击
# 测试时，使用夜神模拟器显示的页面未黑屏，但是可以点击；使用android studio中的模拟器可以正常显示画面和点击

## 访问，管理员账号：administrator/administrator@fakedomain.com (随便输入一个用户名也能登录，但是是普通账号)
http://192.168.99.101:7100
```

## SikuliX桌面自动化方案

- Sikuli(X)是一种新颖的图形脚本语言，或者说是一种另类的自动化测试技术。通过OCR技术，使用图片来作为脚本的识别点/触发点，来进行操作
- 参考文章
    - https://www.wnark.com/archives/71.html
- 默认不支持对中文OCR，需要额外包

## 测试用例

- https://tech.meituan.com/2016/03/22/testcase-templete.html


## 硬件测试

### 磁盘

- 块存储和文件存储的测试重点也不一样
    - 块存储测试：fio/iozone是两个典型的测试工具，重点测试IOPS，延迟和带宽
    
        ```bash
        # fio -filename=/dev/sdc -iodepth=${iodepth} -direct=1 -bs=${bs} -size=100% --rw=${iotype} -thread -time_based -runtime=600 -ioengine=${ioengine} -group_reporting -name=fioTest
        # 测试IOPS：iodepth=32/64/128，bs=4k/8k，rw=randread/randwrite，ioengine=libaio
        # 测试延迟：iodepth=1，bs=4k/8k，rw=randread/randwrite，ioengine=sync
        # 测试带宽：iodepth=32/64/128，bs=512k/1m，rw=read/write，ioengine=libaio
        ```
    - fio/vdbench/mdtest是测试文件系统常用的工具。fio/vdbench用来评估IOPS，延迟和带宽；mdtest评估文件系统元数据性能，主要测试指标是creation和stat，需要采用mpirun并发测试
    
        ```bash
        # fio -filename=/mnt/yrfs/fio.test -iodepth=1 -direct=1 -bs=${bs} -size=500G --rw=${iotype} -numjobs=${numjobs} -time_based -runtime=600 -ioengine=sync -group_reporting -name=fioTest
        # 与块存储的测试参数有一个很大区别，就是ioengine都是用的sync，用numjobs替换iodepth
        # 测试IOPS：bs=4k/8k，rw=randread/randwrite，numjobs=32/64
        # 测试延迟：bs=4k/8k，rw=randread/randwrite，numjobs=1
        # 测试带宽：bs=512k/1m，rw=read/write，numjobs=32/64

        # mpirun --allow-run-as-root -mca btl_openib_allow_ib 1 -host yanrong-node0:${slots},yanrong-node1:${slots},yanrong-node2:${slots} -np ${num_procs} mdtest -C -T -d /mnt/yrfs/mdtest -i 1 -I ${files_per_dir} -z 2 -b 8 -L -F -r -u
        ```

#### fio 工具

- fio使用

```bash
## 安装
yum install -y fio

## 常见参数
-filename=/data/test        # 支持文件、文件系统或者裸设备，可以通过冒号分割。-filename=/dev/sda2或-filename=/dev/sdb:/dev/sdc
-direct=1                   # 测试过程绕过机器自带的buffer，使测试结果更真实
-iodepth=4                  # io深度为4。如果ioengine采用异步方式，该参数表示一批提交保持的io单元数
-rw                         # 测试读写模式
    -rw=randwread             # 测试随机读的I/O
    -rw=randwrite             # 测试随机写的I/O
    -rw=randrw                # 测试随机混合写和读的I/O
    -rw=read                  # 测试顺序读的I/O
    -rw=write                 # 测试顺序写的I/O
    -rw=rw                    # 测试顺序混合写和读的I/O
-ioengine=libaio              # io引擎使用libaio | pync方式，如果要使用libaio引擎，可能需要`yum install libaio-devel`包。默认值是sync同步阻塞I/O，libaio是Linux的native异步I/O
-bs=4k                      # 单次io的块文件大小为4k。默认是4k
-size=2G                    # 本次的测试文件大小为2g，以每次4k的io进行测试。**注意：会在上述文件(/data/test)中写入2G的数据**
-numjobs=4                  # 本次的测试线程为4
-runtime=60                 # 测试时间为60秒，如果不写则一直将2g文件每次分4k写完为止
-group_reporting            # 关于显示结果的，汇总每个进程的信息
-lockmem=1g                 # 只使用1g内存进行测试
-name=Rand_Write_Testing    # 测试名称

## 结果参数说明
bw              # 磁盘的吞吐量，是顺序读写的关键指标
iops            # 磁盘的每秒读写次数，是随机读写的关键指标

io              # 执行了多少M的IO
slat            # 提交延迟
clat            # 完成延迟
lat             # 响应时间
cpu             # 利用率
IO depths       # io队列
IO submit       # 单个IO提交要提交的IO数
IO latencies    # IO完延迟的分布
ios             # 所有group总共执行的IO数
merge           # 总共发生的IO合并数
io_queue        # 花费在队列上的总共时间
util            # 磁盘利用率
```

- 使用案例(基于阿里云80G SSD硬盘进行)

```bash
touch ~/test
## 执行测试
fio -filename=~/test -direct=1 -iodepth=4 -rw=randrw -ioengine=libaio -bs=4k -size=2G -numjobs=4 -runtime=60 -group_reporting -name=Rand_Write_Testing

## 测试结果
Rand_Write_Testing: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=4
...
fio-3.7
Starting 4 processes
Rand_Write_Testing: Laying out IO file (1 file / 2048MiB)
Jobs: 4 (f=4): [m(4)][7.0%][r=5024KiB/s,w=4816KiB/s][r=1256,w=1204 IOPS][eta 13m:27s] 
Rand_Write_Testing: (groupid=0, jobs=4): err= 0: pid=2450: Fri Sep 27 18:30:30 2019
    # iops：磁盘的每秒读写次数，是随机读写的关键指标
    # bw：磁盘的吞吐量，是顺序读写的关键指标
   read: IOPS=1226, BW=4908KiB/s (5026kB/s)(288MiB/60032msec)
    slat (usec): min=2, max=8631, avg=44.76, stdev=80.70
    clat (usec): min=26, max=96665, avg=6108.77, stdev=18978.72
     lat (usec): min=469, max=96678, avg=6154.07, stdev=18977.56
    clat percentiles (usec):
     |  1.00th=[  594],  5.00th=[  668], 10.00th=[  717], 20.00th=[  791],
     | 30.00th=[  857], 40.00th=[  922], 50.00th=[ 1004], 60.00th=[ 1106],
     | 70.00th=[ 1237], 80.00th=[ 1500], 90.00th=[ 2507], 95.00th=[77071],
     | 99.00th=[82314], 99.50th=[83362], 99.90th=[84411], 99.95th=[84411],
     | 99.99th=[91751]
   bw (  KiB/s): min=  936, max= 1624, per=25.01%, avg=1227.33, stdev=85.25, samples=480
   iops        : min=  234, max=  406, avg=306.82, stdev=21.31, samples=480
  write: IOPS=1233, BW=4934KiB/s (5052kB/s)(289MiB/60032msec)
    slat (usec): min=3, max=2539, avg=44.86, stdev=71.18
    clat (usec): min=35, max=94244, avg=6796.74, stdev=19522.18
     lat (usec): min=513, max=94265, avg=6842.16, stdev=19521.01
    clat percentiles (usec):
     |  1.00th=[  635],  5.00th=[  734], 10.00th=[  799], 20.00th=[  906],
     | 30.00th=[ 1012], 40.00th=[ 1123], 50.00th=[ 1237], 60.00th=[ 1401],
     | 70.00th=[ 1614], 80.00th=[ 2040], 90.00th=[ 4621], 95.00th=[78119],
     | 99.00th=[82314], 99.50th=[83362], 99.90th=[85459], 99.95th=[86508],
     | 99.99th=[92799]
   bw (  KiB/s): min= 1008, max= 1600, per=25.01%, avg=1233.75, stdev=73.48, samples=480
   iops        : min=  252, max=  400, avg=308.42, stdev=18.37, samples=480
  lat (usec)   : 50=0.01%, 100=0.01%, 250=0.01%, 500=0.03%, 750=10.12%
  lat (usec)   : 1000=29.20%
  lat (msec)   : 2=43.84%, 4=7.64%, 10=2.17%, 20=0.42%, 50=0.07%
  lat (msec)   : 100=6.50%
  cpu          : usr=0.51%, sys=3.68%, ctx=114096, majf=0, minf=136
  IO depths    : 1=0.1%, 2=0.1%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=73655,74048,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=4

Run status group 0 (all jobs):
   READ: bw=4908KiB/s (5026kB/s), 4908KiB/s-4908KiB/s (5026kB/s-5026kB/s), io=288MiB (302MB), run=60032-60032msec
  WRITE: bw=4934KiB/s (5052kB/s), 4934KiB/s-4934KiB/s (5052kB/s-5052kB/s), io=289MiB (303MB), run=60032-60032msec

Disk stats (read/write):
  vda: ios=73487/73884, merge=0/114, ticks=449091/500446, in_queue=950677, util=100.00%
```
- 基于配置文件测试

```bash
# 基于下文配置文件fio.conf进行测试
fio fio.conf

# 复制下面的配置内容，将directory=/path/to/test修改为测试硬盘挂载目录的地址，并另存为fio.conf
[global]
ioengine=libaio
direct=1
thread=1
norandommap=1
randrepeat=0
runtime=60
ramp_time=6
size=1g
directory=/path/to/test

[read4k-rand]
stonewall
group_reporting
bs=4k
rw=randread
numjobs=8
iodepth=32

[read64k-seq]
stonewall
group_reporting
bs=64k
rw=read
numjobs=4
iodepth=8

[write4k-rand]
stonewall
group_reporting
bs=4k
rw=randwrite
numjobs=2
iodepth=4

[write64k-seq]
stonewall
group_reporting
bs=64k
rw=write
numjobs=2
iodepth=4
```


---

参考文章

[^1]: https://tech.meituan.com/2018/07/19/cloud-phone.html
[^2]: https://blog.csdn.net/xl_lx/article/details/79445862


