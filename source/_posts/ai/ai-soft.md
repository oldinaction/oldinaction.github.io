---
layout: "post"
title: "AI相关软件"
date: "2023-02-08 20:18"
categories: ai
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

## 网址收集

### AI导航

- [toolify](https://www.toolify.ai/)
- https://ai-bot.cn/ AI工具集
- https://www.aigc.cn/ AIGC导航
- https://www.ailookme.com/ AI工具箱
- https://www.8nav.com/ AI导航
- https://www.meoai.net/ MEOAI
- https://www.ai-dh.com/ AI导航
- https://www.aiopenminds.com AI导航

### AI聊天

- ChatGPT: 问答模式
- [Gemini3](https://gemini.google.com/): [对话](https://aistudio.google.com/)
- [claude](https://claude.ai) 支持附件
- https://yiyan.baidu.com/ 文心一言

### AI编程

- 参考[ai-coding.md](/_posts/ai/ai-coding.md)

### AI绘图

- [SD(Stablediffusion)](https://stability.ai/): 开源免费，对应UI框架如
    - [ComfyUI](https://github.com/comfyanonymous/ComfyUI) 节点可自定义, 自由度高, 哩布哩布在线版包含
    - [WebUI:stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui) 哩布哩布在线版包含
        - [AI绘世(汉化版)](https://www.bilibili.com/opus/897873624905547794)
- 国内
    - 即梦, 豆包
    - 通义, 腾讯元宝, 可图, 秒画, 可灵
    - [豆绘AI](https://www.douhuiai.com/)
- 国外
    - [ImageFx(Google)](https://labs.google/fx/tools/image-fx)
    - Nano banana(Google)
    - dalle2
    - [Midjourney](https://www.midjourney.com/): ai绘图（新用户有25次的免费使用额度）
        - Discord使用地址: https://discord.com/invite/midjourney
- 常用网站
    - [哩布哩布AI](https://www.liblib.art/) 国内较权威. 支持模型下载, 在线生图, 作品灵感
    - [civitai](https://civitai.com/) 国外FQ, 模型下载, 灵感分析
        - DreamShaper, majic麦吉: 生图质量较高, 范围广泛
        - PrimeMix: 二次元模型
        - ArchitectureRealMix: 建筑类模型
    - https://novelai.dev/ AI绘世提供, 解析SD图片获取提示词, 提示词超时
    - https://promlib.com/ 提示词标签及效果展示

#### 绘画模型

- 基础模型
    - SD系列
        - SD 1.5 入门级
        - SD 3.5
        - SDXL(Stable Diffusion XL): 针对高质量图像生成设计的进阶模型, 对硬件要求更高
        - Pony: 基于 SDXL
    - Flux: 由Stability AI前核心成员开发, 非 SD 系列, 需要 24GB 以上显存才能流畅运行
        - Flux 1.0(F.1)
- SD模型说明
    - 模型文件常见后缀
        - .safetensors: 安全的模型文件格式, 可以防止模型被修改或损坏
        - .ckpt: 检查点文件, 包含模型的参数和状态, 可以用于恢复训练或继续生成
        - .pt: PyTorch 模型文件, 包含模型的结构和参数, 可以用于在 PyTorch 中加载和使用
    - SD模型(目录models/Stable-diffusion)
    - LoRA(目录models/Lora)
        - 常用模型: https://civitai.com/models/11333/anything-v5
    - Embeddings(目录embeddings)

#### SD使用

- WebUI界面
    - Stable Diffusion 模型: anything-v5
    - 外挂 VAE 模型: 解码
    - 工具栏
        - 文生图
        - 图生图: 仍然需要提示词, 进行描述; 常用语高清修复
    - 提示词: 只支持英文及标点
        - 扩展模型(内嵌词/Embedding): 如从 https://civitai.com/models 中筛选 Embedding 模型, 然后找到想要的风格, 下载模型文件放到 SD 安装目录下的 `embeddings` 文件夹中, 使用时直接导入到提示词输入框即可
        - 其他常用提示词标签, 如人物, 服饰, 场景特征等. 类似 https://tags.novelai.dev/
    - 反向词: 类似提示词, 但作用是拒绝生成某些内容
    - 生成
        - 采样方法: 一般使用 DPM++ 系列, 带 SDE 的每次生成具有动态性, 不带 SDE 的每次生成结果趋于稳定
        - 迭代步数: 一般 20-30 步, 越高越详细, 但也会越慢
        - 高分辨率修复: 使图片变的更清晰
            - 高分迭代步数一般是 0, 重绘幅度一般 0.5 以下, 放大倍数一般 2-4 倍, 放大算法如R-ESRGAN 4x+(真人) 和 R-ESRGAN 4x+ Anime6B(二次元)
        - Refiner: 选择模型和切换时机. 比如切换时机为0.8, 则当图片生成到 20*0.8 步时使用此处定义的模型进行继续渲染(之前使用顶部定义的 SD 模型渲染)
        - 宽度高度: 一般 512x512, 可以根据需要调整, 但必须是 8 的倍数
        - 提示词引导系数(CFG): 越小提示词权重越低, 生成的自由发挥空间更大; 一般是 5-10
        - 随机种子: 生成的每一张图都有各自的随机种子
            - 循环图标表示上一张的随机种子，比如上一张人物可以，背景不行，可以使用上一张的随机种子，再重新描述下背景进行生成
            - 如果将种子值设置成一样，并将提示词设置成一样，那么就可以在不同电脑上生成相同图片
        - After Detailer: 对生成的图片进行后处理, 如去噪, 去模糊等
        - ControlNet: 精准出图, 参考 https://zhuanlan.zhihu.com/p/619721909
            - 勾选启用
            - 控制类型
                - SoftEdge(柔滑边缘): 预处理器如: HED保留细节多但是边缘准确度差, PiDi合理保留主体忽略一些细节
                - Lineart(线稿上色)
                - Openpose(人物姿态): 可基于参考图的人物姿态生成到结果图; 预处理器如: dw_openpose_full
                - Depth(深度,空间关系)
                - Tile(分块)
                - IPAdapter: 常用于人脸替换, 材质迁移, 风格迁移; 预处理器如: ip-adapter-face_id_plus
                - 多个ControlNet单元组合使用: 建筑常用: SoftEdge+Depth, 人物常用: SoftEdge+Openpose+Depth+IPAdapter
            - 勾选预览, 点击预处理器旁边的爆炸图标进行预览
    - 重绘幅度: 比如基于绿茶饮料瓶生成女孩, 此时重绘幅度可以调整大一些
- 图生图案例
    - 局部重绘: 将需要修改的部分标记一下, 并增加想要提示词(进行局部修改, 整体不会变)
    - 涂鸦: 在图片上涂鸦后, 增加提示词进行重绘(可能和传入的图片有较大差异)
- 高清分辨率
    - 一阶段高分辨率修复: 勾选高分辨率修复, 随机种子选择上一张生成的(点击循环图标), 重新生图
    - 二阶段重绘尺寸: 点击生成图下方的照片图标进行图生图, 修改重绘尺寸倍数为2, 设置上一张生成的随机种子, 重新生图
    - 三阶段模型放大: 点击生成图下方的三角尺图标进行后期处理, 勾选图像放大, 放单算法如R-ESRGAN 4x+, 宽高设置成 1024, 缩放比例 4

#### 绘图工具

- https://www.remove.bg/zh/ 去除背景（包括水印）
- 工具类
    - https://prompthero.com 搜集的都是ai生成的图片，可查看图片关键词
    - https://replicate.com/pharmapsychotic/clip-interrogator 可分析图片的关键字

### AI视频

#### 视频工具

- https://supawork.ai/zh 去除视频背景（包括水印），支持API
- Clipchamp: 视频剪辑工具，可自动根据文字生成旁边语音和字幕

#### 虚拟数字人

- https://www.cutout.pro/zh-CN/photo-animer-gif-emoji/upload 图片生成动图(素人无法生成)
- https://www.d-id.com/pricing/ 可以生成五官动
- https://convert.leiapix.com/ 只能身体很奇怪的晃动

### AI音频

- https://ttsmaker.com/zh-cn 文字转语音，多种语言和角色，api接口商业免费
- aiva.ai 自动生成背景音乐
- 开源
    - https://github.com/Soul-AILab/SoulX-Podcast

### AI文案

- [讯飞智文](https://zhiwen.xfyun.cn/) 免费使用，支持基于文本/PDF等文件一键生成Word、PPT文档，并对单页文档进行AI聊天式调整
- [Kimi.ai](https://kimi.moonshot.cn/) 支持在线网页、多文件多格式上传，进行文案归纳总结，可支持200万字的文案总结

### AI工具

### AI聚合(API汇集)

- https://302.ai/ AI聚合

## 提示词

### 图片生成提示词

- 常用提示词

```bash
--ar 9:16 # 手机竖屏比例

depth of field # 景深(远处的背景, 着重近处的人物; 背景虚化)
```
- 提示词书写
    - 人物主体特征: 服饰穿搭, 发型颜色, 五官特点, 面部表情, 肢体动作
    - 场景特征: 室内室外, 大小场景, 小细节
    - 环境光照: 白天黑夜, 光效环境, 特点时间, 场景填空
    - 补充画幅视角: 人物比例, 视角镜头, 镜头类型, 观察视角
- 画风关键词
    - 插画风: lllustration, painting
    - 真实系: photorealistic
    - 二次元: CG, anime, comic
    - 3D风格: 3D render, CGI
- 画质提示词: `(masterpiece:1.2),best quality,ultra-detailed,4k,8k` 杰作,最佳质量,超级细节化,4k,8k
- 权重分配
    - 套括号: `()` 权重x1.1, `{}` 权重x1.05, `[]` 权重x0.9
        - 如果是`(((xxx)))`就是 1.1^3=1.331
        - 安全范围在 1 上下 0.5
    - 前面的权重更高, 顺序: 画质/画风 - 主体 - 环境/场景/构图 - LoRA(模型的轻量微调)
- 提示词融合
    - 非融合 `1girl,cat` 女孩身上有一只猫
    - 融合: 使用 AND 或 _ `1girl AND cat` 或 `1girl_cat` 可能是一个猫娘, AND必须大写
    - 提示词混合: `white/yellow flower` 生成白黄混合的花
    - 提示词迁移: `[white/red/yellow] flower` 先生成白花, 再生成红花, 再生成黄花. 其中/可替换成|
    - 分时间融合: `{forest:1girl:0.3}` 前 30% 的迭代步数生成森林, 后 70% 生成人物
- 负面提示词
    - `(worst quality:2),(low quality:2),(normal qualty:2),lowres,normal qualty,((monochrome)),((grayscale)),blurry` (正常质量:2)，(低质量:2)，(正常质量:2)，低质量，正常质量，((单色))，((灰度))，模糊
    - `skin spots,acnes,skin blemishes,age spot,(ugly:1.331),(duplicate: 1.331),(morbid:1.21),(mutilated:1.21),(tranny:1.331),mutated hands,(poory drawn hands:1.5),(bad anatomy:1.21),(bad proportions:1.331),extra limbs,(disfigured:1.331),(missing arms:.1.331),(extra legs:1.331),(fused fingers:1.61051),(too many fingers:1.61051),(unclear eyes:1.331),lowers,bad hands,missing fingers,extra digit,bad hands,(((extra arms and legs))),(easynagetive1.3)` 皮肤斑点，痤疮，皮肤瑕疵，老年斑，(丑陋:1.331)，(重复:1.331)，(病态:1.21)，(残缺:1.21)，(变形:1.331)，变异的手，(画得不好的手:1.5)，(解剖不良:1.21)，(比例不良:1.331)，多余的四肢，(毁容:1.331)，(缺胳膊:1.331)，(多余的腿:1.331)，(融合的手指:1.61051)，(过多的手指:1.61051)，(不清晰的眼睛:1.331)，低，手坏了，少了手指，多了手指，手坏了，多了胳膊和腿
    - `ng_deepnegative_vl_75t` SD负面提示词模型

### 视频生成提示词

- 你是一个 AI 短视频博主，创作的内容特别厉害，现在要你构思一个短视频，视频时长 33s，以 vlog 形式记录一个人普通但平凡的一天，虽然平凡，但很幸福，要求贴合现实生活。创作内容需要包含以下几个方面：分镜时间，分镜脚本（脚本能通过 AI 画出来），分镜脚本包括人物、场景、动作、画面、镜头、环境、氛围等，创作内容还要包括分镜文案

## 基础设施

### 开发资源

- [Hugging Face](http://www.huggingface.co): 目前已经共享了超100,000个预训练模型，10,000个数据集，变成了机器学习界的github
    - 镜像站: https://hf-mirror.com/
    - https://zhuanlan.zhihu.com/p/535100411
- [Ollama](https://github.com/ollama/ollama) 可在本地机器上便捷部署和运行开源大模型

```bash
# 安装完直接运行ollama命令即可。支持的模型: https://ollama.com/library
# 安装并启动 llama3.2 模型
ollama run llama3.2
# 安装并启动 deepseek-r1 模型, 1.5b参数量(1.1GB)
ollama run deepseek-r1:1.5b
```
- [Gitpod](https://www.gitpod.io/): Gitpod是一个基于云的集成开发环境（IDE），它为开发人员提供了一个完全在线的编码环境

### 社区

- [阿里云百炼](https://bailian.console.aliyun.com/)
- [魔搭社区(阿里巴巴)](https://modelscope.cn)
    - 阿里云ModelScope社区 https://developer.aliyun.com/modelscope
    - 阿里云ModelScope在线体验模型测试 https://developer.aliyun.com/article/1023556
- [Alink实验室(阿里巴巴)](https://alinklab.cn/index.html)
- [飞桨(百度)](https://aistudio.baidu.com/index)
- [千帆社区(百度)](https://cloud.baidu.com/qianfandev)

## OpenAI

- [API价格](https://openai.com/pricing)，应该时旗下API不同类型按照token计费，最终进行统一扣款
    - 仅支持银行卡绑定付费
    - API调用: 每月免费$18.00
    - Chat gpt-3.5-turbo: $0.002 per 1k tokens
    - GPT-4: 8K context版 $0.03/1K 问题tokens，$0.06/1K 回答tokens；32K context版 $0.06/1K 问题tokens，$0.12/1K 回答tokens
- ChatGPT: WEB端访问免费；升级Plus，每月$20，速度和回复质量有所提高
- 官方提供的GPT Token收费计算器: https://platform.openai.com/tokenizer

## 阿里

- Alink实验室 https://alinklab.cn/index.html

### 百炼

- [控制台](https://bailian.console.aliyun.com/)
- [文档](https://help.aliyun.com/zh/model-studio)
    - [应用调用](https://help.aliyun.com/zh/model-studio/user-guide/application-calling)

### 魔搭社区

- https://modelscope.cn
    - 阿里云ModelScope社区 https://developer.aliyun.com/modelscope
    - 阿里云ModelScope在线体验模型测试 https://developer.aliyun.com/article/1023556

### 语音识别

- [百炼语音识别](https://help.aliyun.com/zh/model-studio/user-guide/automatic-speech-recognition)
    - 模型赠送免费额度
- [一句话识别](https://help.aliyun.com/zh/isi/developer-reference/short-sentence-recognition/)
  - 准备阶段: 创建子账户，授权AliyunNLSFullAccess，并生成accessKeyId 和 accessKeySecret；在[智能语音交互控制台](https://nls-portal.console.aliyun.com/applist)创建应用，并获取项目Appkey
  - 阿里云官方提供的小程序SDK是将 accessKeyId 和 accessKeySecret 放在小程序代码里面(是否存在一定的数据泄露风险???)
  - 可基于小程序录音并将录音文件回传然后解析识别
    - 参考: https://help.aliyun.com/zh/isi/developer-reference/sdk-for-java 官方案例中是接收到消息后进行异步返回的，可通过Websocket等方式返回
    - 案例参考: `aezo-chat-gpt(sqt-qingxingyigou)/AliAudioService.java#audioRecognizer`

### 语音合成

- [百炼语音合成](https://help.aliyun.com/zh/model-studio/user-guide/text-to-speech)
    - CosyVoice大模型(参考下文): 流式输入输出, 支持声音复克
    - Sambert大模型: 不支持流式输入, 支持多种国外音色
- [语音合成CosyVoice大模型(百炼)](https://help.aliyun.com/zh/model-studio/developer-reference/quick-start-cosyvoice)
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

### 实时语音/视频

- [智能媒体服务-AI实时互动](https://help.aliyun.com/zh/ims/user-guide/ai-real-time-interactive-overview)

## 字节

- 火山引擎: https://volcengine.com/
    - [火山方舟](https://console.volcengine.com/ark/)
    - [扣子](https://www.coze.cn/): https://www.volcengine.com/product/coze-pro
        - 零代码快速搭建个性化AI应用(插件丰富), 也支持API调用
        - 基础版免费(豆包个人自建智能体就是基于扣子实现)
    - [豆包](https://www.volcengine.com/product/doubao)

## 智谱

- [Z.ai官网](https://z.ai/)
- [智谱开放平台](https://bigmodel.cn/)

## Kimi

## 百度

- 飞桨(百度) https://aistudio.baidu.com/index

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

## 有道

### QAnything

- 官网: https://ai.youdao.com/saas/qanything
- API文档: https://ai.youdao.com/qanything/docs/intro/api-intro
- 特点: 支持知识库
    - API响应速度略慢
- 免费版: 文件存储空间5G, 训练语料字数200万字, AI积分500万

## 案例

### AI编程流程

- 参考
    - Trea流程案例 https://github.com/oldinaction/demo-flutter/blob/main/flutter_demo_dot_dot_dot/AI.md
- Trea流程
    - 生成需求文档 README.md
    - 生成开发规则文档 RULES.md (或者直接在 trea 中设置: `.trea/rules/project_rules.md`)
    - 生成原型图
        - 在Trae/豆包中生成APP原型图html代码
        - 或者通过 v0.app 基于图片生成原型代码并下载
    - 在Trae中通过Builder模式进行开发
        - `目前我们已经有一个产品需求文档 #README.md，以及一个你必须遵循的规则 #RULES.md，同时我将上传给你一张APP的原型图，请你根据这个原型图和需求进行开发。`

### 视频制作

- [基于ChatGPT + Midjourney + Clipchamp创作视频](https://www.bilibili.com/video/BV1wW4y1G7a3)



