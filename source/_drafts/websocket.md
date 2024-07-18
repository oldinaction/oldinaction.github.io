---
layout: "post"
title: "WebSocket"
date: "2023-03-25 07:42"
categories: [arch]
tags: WebSocket
---

## 简介

- 与SSE的区别参考[SSE](/_posts/arch/sse.md)
- [测试工具(本地也支持)](http://wstool.js.org/)
    - 如连接`ws://127.0.0.1:8080/api/1`
- `WS`（WebSocket ）是不安全的 ，容易被窃听，因为任何人只要知道你的ip和端口，任何人都可以去连接通讯
- `WSS`（Web Socket Secure）是WebSocket的加密版本。即WebSocket + Https
- JS客户端
    - 直接使用WebSocket类
    - [ws](https://github.com/websockets/ws)
    - [sockjs-client](https://github.com/sockjs/sockjs-client) sockjs旗下还有对应的服务端

## 基于WebSocket类封装JS客户端

- [node + vue](https://blog.csdn.net/weixin_46758988/article/details/127646256)
- https://blog.csdn.net/nbaqq2010/article/details/108992288

## 整合SpringBoot

- 引入依赖 [^11]

    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-websocket</artifactId>
    </dependency>
    ```
- 后端代码

```java
// 1.WebSocketConfig.java 配置文件
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig extends AbstractWebSocketMessageBrokerConfigurer {
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/user"); // 表示客户端订阅地址的前缀信息，也就是客户端接收服务端消息的地址的前缀信息
        config.setApplicationDestinationPrefixes("/app"); // 定义websocket前缀，指服务端接收地址的前缀，意思就是说客户端给服务端发消息的地址的前缀
        config.setUserDestinationPrefix("/user"); // 定义一对一(点对点)推送前缀，默认是`/user`，可省略此配置
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/aezo") // 定义stomp端点，供客户端使用
                .setAllowedOrigins("*")
                .withSockJS(); // 开启SockJS支持
    }
}

// 2.@Controller
@Autowired
private SimpMessagingTemplate simpMessagingTemplate; // Spring-WebSocket内置的一个消息发送工具，可以将消息发送到指定的客户端或所有客户端

@GetMapping("/")
public String index() {
    return "index";
}

// ==== Message
// 功能类似@RequestMapping，定义消息的基本请求(客户端发送消息)。拼上定义的客户端请求的前缀/app，最终客户端请求为/app/send
@MessageMapping("/send")
// @SendTo发送消息给所有人，@SendToUser只能推送给请求消息的那个人
@SendTo("/topic/send")
public Message send(Message message) throws Exception { // Message为一个VO(不写getter/setter也行)
    DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    message.date = df.format(new Date());
    if(message.toUser != null && !"".equals(message.toUser)) {
        // 给某个人发送消息，此时@SendTo被忽略
        // convertAndSend(destination, payload); //将消息广播到特定订阅路径中，类似@SendTo
        // convertAndSendToUser(user, destination, payload); //将消息推送到固定的用户订阅路径中，类似@SendToUser
        simpMessagingTemplate.convertAndSendToUser(message.toUser, "/private", message); // 发送到/user/${message.toUser}/private通道
        return null;
    } else {
        return message;
    }
}

// 定时1秒执行执行一次，向/topic/callback通道发送信息
@Scheduled(fixedRate = 1000) // 加@EnableScheduling开启定时
@SendTo("/topic/callback")
public Object callback() throws Exception {
    DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    simpMessagingTemplate.convertAndSend("/topic/callback", df.format(new Date()));
    return "callback"; // 此处返回什么不重要
}
```
- 前端代码(基于sockjs + stomp实现websocket)

```html
<!-- 基于angular.js -->
<script src="//cdn.bootcss.com/angular.js/1.5.6/angular.min.js"></script>

<!-- websocket所需js库 -->
<script src="https://cdn.bootcss.com/sockjs-client/1.1.4/sockjs.min.js"></script>
<script src="https://cdn.bootcss.com/stomp.js/2.3.3/stomp.min.js"></script>
<script type="text/javascript">
var stompClient = null;
var app = angular.module('app', []);
app.controller('MainController', function($rootScope, $scope, $http) {
	$scope.data = {
		username: '', // 用户名
		toUser: '',
		connected : false, //连接状态
		message : '', //消息
		rows : [] // 消息历史
	};

	//连接
	$scope.connect = function() {
		var socket = new SockJS('/ws/aezo'); // websocket后台定义的stomp端点
		stompClient = Stomp.over(socket);
		stompClient.connect({}, function(frame) {
			// 注册接收服务端topic消息
			stompClient.subscribe('/topic/send', function(msg) {
				$scope.data.rows.push(JSON.parse(msg.body));
				$scope.data.connected = true;
				$scope.$apply();
			});
			// 注册接收服务端topic消息
			stompClient.subscribe('/topic/callback', function(r) {
				$scope.data.time = '当前服务器时间：' + r.body;
				$scope.data.connected = true;
				$scope.$apply();
			});
			// 注册接手服务端点对点消息(私信)
			stompClient.subscribe('/user/'+ $scope.data.username +'/private', function(msg) {
				$scope.data.rows.push(JSON.parse(msg.body));
				$scope.data.connected = true;
				$scope.$apply();
			});

			$scope.data.connected = true;
			$scope.$apply();
		});
	};

	// 断开连接
	$scope.disconnect = function() {
		if (stompClient != null) {
			stompClient.disconnect();
		}
		$scope.data.connected = false;
	}

	// 给服务端发送消息
	$scope.send = function() {
		stompClient.send("/app/send", {}, JSON.stringify({
			'toUser': $scope.data.toUser,
			'message': $scope.data.message
		}));
	}
});
</script>
```

## STOMP

- https://stomp.github.io/index.html
- https://github.com/stomp-js/stompjs
- https://github.com/jmesnil/stomp-websocket

- https://zhuanlan.zhihu.com/p/378939100
- https://my.oschina.net/feinik/blog/853875


