---
layout: "post"
title: "OkHttp"
date: "2023-04-18 22:13"
categories: [arch]
---

## 简单POST请求

```java
public static void main(String[] args) throws IOException {
    String msg = "你是谁";
    OkHttpClient okHttpClient = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build();
    String requestBody = "{\"enable_google_results\":\"true\",\"enable_memory\":false,\"input_text\":\""+ msg +"\"}";
    Request request = new Request.Builder()
            .url("https://api.writesonic.com/v2/business/content/chatsonic?engine=premium&language=zh")
            .post(RequestBody.create(MediaType.parse(ContentType.JSON.getValue()), requestBody))
            .addHeader("X-API-KEY", "564b4f5d-5e15-4ff0-45sd-ce44df123543")
            .build();
    Response response = okHttpClient.newCall(request).execute();
    String result = response.body().string();
    System.out.println("result = " + result);
}
```

## SSE客户端案例

- ServerSentEvent案例
    - 服务端使用如: https://www.baeldung.com/spring-server-sent-events#mvc

```java
@Slf4j
public class ChatClient extends EventSourceListener {

    @Override
    public void onOpen(EventSource eventSource, Response response) {
        log.info("建立sse连接...");
    }

    @SneakyThrows
    @Override
    public void onEvent(EventSource eventSource, String id, String type, String data) {
        log.info("返回数据：{}", data);
    }

    @Override
    public void onClosed(EventSource eventSource) {
        log.info("关闭sse连接...");
    }

    @SneakyThrows
    @Override
    public void onFailure(EventSource eventSource, Throwable t, Response response) {
        if (Objects.isNull(response)) {
            return;
        }
        ResponseBody body = response.body();
        if (Objects.nonNull(body)) {
            log.error("sse连接异常data：{}，异常：{}", body.string(), t);
        } else {
            log.error("sse连接异常data：{}，异常：{}", response, t);
        }
        eventSource.cancel();
    }

    public void sendMsg(OkHttpClient okHttpClient, String msg) {
        String requestBody = "{\"user\": \"1\",\"model\":\"gpt-3.5-turbo\",\"messages\":[\""+ msg +"\"],\"stream\":true}";
        Request request = new Request.Builder()
                .url("https://api.openai.com/v1/chat/completions")
                .post(RequestBody.create(MediaType.parse(ContentType.JSON.getValue()), requestBody))
                .build();

        EventSource.Factory factory = EventSources.createFactory(okHttpClient);
        // 发起SSE请求，需要服务端支持SSE
        factory.newEventSource(request, this);
    }

    public static void main(String[] args) {
        OkHttpClient okHttpClient = new OkHttpClient.Builder()
                .connectTimeout(30, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                // .proxy(proxy)
                .build();
        
        ChatClient chatClient = new ChatClient();
        chatClient.sendMsg(okHttpClient, "你是谁");
    }
}
```
