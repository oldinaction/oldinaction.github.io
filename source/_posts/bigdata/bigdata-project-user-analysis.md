---
layout: "post"
title: "大数据项目实践 —— 用户行为分析"
date: "2021-07-25 18:11"
categories: bigdata
tags: [project]
---

## 简介

- 本项目源码参考[smjava/bigdata-hadoop-project](https://github.com/oldinaction/smjava)
- 可通过站长工具查看某网站的每日PV值(只有通过百度等外链进入网站的才会统计，直接输入网址无法被此类工具统计到)，从而估算一下网站每日产生的数据量
- 集群大小
    - 中小型30-50台，100台以上可认为是较大集群了
    - 三一共6套集群：最新12台机器，最大68台，都是基于128G来说的；北京某交通分析，38台集群
    - spark(充分利用内存)、redis、hbase这种内存消耗较大的一般不混合部署；zk、hadoop这种可以混合部署
- 日志大小(按天算)
    - 条数：千万级别-亿级别
    - 大小：几百个G，中大型集群可能上PB/T；**条数(PV数) * 每条大小(如1KB左右)**

## 用户行为分析需求 

- 本项目分别从七个大的角度来进行用户行为分析
    - 用户基本信息分析模块
        - 用户基本信息分析模块主要是从用户/访客和会员两个主要角度分析浏览相关信息，包括但不限于新增用户，活跃用户，总用户，新增会员，活跃会员，总会员以及会话分析等
    - 浏览器信息分析模块
        - 在用户基本信息分析的基础上添加一个浏览器这个维度信息：浏览器用户分析、浏览器会员分析、浏览器会话分析、浏览器PV分析
    - 地域信息分析模块
        - 活跃访客地域分析、跳出率分析(分析各个不同地域的跳出率情况)
    - 用户浏览深度分析模块
    - 外链数据分析模块
        - 主要分析各个不同外链端带来的用户访问量数据：外链偏好分析、外链会话(跳出率)分析
    - 订单分析模块
    - 事件分析模块
        - 如订单相关的事件
- 几个项目概念
    - 用户/访客：表示同一个浏览器代表的用户。唯一标示用户
    - 会员：表示网站的一个正常的会员用户
    - 会话：一段时间内的连续操作，就是一个会话中的所有操作
    - PV：访问页面的数量
    - 在本次项目中，所有的计数都是去重过的。比如：活跃用户/访客，计算uuid的去重后的个数
- 数据流向图

    ![bigdata-user-analysis.png](/data/images/bigdata/bigdata-user-analysis.png)
    - 其中将Hbae的数据进行计算后，将结果保存到mysql，可以使用手写MapReduce或基于Hive实现

## JS SDK设计

- 不采用ip来标示用户的唯一性，而是通过在cookie中填充一个uuid来标示用户的唯一性
- Js sdk执行工作流

    ![bigdata-user-analysis-flow.png](/data/images/bigdata/bigdata-user-analysis-flow.png)
- PC端事件分析
    - 用户基本信息就是用户的浏览行为信息分析，也就是我们只需要pageview事件就可以了
    - 浏览器信息分析以及地域信息分析其实就是在用户基本信息分析的基础上添加浏览器和地域这个维度信息
        - 其中浏览器信息我们可以通过浏览器的window.navigator.userAgent来进行分析
        - 地域信息可以通过nginx服务器来收集用户的ip地址来进行分析
    - 外链数据分析以及用户浏览深度分析我们可以在pageview事件中添加访问页面的当前url和前一个页面的url来进行处理分析
    - 订单信息分析要求pc端发送一个订单产生的事件，那么对应这个模块的分析，需要一个新的事件chargeRequest
    - 对于事件分析我们也需要一个pc端发送一个新的事件数据，我们可以定义为event。除此之外，我们还需要设置一个launch事件来记录新用户的访问
    - PC端的各种不同事件发送的数据url格式如下，其中url中后面的参数就是我们收集到的数据：http://node01/bigdata-tracker.png?requestdata
        - **通过JS请求一个图片URL，并附带请求参数，这样不会影响前端页面的正常运行**
- 事件和可分析的模块
    - pageview事件：用户基本信息分析、浏览器信息分析、地域信息分析、外链数据分析、用户浏览深度分析
    - chargeRequest事件：订单信息分析
    - event事件：事件分析
    - launch事件

### 事件说明

- Launch事件
    - 当用户第一次访问网站的时候触发该事件，不提供对外调用的接口，只实现该事件的数据收集
    - 发送的数据 `u_sd=8E9559B3-DA35-44E1-AC98-85EB37D1F263&c_time=1449137597974&ver=1&en=e_l&pl=website&sdk=js&b_rst=1920*1080&u_ud=12BF4079-223E-4A57-AC60-C1A04D8F7A2F&b_iev=Mozilla%2F5.0%20(Windows%20NT%206.1%3B%20WOW64)%20AppleWebKit%2F537.1%20(KHTML%2C%20like%20Gecko)%20Chrome%2F21.0.1180.77%20Safari%2F537.1&l=zh-CN`
- Pageview事件
    - 当用户访问页面/刷新页面的时候触发该事件。该事件会自动调用，也可以让程序员手动调用
    - 发送的数据 `ver=1&en=e_pv&pl=website&sdk=js&b_rst=1920*1080&u_ud=12BF4079-223E-4A57-AC60-C1A04D8F7A2F&b_iev=Mozilla%2F5.0%20(Windows%20NT%206.1%3B%20WOW64)%20AppleWebKit%2F537.1%20(KHTML%2C%20like%20Gecko)%20Chrome%2F21.0.1180.77%20Safari%2F537.1&l=zh-CN&u_sd=8E9559B3-DA35-44E1-AC98-85EB37D1F263&c_time=1449137597979&ht=www.msb.com%3A8080&p_url=http%3A%2F%2Fwww.msb.com%3A8080%2Fvst_track%2Findex.html`
- ChargeRequest事件
    - 当用户下订单的时候触发该事件，该事件需要程序主动调用。
    - 发送的数据 `u_sd=8E9559B3-DA35-44E1-AC98-85EB37D1F263&c_time=1449139048231&oid=orderid123&on=%E4%BA%A7%E5%93%81%E5%90%8D%E7%A7%B0&cua=1000&cut=%E4%BA%BA%E6%B0%91%E5%B8%81&pt=%E6%B7%98%E5%AE%9D&ver=1&en=e_crt&pl=website&sdk=js&b_rst=1920*1080&u_ud=12BF4079-223E-4A57-AC60-C1A04D8F7A2F&b_iev=Mozilla%2F5.0%20(Windows%20NT%206.1%3B%20WOW64)%20AppleWebKit%2F537.1%20(KHTML%2C%20like%20Gecko)%20Chrome%2F21.0.1180.77%20Safari%2F537.1&l=zh-CN`
    - 参数

    | 参数           | 类型   | 是否必填 | 描述             |
    | -------------- | ------ | -------- | ---------------- |
    | orderId        | string | 是       | 订单id           |
    | orderName      | String | 是       | 产品购买描述名称 |
    | currencyAmount | double | 是       | 订单价格         |
    | currencyType   | String | 是       | 货币类型         |
    | paymentType    | String | 是       | 支付方式         |

- Event事件
    - 当访客/用户触发业务定义的事件后，前端程序调用该方法
    - 发送的数据 `ca=%E7%B1%BB%E5%9E%8B&ac=%E5%8A%A8%E4%BD%9C&c_time=1449139512665&u_sd=8E9559B3-DA35-44E1-AC98-85EB37D1F263&kv_p_url=http%3A%2F%2Fwwwmsb..com%3A8080%2Fvst_track%2Findex.html&kv_%E5%B1%9E%E6%80%A7key=%E5%B1%9E%E6%80%A7value&du=1000&ver=1&en=e_e&pl=website&sdk=js&b_rst=1920*1080&u_ud=12BF4079-223E-4A57-AC60-C1A04D8F7A2F&b_iev=Mozilla%2F5.0%20(Windows%20NT%206.1%3B%20WOW64)%20AppleWebKit%2F537.1%20(KHTML%2C%20like%20Gecko)%20Chrome%2F21.0.1180.77%20Safari%2F537.1&l=zh-CN`
    - 参数
    
    | 参数     | 类型   | 是否必填 | 描述           |
    | -------- | ------ | -------- | -------------- |
    | category | string | 是       | 自定义事件名称 |
    | action   | String | 是       | 自定义事件动作 |
    | map      | map    | 否       | 其他参数       |
    | duration | long   | 否       | 事件持续时间   |

### 数据参数说明

- 在各个不同事件中收集不同的数据发送到nginx服务器，但是实际上这些收集到的数据还是有一些共性的。下面将所用可能用到的参数描述如下

| 参数名称 | 类型   | 描述                       |
| -------- | ------ | -------------------------- |
| en       | string | 事件名称, eg: e_pv         |
| ver      | string | 版本号, eg: 0.0.1          |
| pl       | string | 平台, eg: website,javaserver|
| sdk      | string | Sdk类型, eg: js            |
| b_rst    | string | 浏览器分辨率，eg: 1800*678 |
| b_iev    | string | 浏览器信息useragent        |
| u_ud     | string | 用户/访客唯一标识符        |
| l        | string | 客户端语言                 |
| u_mid    | string | 会员id，和业务系统一致     |
| u_sd     | string | 会话id                     |
| c_time   | string | 客户端时间                 |
| p_url    | string | 当前页面的url              |
| p_ref    | string | 上一个页面的url            |
| tt       | string | 当前页面的标题             |
| ca       | string | Event事件的Category名称    |
| ac       | string | Event事件的action名称      |
| kv_*     | string | Event事件的自定义属性      |
| du       | string | Event事件的持续时间        |
| oid      | string | 订单id                     |
| on       | string | 订单名称                   |
| cua      | string | 支付金额                   |
| cut      | string | 支付货币类型               |
| pt       | string | 支付方式                   |

## Java SDK设计

- 本项目中java sdk的作用主要就是发送支付成功/退款成功的信息给nginx服务器
- 工作流：Start - 程序后台调用支付成功方法 - 单独线程发送ChargeRequest事件 - End
- 本项目中在程序后台只会出发chargeSuccess事件，本事件的主要作用是发送订单成功的信息给nginx服务器。发送格式同pc端发送方式，也是访问同一个url来进行数据的传输。格式为：http://node01/bigdata-tracker.png?requestData
- 事件说明
    - ChargeSuccess事件
        - 当会员最终支付成功的时候触发该事件，该事件需要程序主动调用
        - 发送数据 `u_mid=msb&c_time=1449142044528&oid=orderid123&ver=1&en=e_cs&pl=javaserver&sdk=jdk`
        - 参数：orderId(订单ID，字符串必填)、memberId(会员ID，字符串必填)
    - ChargeRefund事件
        - 当会员进行退款操作的时候触发该事件，该事件需要程序主动调用
        - 发送数据 `u_mid=msb&c_time=1449142044528&oid=orderid123&ver=1&en=e_cr&pl=jdk&sdk=java`
        - 参数：orderId(订单ID，字符串必填)、memberId(会员ID，字符串必填)
- 集成方式：直接将java的sdk引入到项目中即可，或者添加到classpath中
- 数据参数说明

| 参数名称 | 类型   | 描述                          |
| -------- | ------ | ----------------------------- |
| en       | string | 事件名称, eg: e_cs            |
| ver      | string | 版本号, eg: 0.0.1             |
| pl       | string | 平台, eg: website,javaweb,php |
| sdk      | string | Sdk类型, eg: java             |
| u_mid    | string | 会员id，和业务系统一致        |
| c_time   | string | 客户端时间                    |
| oid      | string | 订单id                        |

## Nginx接受日志请求

- nginx.conf

```bash
http {
    # 设置日志格式，方便后续提取(^A为分隔符，需要手动按键Ctrl+V+A进行输入)。msec: 当前时间，单位是秒，精度是毫秒
    log_format bigdata_format '$remote_addr^A$msec^A$http_host^A$request_uri';

    server {
        # 访问 http://node01/bigdata-tracker.png?id=123 打印的日志如 192.168.6.11628333945.269node01/bigdata-tracker.png?id=123 (其中的分割符不可见)
        location = /bigdata-tracker.png {
            default_type image/png;
            access_log /opt/data/access.log bigdata_format;
        }
    }
}
```

## Flume传输日志

- Flume参考[bigdata-tools.md#Flume](/_posts/bigdata/bigdata-tools.md#Flume)
- 项目Flume配置文件`user-analysis.conf`，此处选择直接写入到HDFS，还可以写入Hive/Hbase

```bash
# Name the components on this agent
a1.sources = r1
a1.sinks = k1
a1.channels = c1

# 监听本地nginx日志文件access.log
# -F：等同于 –follow=name --retry，根据文件名进行追踪，并保持重试，即该文件被删除或改名后，如果再次创建相同的文件名，会继续追踪
a1.sources.r1.type = exec
a1.sources.r1.command = tail -F /opt/data/access.log

# 将数据保存到HDFS，需要配置 HADOOP_HOME 环境变量，即需在HDFS节点上启动Agent
# 参考 https://flume.liyifeng.org/#hdfs-sink
a1.sinks.k1.type = hdfs
a1.sinks.k1.hdfs.path = /project/%Y%m%d
a1.sinks.k1.hdfs.filePrefix = log-
a1.sinks.k1.hdfs.rollInterval = 0
a1.sinks.k1.hdfs.rollSize = 10240
a1.sinks.k1.hdfs.rollCount = 0
a1.sinks.k1.hdfs.idleTimeout = 30
a1.sinks.k1.hdfs.fileType = DataStream
a1.sinks.k1.hdfs.callTimeout = 60000
a1.sinks.k1.hdfs.useLocalTimeStamp = true

# Use a channel which buffers events in memory
a1.channels.c1.type = memory
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100

# Bind the source and sink to the channel
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```
- 启动`flume-ng agent --conf-file ~/flume/user-analysis.conf --name a1 -Dflume.root.logger=INFO,console`
- 在日志收集系统触发日志生成，会产生如 /project/20210808/log-.1628394865013 的数据文件
    - 启动`hadoop_project_log_source`模块，参考smjava代码
    - 访问`http://localhost:8080/hadoop_project_log_source/`进入页面进行事件触发

## ETL-MR数据清洗

- `ETL`(Extract-Transform-Load，抽取-转换-存储）即在数据抽取过程中进行数据的加工转换，然后加载到存储中。常见的如Informatics和开源工具Kettle，当然也可直接使用MapReduce进行清洗。此案例为巩固理解MR原理，因此选用MR进行清洗



















