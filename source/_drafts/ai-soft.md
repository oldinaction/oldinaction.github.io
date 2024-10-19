---
layout: "post"
title: "AI相关软件"
date: "2023-02-08 20:18"
categories: extend
tags: [ai]
---

## 介绍

- AI中的Token: https://zhuanlan.zhihu.com/p/612954797
    - 在自然语言处理(NLP)中，token是指一组相关的字符序列，例如一个单词或一个标点符号，还可以是比词更高级别的语言单位，例如短语或句子
    - 在英语中“一个 token 通常对应大约 4 个字符”，而1个汉字大致是2~2.5个token。1000 tokens大概是750单词
    - gpt-3.5-turbo收费方式: $0.002 per 1k tokens
        - 1000 tokens大概是750单词，大概2美元可以问100万个token，相当于750000个单词。75万个单词需要15块钱人民币
        - 根据大家的经验，基本问清楚1个问题就要耗费100~200个token，算起来其实不少的，尤其在连续会话中，为了保持对话的连续性，必须每次都要回传历史消息，并且输入都要算 token 数算钱的
        - 官方提供的Token收费计算器: https://platform.openai.com/tokenizer

## 软件

- 聊天
    - ChatGPT: 问答模式
    - [claude](https://claude.ai)
        - 支持附件
- AI绘图
    - [Midjourney](https://www.midjourney.com/): ai绘图（新用户有25次的免费使用额度）
        - Discord使用地址: https://discord.com/invite/midjourney
    - dalle2、stable diffusion 也是ai绘图工具
    - [prompthero.com](https://prompthero.com) 搜集的都是ai生成的图片，可查看图片关键词
    - https://replicate.com/pharmapsychotic/clip-interrogator 可分析图片的关键字
- AI虚拟人
    - https://www.cutout.pro/zh-CN/photo-animer-gif-emoji/upload 图片生成动图(素人无法生成)
    - https://www.d-id.com/pricing/ 可以生成五官动
    - https://convert.leiapix.com/ 只能身体很奇怪的晃动
- AI配音
    - https://ttsmaker.com/zh-cn 文字转语音，多种语言和角色，api接口商业免费
- Clipchamp: 视频剪辑工具，可自动根据文字生成旁边语音和字幕
- aiva.ai 自动生成背景音乐

## 基础设施

- [Hugging Face](http://www.huggingface.co): 目前已经共享了超100,000个预训练模型，10,000个数据集，变成了机器学习界的github
    - https://zhuanlan.zhihu.com/p/535100411
- [Gitpod](https://www.gitpod.io/): Gitpod是一个基于云的集成开发环境（IDE），它为开发人员提供了一个完全在线的编码环境

## 案例

- [基于ChatGPT + Midjourney + Clipchamp创作视频](https://www.bilibili.com/video/BV1wW4y1G7a3)

## OpenAI

- [API价格](https://openai.com/pricing)，应该时旗下API不同类型按照token计费，最终进行统一扣款
    - 仅支持银行卡绑定付费
    - API调用: 每月免费$18.00
    - Chat gpt-3.5-turbo: $0.002 per 1k tokens
    - GPT-4: 8K context版 $0.03/1K 问题tokens，$0.06/1K 回答tokens；32K context版 $0.06/1K 问题tokens，$0.12/1K 回答tokens
- ChatGPT: WEB端访问免费；升级Plus，每月$20，速度和回复质量有所提高
- 官方提供的GPT Token收费计算器: https://platform.openai.com/tokenizer

## 百度

### 千帆大模型

> https://www.yuque.com/aezo/emoai/ri3rzvdhdgqk9fae?singleDoc

首先介绍一下百度AI相关产品矩阵，如下图百度力推的千帆大模型超级工厂，他包含

- 千帆大模型平台：其中大模型开发就是自己训练一个大模型，这种比较有技术含量，少部分企业才会用到；大模型调用则包含百度开放的文心大模型(即文心一言，ERNIE 4.0和ERNIE 3.5为模型版本分类，对标ChatGPT)，还包括一些第三方模型供调用
- 千帆AppBuilder：是提供开发者基于文心大模型可以快速开发出一个AI应用，创建的应用可以集成一些官方的组件（如天气查询、快递查询等），也可以集成自定义组件（通过画布拖拽，自行编排组件逻辑，如调用企业内部API或调用大模型接口），另外还可导入知识库供大模型使用(支持txt/pdf/doc/url等模式)。通过AppBuilder创建的应用官方提供一个访问链接供普通用户使用（界面是通用的AI聊天界面），开发者也可以通过SDK调用创建的AI应用从而集成到实际的业务系统中。这部分会在后续文章中做详细说明
- 千帆AI原生应用商店：就是百度自己开发的AI应用。如超级助理，下载浏览器插件即可使用，支持划词翻译、网页解读、OCR识别等功能

创建应用：进入 https://console.bce.baidu.com/qianfan/ais/console/applicationConsole/application 创建，可勾选启用的模型，如ERNIE-3.5-8K、ERNIE-4.0-8K、Yi-34B-Chat(免费)等

- [模型类型说明](https://console.bce.baidu.com/qianfan/modelcenter/model/buildIn/list)
    - ERNIE(百度): ERNIE-3.5、ERNIE-4.0
    - Yi(零一万物, 李开复): Yi-34B-Chat(免费)
    - Meta-Llama(Meta AI, Facebook)
- [模型计费说明](https://console.bce.baidu.com/qianfan/chargemanage/list)
    - ERNIE-4.0-8K: 输入：¥0.03元/千tokens, 输出：¥0.09元/千tokens
    - ERNIE-3.5-128K: 0.0008+0.002
    - ERNIE-Speed-128K(免费, 需开通, 每分钟请求Token数RPM=500)
    - Yi-34B-Chat(免费, 无需开通)
- [模型推理说明](https://console.bce.baidu.com/qianfan/ais/console/onlineService): 展示了模型服务名称和API地址，以及调用频率限制
    - 超过频率限制报错如: `Open api daily request limit reached` 同一个AppKey/Secret对于不同的模型有各自的调用频率限制, 不互相影响(如A模型超过调用量, 仍然可以调用B模型)

### 千帆AppBuilder

> https://www.yuque.com/aezo/emoai/hvmavirgbxdf7p24?singleDoc

千帆AppBuilder是提供开发者基于文心大模型可以快速开发出一个AI应用

创建的应用可以集成一些官方的组件（如天气查询、快递查询等），也可以集成自定义组件（通过画布拖拽，自行编排组件逻辑，如调用企业内部API或调用大模型接口）

另外还可导入知识库供大模型使用(支持txt/pdf/doc/url等模式)

通过AppBuilder创建的应用官方提供一个访问链接供普通用户使用（界面是通用的AI聊天界面），开发者也可以通过SDK调用创建的AI应用从而集成到实际的业务系统中

## 阿里

### 语音识别

- [一句话识别](https://help.aliyun.com/zh/isi/developer-reference/short-sentence-recognition/)
  - 阿里云官方提供的小程序SDK是将 accessKeyId 和 accessKeySecret 放在小程序代码里面(是否存在一定的数据泄露风险???)
  - 可基于小程序录音并将录音文件回传然后解析识别
    - 参考: https://help.aliyun.com/zh/isi/developer-reference/sdk-for-java 官方案例中是接收到消息后进行异步返回的，可通过Websocket等方式返回
    - 案例参考: `aezo-chat-gpt(sqt-qingxingyigou)/AliAudioService.java#audioRecognizer`

### 语音合成

- [语音合成CosyVoice大模型](https://help.aliyun.com/zh/model-studio/developer-reference/quick-start-cosyvoice)
  - 可实现全双工流式合成：多次输入合成文本，多次返回合成音频
  - 官方案例中有将LLM生成的文本通过扬声器实时播放（全双工流式合成）
  - 案例参考: `aezo-chat-gpt(sqt-qingxingyigou)/QanythingEventSourceListener.java`
  - 可将流式合成的语音数据(ByteBuffer)返回到小程序等前端从而实现全双工流式合成效果（由于小程序无法实现流式播放，可将后端多个ByteBuffer合成为几个大的ByteBuffer传到小程序端，从而小程序端进行多个ByteBuffer依次播放来实现），参考[uni-app.md#语音处理](/_posts/mobile/uni-app.md#语音处理)
  
    ```java
    private static ByteBuffer mergeByteBuffers(ByteBuffer buffer1, ByteBuffer buffer2) {
        ByteBuffer mergedBuffer = ByteBuffer.allocate(buffer1.remaining() + buffer2.remaining());
        mergedBuffer.put(buffer1);
        mergedBuffer.put(buffer2);
        mergedBuffer.flip();
        return mergedBuffer;
    }
    ```

## 字节

## 有道

### QAnything

- 官网: https://ai.youdao.com/saas/qanything
- API文档: https://ai.youdao.com/qanything/docs/intro/api-intro
- 特点: 支持知识库
    - API响应速度略慢
- 免费版: 文件存储空间5G, 训练语料字数200万字, AI积分500万




