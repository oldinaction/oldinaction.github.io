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

- ChatGPT: 问答模式
- [Midjourney](https://www.midjourney.com/): ai绘图（新用户有25次的免费使用额度）
    - dalle2、stable diffusion 也是ai绘图工具
    - [prompthero.com](https://prompthero.com) 搜集的都是ai生成的图片，可查看图片关键词
    - https://replicate.com/pharmapsychotic/clip-interrogator 可分析图片的关键字
- Clipchamp: 视频剪辑工具，可自动根据文字生成旁边语音和字幕
- aiva.ai 自动生成背景音乐
- [Hugging Face](http://www.huggingface.co): 目前已经共享了超100,000个预训练模型，10,000个数据集，变成了机器学习界的github
    - https://zhuanlan.zhihu.com/p/535100411

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
