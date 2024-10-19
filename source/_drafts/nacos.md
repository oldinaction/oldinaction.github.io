---
layout: "post"
title: "Nacos"
date: "2024-08-02 18:17"
categories: arch
tags: [微服务]
---

## 简介

- Nacos /nɑ:kəʊs/ 是 Dynamic Naming and Configuration Service的首字母简称，一个更易于构建云原生应用的动态服务发现、配置管理和服务管理平台
- [官网](https://nacos.io/)

## 安装

- 官网安装参考: https://nacos.io/docs/latest/quickstart/quick-start/ 支持Docker快速安装
- 安装后可访问`http://127.0.0.1:8848/nacos/`控制台，默认账号密码: nacos/nacos

## 客户端接入

- 基于SDK接入参考: https://nacos.io/docs/latest/manual/user/java-sdk/usage/
- 接入API接口接入参考: https://nacos.io/docs/latest/manual/user/open-api/
 
### 基于SDK手动注册实例

**SpringBoot手动接入**

```java
// 可以使用其服务发现功能进行配置后自动注册，参考(当前版本未测试)：https://nacos.io/docs/v1/quick-start-spring-boot/#%E5%90%AF%E5%8A%A8%E6%9C%8D%E5%8A%A1%E5%8F%91%E7%8E%B0
@Component
public class NacosDiscoveryAutoRegister implements ApplicationListener<EmbeddedServletContainerInitializedEvent> {

    @SneakyThrows
    @Override
    public void onApplicationEvent(EmbeddedServletContainerInitializedEvent event) {
        // Tomcat启动，执行注册，参考下文ofbiz
        Integer port = event.getSource().getPort();
        // ...
    }
}
```

**以OFBiz接入为例**

- 引入jar包

```bash
# framework/base/lib/nacos
nacos-api-1.4.2.jar
nacos-client-1.4.2.jar
nacos-common-1.4.2.jar

jackson-annotations-2.12.2.jar
jackson-core-2.12.2.jar
jackson-databind-2.12.2.jar
simpleclient-0.5.0.jar
```
- 注册实例

```java
public class CatalinaContainer implements Container {

    // ...
    // 启动tomcat容器
    public boolean start() throws ContainerException {
        // Start the Tomcat server
        try {
            tomcat.getServer().start();
        } catch (LifecycleException e) {
            throw new ContainerException(e);
        }
        // ...

        // 注册nacos实例
        NacosClient.registerInstance();
        Debug.logInfo("Started NacosClient", module);
        
        return true;
    }
}
```
- NacosClient.java

```java
public class NacosClient {
    private static final String serviceName = UtilProperties.getPropertyValue(
            "nacos.properties", "nacos.serviceName"); // test.demo1
    private static final String serverAddr = UtilProperties.getPropertyValue(
            "nacos.properties", "nacos.serverAddr"); // 192.168.1.100:8848,192.168.1.100:8849,192.168.1.100:8850
    private static final Integer portHttp = UtilProperties.getPropertyAsInteger(
            "url.properties", "port.http", 8080);
    private static String innetIp = null;

    public static void registerInstance() throws NacosException, SocketException {
        Properties properties = new Properties();
        properties.put(PropertyKeyConst.SERVER_ADDR, serverAddr);
        //properties.put(PropertyKeyConst.USERNAME, "nacos");
        //properties.put(PropertyKeyConst.PASSWORD, "nacos");

        Instance instance = new Instance();
        innetIp = getInnetIp();
        instance.setIp(innetIp); // 当前客户端IP
        instance.setPort(portHttp); // 当前客户端监听端口
        instance.setEphemeral(false);
        Map<String, String> map = new HashMap<String, String>();
        instance.setMetadata(map);

        NamingService namingService = NacosFactory.createNamingService(properties);
        namingService.registerInstance(serviceName, instance);

        startBeatCheck(properties);
    }

    public static void startBeatCheck(Properties properties) {
        BeatInfo beatInfo = new BeatInfo();
        beatInfo.setServiceName(serviceName);
        beatInfo.setIp(innetIp);
        beatInfo.setPort(portHttp);
        beatInfo.setScheduled(false);
        beatInfo.setPeriod(3000L);

        NamingProxy namingProxy = new NamingProxy(null, null, serverAddr, properties);

        BeatReactor beatReactor = new BeatReactor(namingProxy);
        beatReactor.addBeatInfo(serviceName, beatInfo);
    }

    public static String getInnetIp() throws SocketException {
        String localip = null;// 本地IP，如果没有配置外网IP则返回它
        String netip = null;// 外网IP
        Enumeration<NetworkInterface> netInterfaces;
        netInterfaces = NetworkInterface.getNetworkInterfaces();
        InetAddress ip = null;
        boolean finded = false;// 是否找到外网IP
        while (netInterfaces.hasMoreElements() && !finded) {
            NetworkInterface ni = netInterfaces.nextElement();
            Enumeration<InetAddress> address = ni.getInetAddresses();
            while (address.hasMoreElements()) {
                ip = address.nextElement();
                if (!ip.isSiteLocalAddress()
                        &&!ip.isLoopbackAddress()
                        &&ip.getHostAddress().indexOf(":") == -1){// 外网IP
                    netip = ip.getHostAddress();
                    finded = true;
                    break;
                } else if (ip.isSiteLocalAddress()
                        &&!ip.isLoopbackAddress()
                        &&ip.getHostAddress().indexOf(":") == -1){// 内网IP
                    localip = ip.getHostAddress();
                }
            }
        }
        if (netip != null && !"".equals(netip)) {
            return netip;
        } else {
            return localip;
        }
    }
}
```

