---
layout: "post"
title: "Prometheus"
date: "2019-09-19 15:27"
categories: devops
tag: [monitor, cncf]
---

## 简介

- [Prometheus](https://prometheus.io/)(普罗米修斯)、[Docs](https://prometheus.io/docs/introduction/overview/)
    - 是一套开源的系统监控报警框架。现在已加入 Cloud Native Computing Foundation(CNCF)，成为受欢迎度仅次于 Kubernetes 的项目
- Prometheus可基于如node_exporter进行监控，并提供PromQL查询语句来展示监控状态，但是PromQL不支持API server，因此中间可使用插件k8s-prometheus-adpater来执行API server的命令，并转成PromQL语句执行
- 架构 [^1]

    ![Prometheus](/data/images/devops/Prometheus.png)
    - `Prometheus Server` 主要用于抓取数据和存储时序数据，另外还提供查询和 Alert Rule 配置管理
    - `Client Libraries` 客户端库，为需要监控的服务生成相应的 metrics 并暴露给 Prometheus server。当 Prometheus server 来 pull 时，直接返回实时状态的 metrics
    - `Push Gateway` 推送网关，短期的监控数据的汇总节点。主要用于业务数据汇报等，此类数据存在时间可能不够长，Prometheus采集数据是用的pull也就是拉模型(如5秒钟拉取一次数据)，导致此类数据无法抓取到，因此可以将他们推送到网关中，此时网关相当于一个缓存，之后仍然由Prometheus Server定期到Push Gateway上拉取数据
    - `Exporters` 进行各种数据汇报，例如汇报机器数据的 `node exporter`，汇报 MongoDB 信息的 `MongoDB exporter` 等等
    - `Alertmanager` 从 Prometheus server 端接收到 alerts 后，会进行去除重复数据，分组，并路由到对收的接受方式，发出报警。支持电子邮件、slack、pagerduty，hitchat，webhook、钉钉等
- Prometheus工作说明
    - Prometheus需要的metrics，要么程序定义输出(模块或者自定义开发)；要么用官方的各种exporter(node-exporter，mysqld-exporter，memcached_exporter…)采集要监控的信息，占用一个web端口然后输出成metrics格式的信息
    - prometheus server去收集各个target的metrics存储起来(存储在TSDB时序数据库中)
    - 用户可以在prometheus的http页面上用promQL(prometheus的查询语言)或者(grafana数据来源就是用)api去查询一些信息，也可以利用pushgateway去统一采集，然后prometheus从pushgateway采集(所以pushgateway类似于zabbix的proxy)
- 相关概念
    - Prometheus 中存储的数据为时间序列，是由 metric 的名字和一系列的标签（键值对）唯一标识的，不同的标签则代表不同的时间序列。metric 名字格式：`<metric name>{<label name>=<label value>, …}`，例如：`http_requests_total{method="POST",endpoint="/api/tracks"}`

## 安装

### 基于docker安装

#### Prometheus Server 安装

- 安装命令 [^3]

```bash
cd /home/smalle/prom/prometheus
# 创建 prometheus.yml 配置文件，见下文。其中 rules.yml 规则配置，见下文alertmanager安装部分，未安装alertmanager不会影响Prometheus的启动
## 启动容器
# 启动时加上--web.enable-lifecycle启用远程热加载配置文件，调用指令是`curl -X POST http://192.168.6.131:9090/-/reload`
docker run -d -p 9090:9090 \
            -v $PWD/prometheus.yml:/etc/prometheus/prometheus.yml \
            -v $PWD/rules.yml:/etc/prometheus/rules.yml \
            --name prometheus \
            prom/prometheus:v2.11.1 \
            --config.file=/etc/prometheus/prometheus.yml \
            --web.enable-lifecycle
## 测试访问
# 访问 http://192.168.6.131:9090 进入web界面
# 访问 http://192.168.6.131:9090/metrics 查看Prometheus Server自身的metrics信息，默认prometheus会抓取自己的/metrics接口数据
# 访问 http://192.168.6.131:9090/targets 显示所有被抓取metrics信息的目标即其状态
# 选择metric名`up`，并点击`Execute`查看metric信息
```
- prometheus.yml(/home/smalle/prom/prometheus 目录)

```yml
# 参考：https://prometheus.io/docs/prometheus/latest/configuration/configuration/
# 全局设置，可以被覆盖
global:
  # 默认值为 15s，用于设置每次数据收集的间隔
  scrape_interval: 15s
  # 所有时间序列和警告与外部通信时用的外部标签
  external_labels:
    monitor: 'sq-monitor'
# 这里表示抓取对象的配置
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  # 需要全局唯一，采集 Prometheus 自身的 metrics
  - job_name: 'prometheus'
    # 覆盖全局的 scrape_interval
    scrape_interval: 5s
    # 静态目标的配置
    static_configs:
      # 本机 Prometheus 的 endpoint
      - targets: ['192.168.6.131:9090']
      # pushgateway节点(可见下文安装pushgateway)
      - targets: ['192.168.6.131:9091']
        labels:
          group: 'pushgateway'
  # 需要全局唯一，采集本机的 metrics，需要在本机安装 node_exporter(用于上报服务器性能信息)，见下文（未安装也可正常启动server）
  - job_name: 'node'
    scrape_interval: 10s
    static_configs:
      - targets: ['192.168.6.131:9100']  # 客户端(此时为本机) node_exporter 的 endpoint
    # 重命名标签。参考：https://www.li-rui.top/2019/04/16/monitor/Prometheus%E4%B8%ADrelabel_configs%E7%9A%84%E4%BD%BF%E7%94%A8/
    # relabel_configs:
# 警告规则设置文件，需要安装Alertmanager，见下文。如使用Grafana告警则不需要
rule_files:
  - '/etc/prometheus/rules.yml'
  #- '/etc/prometheus/rules2.yml'
# alertmanager配置，需要安装alertmanager，见下文，可选
alerting:
  alertmanagers:
    - static_configs:
      # alertmanager服务监听地址
      - targets: ['192.168.6.131:9093']
```
- rules.yml(/home/smalle/prom/prometheus 目录) 报警规则配置(需要配合Alertmanager使用，如使用Grafana告警则不需要)

```yml
groups:
  - name: my-alert
    rules:
      # alert 名字
      - alert: Instance Memory Abnormal Alert
        # 判断条件
        # expr: up == 0 # 服务器宕机
        expr: (node_memory_MemTotal_bytes - (node_memory_MemFree_bytes+node_memory_Buffers_bytes+node_memory_Cached_bytes )) / node_memory_MemTotal_bytes * 100 > 80 # 内存占用超过80
        # 条件保持 1m 才会触发alert
        for: 1m
        # 指标匹配此标签才触发alert
        labels:
          severity: critical
        annotations:
          # $labels 可获取上文定义的一些labels和job/export加入的labels
          summary: "{{$labels.instance}}: High Memory usage detected"
          description: "详细异常. {{$labels.instance}}: Memory usage is above 80% (current value is:{{ $value }})"
```

#### Alertmanager 安装

- 安装(**如使用Grafana告警则不需要安装，但是Grafana告警比较有限**)

```bash
cd /home/smalle/prom/alertmanager
# 创建 alertmanager.yml 配置文件
# 启动容器
docker run -d -p 9093:9093 -v $PWD/alertmanager.yml:/etc/alertmanager/alertmanager.yml --name alertmanager prom/alertmanager
# 访问 http://192.168.6.131:9093/#/status 可以查看配置和服务状态
```
- alertmanager.yml

```yml
global:
  resolve_timeout: 5m
  # 配置邮箱发送服务器(基于邮箱报警才需要)
  smtp_smarthost: 'smtp.163.com:25'
  smtp_from: 'aezocn@163.com'
  smtp_auth_username: 'aezocn@163.com'
  smtp_auth_password: 'XXX' # 需要填写邮箱的授权码，而不是邮箱密码
route:
  # 将多个标签的报警合并成一个(如一份邮件)
  # group_by: [cluster, alertname]
  # 默认接收者 default-receiver
  receiver: 'email-receiver'
  # 组报警等待时间
  group_wait: 30s
  # 组报警间隔时间
  group_interval: 1m
  # 组重复报警间隔时间
  repeat_interval: 15m
  # 与以下子路线不匹配的所有警报将保留在根节点上，并分派给'default-receiver'。如果匹配到一个路由，则不再往下匹配
  routes:
  # 匹配 alert 标签和接受者
  # - match_re: #基于正则匹配
  - match:
      severity: critical
      team: frontend
    receiver: frontend-receiver
    # group_by: [product, environment] # 覆盖默认的集群分组为基于产品和环境分区
receivers:
# 基于email进行报警
- name: 'email-receiver'
  email_configs:
  - to: 'aezocn@163.com'
    # html: '{{ template "email.default.html" . }}' # 默认模板
# 基于 webhook 进行报警：出问题后自动访问下列地址
- name: 'frontend-receiver'
  webhook_configs:
  - url: 'http://192.168.6.131:8080/restart'
# 基于 Slack (类似在线聊天室) 进行报警，具体参考：https://api.slack.com/incoming-webhooks (进入到 Your Apps > incoming-webhooks 中查看Webhook URL)
- name: 'slack-receiver'
  slack_configs:
  - send_resolved: true
    # 在 https://api.slack.com/apps/TN511J342/incoming-webhooks 中查看地址
    api_url: https://hooks.slack.com/services/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
    channel: 'monitor'
    # 参考 https://prometheus.io/docs/alerting/configuration/#webhook_config (注意首字母大写)
    text: "{{ .CommonAnnotations.description }}"
    # 存在多个异常。`:small_orange_diamond:`为slack表情代码
    #text: "{{ range .Alerts }}:small_orange_diamond:{{ .Annotations.summary }}。{{ .Annotations.description }}\n\n{{ end }}"
```

#### Push Gateway 安装

- 安装及使用

```bash
## 安装
mkdir -p /home/smalle/prom/pushgateway
cd !$
docker run -d -p 9091:9091 --name pushgateway prom/pushgateway
# 访问 http://192.168.6.131:9091

## 测试推送。prometheus提供了多种语言的sdk，最简单的方式就是通过shell
# 推送一个指标
# pushgateway 中的数据我们通常按照 job 和 instance 分组分类。此时无需server中定义此job(指标)，会自动创建此aezo对应的job
echo "aezo_metric 100" | curl --data-binary @- http://192.168.6.131:9091/metrics/job/aezo # aezo_metric{instance="",job="aezo"} 100
# 推送多个指标. smalle_metric{instance="test",job="aezo",label="hello"} 120
cat <<EOF | curl --data-binary @- http://192.168.6.131:9091/metrics/job/aezo/instance/node1
# 每次推送的key不能相同
# TYPE smalle_metric counter
smalle_metric{label="hello"} 120
# TYPE aezo_test1 counter
aezo_test1 100
# TYPE aezo_test2 counter
aezo_test2 110
# TYPE aezo_test3 counter
aezo_test3 120
EOF
# 删除某个组下的某实例的所有数据
curl -X DELETE http://192.168.6.131:9091/metrics/job/aezo/instance/node1
```
- server配置中需要添加pull拉取pushgateway节点任务
- 存在认证问题。直接推送到pushgateway路径`http://192.168.6.131:9091/metrics/job/<my_job>/instance/<my_instance>`(my_instance如hostname或ip)，然后server根据my_job和my_instance进行记录，server无需其他额外配置

### 基于prometheus-operator安装prometheus(k8s环境)

- [基于Helm安装(推荐)](/_posts/devops/helm.md#Prometheus)
- [prometheus-operator](https://github.com/coreos/prometheus-operator) [^2]
    - `Prometheus-operator`的本职就是一组用户自定义的CRD资源以及Controller的实现，Prometheus Operator这个controller有BRAC权限下去负责监听这些自定义资源的变化。相关CRD说明
        - `Prometheus`：由 Operator 依据一个自定义资源kind: Prometheus类型中，所描述的内容而部署的 Prometheus Server 集群，可以将这个自定义资源看作是一种特别用来管理Prometheus Server的StatefulSets资源
        - `ServiceMonitor`：一个Kubernetes自定义资源(和kind: Prometheus一样是CRD)，该资源描述了Prometheus Server的Target列表，Operator 会监听这个资源的变化来动态的更新Prometheus Server的Scrape targets并让prometheus server去reload配置(prometheus有对应reload的http接口/-/reload)。而该资源主要通过Selector来依据 Labels 选取对应的Service的endpoints，并让 Prometheus Server 通过 Service 进行拉取（拉）指标资料(也就是metrics信息)，metrics信息要在http的url输出符合metrics格式的信息，ServiceMonitor也可以定义目标的metrics的url
        - `Alertmanager`：Prometheus Operator 不只是提供 Prometheus Server 管理与部署，也包含了 AlertManager，并且一样通过一个 kind: Alertmanager 自定义资源来描述信息，再由 Operator 依据描述内容部署 Alertmanager 集群
        - `PrometheusRule`：对于Prometheus而言，在原生的管理方式上，我们需要手动创建Prometheus的告警文件，并且通过在Prometheus配置中声明式的加载。而在Prometheus Operator模式中，告警规则也编程一个通过Kubernetes API 声明式创建的一个资源.告警规则创建成功后，通过在Prometheus中使用想servicemonitor那样用ruleSelector通过label匹配选择需要关联的PrometheusRule即可
        - 注：安装下文安装完成后可通过`kubectl get APIService | grep monitor`看到新增了`v1.monitoring.coreos.com`的APIService，通过`kubectl get crd`查看相应的CRD
- 基于prometheus-operator安装Prometheus

```bash
# 下载 https://github.com/coreos/kube-prometheus/releases/tag/v0.1.0 中的 manifests 目录下所有文件
wget https://github.com/coreos/kube-prometheus/archive/v0.1.0.tar.gz
tar -zxvf v0.1.0.tar.gz
cd kube-prometheus-0.1.0/prometheus/manifests
# 修改镜像
grep 'image: k8s.gcr.io' *
sed -i 's/image: k8s.gcr.io/image: registry.aliyuncs.com\/google_containers/g' *
# 安装所有CRD
kubectl create -f .

# 检测是否创建
until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com ; do date; sleep 1; echo ""; done
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
# 有时可能需要多执行几次
kubectl apply -f . # This command sometimes may need to be done twice (to workaround a race condition).
# 查看状态
kubectl -n monitoring get all
```
- 基于下列Ingress配置暴露服务到Ingress Controller。访问`http://grafana.aezocn.local/`，默认用户密码`admin/admin`即可进入Grafana界面
- 可从[Grafana模板中心](https://grafana.com/grafana/dashboards)下载模板对应的json文件，并导入到Grafana的模板中

```yml
# prometheus-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prometheus-ing
  namespace: monitoring
spec:
  rules:
  - host: prometheus.aezocn.local
    http:
      paths:
      - backend:
          serviceName: prometheus-k8s
          servicePort: 9090
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: grafana-ing
  namespace: monitoring
spec:
  rules:
  - host: grafana.aezocn.local
    http:
      paths:
      - backend:
          serviceName: grafana
          servicePort: 3000
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: alertmanager-ing
  namespace: monitoring
spec:
  rules:
  - host: alertmanager.aezocn.local
    http:
      paths:
      - backend:
          serviceName: alertmanager-main
          servicePort: 9093
```

## Grafana

- Prometheus数据源说明：https://grafana.com/docs/features/datasources/prometheus/
    - `label_values` 等函数，可在`Variables > Edit -> Query Options -> Query`属于表达式，在`Preview of values`中会显示表达式结果
- Dashboard
    - 模板参考：https://grafana.com/docs/reference/templating/
    - 配置Json Model参考：https://grafana.com/docs/reference/dashboard/

### Grafana安装

```bash
mkdir -p /home/smalle/prom/grafana
cd !$
docker run -d -p 3000:3000 --name grafana grafana/grafana

# 访问 http://192.168.6.131:3000，登录 admin/admin
```
- 配置参考：http://docs.grafana.org/installation/configuration/

### 基本使用

- 选择数据源：Configuration - Data Sources - Add data sources - Time series databases选择Prometheus
- 配置数据源：Data Sources/Prometheus/Settings - HTTP输入 http://192.168.6.131:9090 (Prometheus Server地址，或者如http://prometheus-server.monitoring.svc.cluster.local) - Save & Test
- 选择图表：Data Sources/Prometheus/Dashboards - Import一个图表(如Prometheus 2.0 Stats) - 选择Prometheus Stats - 即可看到图表展示
- 可从[Grafana模板中心](https://grafana.com/grafana/dashboards)下载模板对应的json文件，并导入到Grafana的模板中
    - Prometheus数据源推荐模板
        - Kubernetes相关：`8588`(可选择deploy/node进行统计CPU和内存)、`7249`(汇总所有的节点统计CPU和内存)
        - Node Exporter相关：`8919`、`1860`(选择某一个节点，分类展示系统信息)
        - Blackbox Exporter：9965
- 插件安装
    - 安装后需要重启grafana服务，k8s-helm安装的pod重新创建后插件和Dashboard还在(已经持久化到磁盘)
    - `grafana-cli plugins install grafana-piechart-panel` 安装`Pie Chart`插件

### 自定义图表

- Create - Dashboard - New Panel(新建一个图表) - Add Query
- Query查询配置：选择数据源Prometheus
    - 选择Metrics指标(所有metrics根据命名的第一个_进行分类)
    - Legend为指标说明(标题)
    - 可Add Query继续增加指标
- Visualization可视化配置
- General基本配置
    - Title设置图标标题
- Alerting告警配置
    - 如果某图表使用模板变量，则该图表不能配置告警(单独配置个告警的视图，用正则匹配出所有的主机或者每台主机单独一个查询语句)；告警只支持graph的图表
- 右上角保存Save Dashboard

### 告警插件(默认安装)

- Grafana是基于图标进行告警，Alertmanager则没有此限制，可同时使用
- Alerting/Alert Rules 查看告警规则，新增需要在每个Panel的设置中进行
- Notification channels 设置告警通道，可使用Email(可以定义多个邮件通道)、webhook、Slack、钉钉(DingDing)等
    - 使用邮件通道时，需提前配置邮件发送服务器
    - Slack配置(参考上文Alertmanager)
        - Url填写slack应用对应地址
        - Recipient为slack通道，如`#monitor`

## Exporter

- [官方推荐的Exporter](https://prometheus.io/docs/instrumenting/exporters/)
- 与Prometheus服务端安装无关，**一般由被监控的客户端安装**。此处仅为了演示exporter如何输出metrics格式的信息，并由Prometheus Server采集
- 需要Server到Exporter节点Pull(因此Exporter节点对应端口需对外开放)
- 采集参考[采集文本说明](#采集文本说明)，客户端(Exporter)需要按照一定的格式上报metric

### node_exporter (官方)

- [node_exporter](https://github.com/prometheus/node_exporter) 主要采集节点系统性能指标(cpu/mem/disk)并提供查询
- 手动安装(配合自动重启)
    - 快速安装 `bash <(curl -L https://raw.githubusercontent.com/oldinaction/scripts/master/shell/prod/install-prometheus-node_export.sh) 2>&1 | tee my.log`
    - 安装步骤

        ```bash
        wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
        tar -xvzf node_exporter-0.18.1.linux-amd64.tar.gz # 只有一个node_exporter的可执行程序
        mv node_exporter-0.18.1.linux-amd64/node_exporter /usr/sbin/node_exporter # 可删除下载文件
        # 启动服务，默认监听9100端口，正式环境可自定义成服务后台运行。`./node_exporter -h` 查看参数设置
        /usr/sbin/node_exporter
        # 查看metrics信息
        curl http://localhost:9100/metrics
        ```
    - 自动重启，参考[Supervisor](/_posts/linux/CentOS服务器使用说明.md#Supervisor%20进程管理)
    - 在prometheus中添加此Exporter的爬取配置
- 如果Node Exporter处于防火墙中，则server无法爬取。此时只能push推送到PushGateway，临时解决方案如
    - 通过 cronjob 每分钟(类似server拉取频率)执行脚本 `curl -s http://localhost:9100/metrics | curl --data-binary @- http://pushgateway.example.org/metrics/job/some_job/instance/some_instance` [^5]
- 基于docker安装

```bash
docker run -d --name=node-exporter -p 9100:9100 prom/node-exporter
curl http://localhost:9100/metrics
```

### blackbox_exporter (官方)

- [blackbox_exporter](https://github.com/prometheus/blackbox_exporter) 可以提供 `http`、`tcp`、`icmp`、`dns` 的监控数据采集。应用场景
    - HTTP 测试
        - 定义 Request Header 信息
        - 判断 Http status / Http Respones Header / Http Body 内容
    - TCP 测试
        - 业务组件端口状态监听
        - 应用层协议定义与监听
    - ICMP 测试
        - 主机探活机制
    - POST 测试
        - 接口联通性
    - SSL 证书过期时间
- 安装

```bash
## 安装
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.16.0/blackbox_exporter-0.16.0.linux-amd64.tar.gz
tar -xvzf blackbox_exporter-0.16.0.linux-amd64.tar.gz

mv blackbox_exporter-0.16.0.linux-amd64/blackbox_exporter /usr/sbin/blackbox_exporter
# blackbox.yml源文件参考：https://github.com/prometheus/blackbox_exporter/blob/master/blackbox.yml
# blackbox.yml配置参考：https://github.com/prometheus/blackbox_exporter/blob/master/CONFIGURATION.md
mv blackbox_exporter-0.16.0.linux-amd64/blackbox.yml /etc/blackbox.yml
# blackbox.yml中增属性 `modules.http_2xx.timeout: 10s` 默认5s
# blackbox.yml中增属性 `modules.http_2xx.http.preferred_ip_protocol: "ip4"` 开启ipv4(默认是ip6)

## 启动(参考上文Supervisor进程监控)
cat > /etc/supervisord.d/blackbox_exporter.ini << EOF
[program:blackbox_exporter]
command=/usr/sbin/blackbox_exporter --config.file=/etc/blackbox.yml
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/blackbox_exporter.log
log_stderr=true
user=root
EOF
supervisorctl update && supervisorctl status
```
- 在prometheus中添加此Exporter的爬取配置

```yml
## HTTP 监控
scrape_configs:
  - job_name: 'blackbox_http_2xx'
    scrape_interval: 30s
    # 将metrics_path由默认的/metrics改为/probe
    metrics_path: /probe
    params:
      # 生成__param_module="http_2xx"的label
      module: [http_2xx]
    static_configs:
      - targets:
        - https://www.baidu.com/
        - 172.0.0.1:9090
```


## 采集和PromQL查询

### 样本、指标 [^4]

- Prometheus会将所有采集到的样本数据以时间序列(time-series)的方式保存在内存数据库中，并且定时保存到硬盘上。time-series是按照时间戳和值的序列顺序存放的，称之为向量(vector)。每条time-series通过指标名称(metrics name)和一组标签集(labelset)命名
- 在time-series中的每一个点称为一个样本(sample)，样本由以下三部分组成
    - 指标(metric)：metric name和描述当前样本特征的labelsets
    - 时间戳(timestamp)：一个精确到毫秒的时间戳
    - 样本值(value)： 一个float64的浮点型数据表示当前样本的值
- 指标(Metric)格式如 `metric_name [ {label_name1="label_value1",label_name2=label_value2} ] value [ timestamp ]`
    - `api_http_requests_total{method="POST", handler="/messages"}` 等同于 `{__name__="api_http_requests_total", method="POST", handler="/messages"}`

### 采集文本说明

- 客户端(Exporter)需要按照一定的格式上报metric
- Exporter 收集的数据转化的文本内容以行 `\n` 为单位，空行将被忽略
    - 如果以 `#` 开头通常表示注释，不以 `#` 开头，表示采样数据
    - 以 `# HELP` 开头表示 metric 帮助说明
    - 以 `# TYPE` 开头表示定义 metric 类型，包含 `counter`, `gauge`, `histogram`, `summary`, 和 `untyped`(默认) 类型
    - 其他`#`开头认为是普通注释
- 采样数据格式
    - `metric_name [ {label_name1="label_value1",label_name2=label_value2} ] value [ timestamp ]`
    - 其中metric_name和label_name必须遵循PromQL的格式规范要求。value是一个float格式的数据，timestamp的类型为int64（从1970-01-01 00:00:00以来的毫秒数），timestamp为可选默认为当前时间。具有相同metric_name的样本必须按照一个组的形式排列，并且每一行必须是唯一的指标名称和标签键值对组合
- 假设采样数据 metric 叫做 `x`，且 `x` 是 histogram 或 summary 类型必需满足以下条件
    - 采样数据的总和应表示为 `x_sum`；总量应表示为 `x_count`
    - summary 类型的采样数据的 quantile 应表示为 `x{quantile="y"}`
    - histogram 类型的采样分区统计数据将表示为 `x_bucket{le="y"}`；必须包含 `x_bucket{le="+Inf"}`， 它的值等于 `x_count` 的值
    - summary 和 historam 中 quantile 和 le 必需按从小到大顺序排列

### PromQL查询

- PromQL查询语法 https://prometheus.io/docs/prometheus/latest/querying/basics/
- PromQL示例 [^4]

```bash
## 查询时间序列。瞬时向量表达式(查询的最新数据)
# 查询所有http_requests_total(metric_name名称)时间序列中
http_requests_total # 等价于 `http_requests_total{}`
# 完全匹配模式。查询所有http_requests_total满足标签instance为localhost:9100的时间序列
http_requests_total{instance="localhost:9100"}
# 正则模式
http_requests_total{environment=~"staging|testing|development",method!="GET"}

## 范围查询。区间向量表达式
# 选择最近5分钟内的所有样本数据。单位：s/m/h/d/w/y
http_request_total{}[5m]

## 时间位移操作 offset
http_request_total{} # 瞬时向量表达式，选择当前最新的数据
http_request_total{}[5m] # 区间向量表达式，选择以当前时间为基准，5分钟内的数据
http_request_total{} offset 5m # 5分钟前的瞬时样本数据
http_request_total{}[1d] offset 1d # 昨天一天的区间内的样本数据

## 所有的PromQL表达式都必须至少包含一个指标名称(例如http_request_total)，或者一个不会匹配到空字符串的标签过滤器(例如{code="200"})
http_request_total # 合法
{method="get"} # 合法
{job=~".*"} # 不合法

## 内置标签。除使用`<metric_name>{label=value}`的形式以外，还可以使用内置的`__name__`标签来指定监控指标名称
{__name__=~"http_request_total"} # 合法
{__name__=~"node_disk_bytes_read|node_disk_bytes_written"} # 合法

## PromQL操作符中优先级由高到低依次为
^ # 幂运算
*, /, %
+, -
==, !=, <=, <, >=, >
and, unless # unless 排除
or

## 聚合操作
sum # 求和
min # 最小值
max # 最大值
avg # 平均值
stddev # 标准差
stdvar # 标准差异
count # 计数
count_values # 对value进行计数
topk # 前n条时序。topk和bottomk用于对样本值进行排序，返回当前样本值前n位，或者后n位的时间序列
bottomk # 后n条时序
quantile # 分布统计。用于计算当前样本数据值的分布情况quantile(φ, express)其中0 ≤ φ ≤ 1
# 示例
sum(http_request_total) # 查询系统所有http请求的总量
100 - avg (irate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100 # 按照主机计算5min为取样每秒的CPU瞬时利用率
topk(5, http_requests_total) # 获取HTTP请求数前5位的时序样本数据
quantile(0.5, http_requests_total) # 当φ为0.5时，即表示找到当前样本数据中的中位数

## without | by
# <aggr-op>([parameter,] <vector expression>) [without|by (<label list>)]
sum(http_requests_total) by (application, group) # 基于 application, group 标签对序列进行分组
sum(http_requests_total) without (instance) # 不包含 instance 标签的序列

## 内置函数
https://prometheus.io/docs/prometheus/latest/querying/functions/
```
- 常用查询

```bash
# exporter的可用性监控
up{job="kubernetes-nodes"}
# CPU利用率(按照主机)
# 5m是range vector,表示使用记录的上一个5分钟的数据；irate是瞬时变化率,适合变化较频繁的metric；avg是因为有多个metrics(分别是每核的)
100 - avg (irate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100
# CPU饱和度
count by (instance)(node_cpu_seconds_total{mode="idle"})
# 内存使用率
(node_memory_MemTotal_bytes - (node_memory_MemFree_bytes + node_memory_Cached_bytes + node_memory_Buffers_bytes)) / node_memory_MemTotal_bytes * 100
# 内存饱和度
1024 * sum by (instance) ((rate(node_vmstat_pgpgin[1m])+ rate(node_vmstat_pgpgout[1m])))
# 磁盘使用率(一个节点多个磁盘则会出现多条记录)
(node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100
```





---

参考文章

[^1]: https://jimmysong.io/kubernetes-handbook/practice/prometheus.html
[^2]: https://www.servicemesher.com/blog/prometheus-operator-manual/
[^3]: https://www.ibm.com/developerworks/cn/cloud/library/cl-lo-prometheus-getting-started-and-practice/index.html
[^4]: https://yunlzheng.gitbook.io/prometheus-book/parti-prometheus-ji-chu/promql
[^5]: https://github.com/prometheus/node_exporter/issues/279

