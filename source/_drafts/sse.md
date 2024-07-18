---
layout: "post"
title: "SSE"
date: "2024-06-29 21:21"
categories: [arch]
tags: WebSocket
---

## 简介

- SSE(Server-Sent Events)：简化的单向数据流，是一种基于 HTTP 的技术，允许「服务器向客户端单向发送数据流」，适用于不需要客户端响应的场景
    - WebSocket：全双工通信的实现，参考[WebSocket](/_posts/arch/websocket.md)
- WebSocket 与 SSE 选择
    - 「通信方式」：WebSocket 提供双向通信，适用于需要客户端和服务器间频繁交互的应用；SSE 仅支持从服务器到客户端的单向通信，适用于更新频率较低的场景
    - 「支持和兼容性」：WebSocket 需要特定的服务器和客户端支持；SSE 更容易集成到现有 HTTP 基础设施中
    - 「适用场景」：WebSocket 适合聊天应用、在线游戏等；SSE 适合新闻推送、实时通知等应用
- [OKHttp](https://github.com/square/okhttp)
    - OKHttp是处理网络请求的开源框架，Andorid当前最火热的网络框架，Retrofit的底层也是OKHttp
    - 支持SSE客户端请求

## SSE技术原理

- SSE是建立在HTTP协议之上的，所以原理比较简单，也与HTTP原理类似
    - 建立连接：关键区别是请求MIME为 `Accept: text/event-stream` 类型，告知服务器该请求是 SSE 请求
    - 服务器处理请求：服务器接收到 SSE 请求后，会在连接上保持打开状态，不会立即关闭。这是与普通的请求-响应模式的主要不同之处。服务器端通过这个持久连接向客户端发送数据
    - 数据推送：消息以文本的形式发送，并遵循一定的格式，通常以 data 字段表示消息内容。响应头为`Content-Type: text/event-stream`和`data: This is a message\n\n`
    - 客户端接收消息：EventSource#onmessage
    - 连接关闭：当服务器端不再需要向客户端推送消息时，或者发生错误时，服务器可以关闭连接。客户端也可以通过调用 eventSource.close() 来关闭连接

## SSE简单案例

- 基于springboot + okhttp进行演示
**服务端**

- 仅使用springboot即可实现

```java
@RestController
@RequestMapping("/sse")
public class SSEmitterController {
    // @GetMapping("/stream") // 此时浏览器可直接访问 http://localhost:8080/api/sse/stream，则页面会依次显示服务器推送的消息
    @PostMapping("/stream")
    public SseEmitter handleSse(@RequestBody Map<String, Object> data) {
        // 用于创建一个 SSE 连接对象 org.springframework.web.servlet.mvc.method.annotation.SseEmitter
        SseEmitter emitter = new SseEmitter();
        // 还可设置超时时间
        // SseEmitter emitter = new SseEmitter(10000L);    
        // 注册回调函数，处理服务器向客户端推送的消息
        emitter.onCompletion(() -> {
            System.out.println("Connection completed");
            // 在连接完成时执行一些清理工作
        });
        emitter.onTimeout(() -> {
            System.out.println("Connection timeout");
            // 在连接超时时执行一些处理
            emitter.complete();
        });

        // 在后台线程中模拟实时数据
        // 生产可以使用线程池来管理后台任务的执行，或者使用非阻塞IO来提高系统的吞吐量和性能
        new Thread(() -> {
            for (int i = 0; i < 10; i++) {
                try {
                    // emitter.send("hi"); 方法向客户端发送消息
                    // 使用SseEmitter.event()创建一个事件对象，设置事件名称和数据
                    emitter.send(SseEmitter.event()
                            .name("message")
                            .data("[" + new Date() + "] Data #" + i + ":" + data));
                    Thread.sleep(1000);
                } catch (IOException | InterruptedException e) {
                    // 发生错误时，关闭连接并报错
                    emitter.completeWithError(e);
                }
            }
            // 数据发送完成后，关闭连接
            emitter.complete();
        }).start();
        return emitter;
    }
}
```

**客户端**

- 引入依赖

```xml
<dependency>
	<groupId>com.squareup.okhttp3</groupId>
	<artifactId>okhttp</artifactId>
	<version>4.2.0</version>
</dependency>
<dependency>
	<groupId>com.squareup.okhttp3</groupId>
	<artifactId>okhttp-sse</artifactId>
	<version>4.2.0</version>
</dependency>
```
- 调用代码

```java
public static void main(String[] args) throws Exception {
    // 自定义监听器
    EventSourceListener eventSourceListener = new EventSourceListener() {
        @Override
        public void onOpen(EventSource eventSource, Response response) {
            System.out.println("onOpen...");
            super.onOpen(eventSource, response);
        }

        @Override
        public void onEvent(EventSource eventSource, String id, String type, String data) {
            // 接受消息 data
            System.out.println("onEvent:" + data);
            super.onEvent(eventSource, id, type, data);
        }

        @Override
        public void onClosed(EventSource eventSource) {
            System.out.println("onClosed...");
            super.onClosed(eventSource);
        }

        @Override
        public void onFailure(EventSource eventSource, Throwable t, Response response) {
            System.out.println("onFailure...");
            super.onFailure(eventSource, t, response);
        }
    };

    // 请求体 okhttp3.RequestBody
    HashMap<String, Object> map = new HashMap<>();
    map.put("text", "hello, 你好");
    String json = JSONUtil.toJsonStr(map);
    RequestBody body = RequestBody.create(MediaType.parse("application/json; charset=utf-8"), json);

    // 请求对象 okhttp3.Request
    Request request = new Request.Builder()
            .url("http://localhost:8080/api/sse/stream")
            .post(body) // POST请求
            .build();

    // 生产可将OkHttpClient设置成Bean，扩展参数可参考文档
    // https://square.github.io/okhttp/5.x/okhttp/okhttp3/-ok-http-client/index.html
    OkHttpClient client = new OkHttpClient.Builder().build();
    // 每次请求都需要创建Factory
    EventSource.Factory factory = EventSources.createFactory(client);
    // 创建事件, 返回数据会在eventSourceListener监听中显示
    factory.newEventSource(request, eventSourceListener);
}
```
