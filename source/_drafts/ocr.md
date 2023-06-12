---
layout: "post"
title: "OCR智能识别"
date: "2021-02-26 18:34"
categories: [arch]
---

## 简介

- `OCR` （Optical Character Recognition，光学字符识别），就是识别图片上的文字，然后提取出来，变成可编辑的文档
- OCR相关软件：https://www.zhihu.com/question/34873811
- ORC相关API
    - [百度文字识别](https://ai.baidu.com/tech/ocr/general)
        - 每天5w免费识别次数
    - [阿里云](https://ai.aliyun.com/ocr/general)
    - [腾讯](https://cloud.tencent.com/product/ocr-catalog?lang=cn)
    - [azure](https://azure.microsoft.com/zh-cn/services/cognitive-services/computer-vision/)
    - [ABBYY](https://www.abbyy.cn/mobile-capture-sdk/)
    - [ocr space](https://ocr.space/)
        - 提供在线语音识别和免费API接口，当然也有专业版的付费API接口
- 开源框架
    - [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR)
        - PaddlePaddle开源，[PaddlePaddle](https://www.paddlepaddle.org.cn/)一般指飞桨，是百度开源深度学习平台
        - 超轻量级中文OCR（模型大小仅8.6M）
    - [Tesseract](https://github.com/tesseract-ocr/tesseract)
        - 谷歌开源，支持100多种语言
    - [Ocropus](https://github.com/ocropus/ocropy)
        - 采用可插入的布局分析，可插入的字符识别
    - [树洞 OCR 文字识别](https://github.com/AnyListen/tools-ocr)
        - 一款跨平台的 OCR 小工具
