---
layout: "post"
title: "AI编程"
date: "2023-02-08 20:18"
categories: ai
tags: [ai]
---

## TODO

- 技能
    - 技能和 Agent 交互?

    ```bash
    Agent分析
    ↓
    Skill A 启动 → suspend（状态1）
    ↓
    Agent (<-> 用户) 多轮交互
    ↓
    Skill A resume（状态1）→ 继续执行 → suspend（状态2）
    ↓
    Agent 再交互
    ↓
    Skill A resume（状态2）
    ↓
    最终处理 → finish
    ```

## Vibe-Coding

- [easy-vibe](https://datawhalechina.github.io/easy-vibe/zh-cn/)

## AI编程工具

- 端到端模式
    - [Claude Code](https://claude.com/product/claude-code) 常用终端(也支持桌面), 系统级Agent
- IDE(协作模式)
    - Trea: 字节
    - [Antigravity](https://antigravity.google/) IDE, Google
        - [Gemini3](https://aistudio.google.com/)
        - [API Keys](https://aistudio.google.com/app/api-keys)
    - [Cursor](https://cursor.com/) 类似Trae
    - [OpenCode](https://github.com/anomalyco/opencode)
    - Windsurf
    - Kiro 亚马逊
    - GitHub Copilot 终端
- API类
    - 智谱LM 4.7
    - Kimi K2
- 原型工具
    - [V0: 生成简单原型界面](https://v0.app/)
- 设计图工具
    - [Stitch](https://stitch.withgoogle.com/): Google, 原型生成
    - Figma Make
- 流程图设置
    - [基于draw.io的AI流程图插件](https://github.com/DayuanJiang/next-ai-draw-io): [在线使用](https://next-ai-drawio.jiang.jp/)

## 相关概念协议

- Skills vs MCP vs Subagents 
    - Skills 教 AI 怎么做（可移植的专业知识）
    - MCP 给 AI 连接数据（外部数据源和 API）
    - Subagents 让 AI 分身干活（独立运行的子任务）

### MCP

- [Figma原型生成](https://github.com/GLips/Figma-Context-MCP)
- [Stitch原型生成](https://stitch.withgoogle.com/docs/mcp/setup)
- [firebase](https://github.com/gannonh/firebase-mcp)

### Skills

- 参考: https://cloud.tencent.com/developer/article/2616897
- [openskills](https://github.com/numman-ali/openskills) 技能管理框架
- claude-code中使用

```bash
## (推荐)基于 openskills 管理技能
npm i -g openskills
# 安装技能(如在家目录执行), 会安装到当前目录的 ./.claude/skills/ 目录
openskills install anthropics/skills # 科学上网
# openskills install your-org/custom-skills # 安装自定义技能库
openskills sync # 同步技能到当前目录的 AGENTS.md 文件中

## 基于[skills-installer](https://www.npmjs.com/package/skills-installer) 安装技能
npx skills-installer install @anthropics/claude-code/frontend-design --client claude-code # 安装前端设计技能包

## 基于 claude-code 提供的插件市场安装技能
/plugin marketplace add anthropics/skills # 安装 claude-code 官方技能库
/plugin install document-skills@anthropic-agent-skills # 文档技能包
/plugin install example-skills@anthropic-agent-skills # 示例技能包
```
- trae中使用: 新版本内置技能设置; 下文是手动触发技能方案
    - 先 openskills install 及 sync 安装并同步技能到当前目录的 AGENTS.md 文件中
    - 然后对话中使用技能名或相关关键词触发技能. eg: `基于 frontend-design skills 设计一个宠物记事的H5网页`

#### Skills收集分类

- [SkillsMP](https://skillsmp.com/zh): 收录 30,000+ 预定义技能
    - [claude-code官方技能库](https://github.com/anthropics/skills)
- https://www.aitmpl.com 提供 Skills, MCP, Commands 等
- https://skills.sh/
- [Stitch原型设计官方技能](https://github.com/google-labs-code/stitch-skills)
- [Flutter开发官方技能](https://github.com/flutter/skills/tree/generate-skills)

## AI编程工具

### Claude-Code

- [Claude Code 官方文档](https://code.claude.com/docs/zh-CN/overview)
    - 命令行安装参考下文
    - [WEB版使用](https://claude.ai/)
    - 第三方CC-GUI(类似 Codex 界面): https://github.com/zhukunpenglinyutong/desktop-cc-gui
    - 官方桌面端(不推荐): https://code.claude.com/docs/en/desktop-quickstart
- Claude Code 实践
    - [Claude Code Terminal工作流](https://mp.weixin.qq.com/s/x9wUAM6QI1Ogv2B0biawbg)
    - [Claude Code 完全指南](https://www.cnblogs.com/knqiufan/p/19449849)
    - [Hooks以及Iterm2通知](https://blog.csdn.net/chendongqi2007/article/details/157874356)
    - [Claude Code命令行底部增加状态栏](https://github.com/Wangnov/claude-code-statusline-pro)
- 相关工具
    - [cc-switch](https://github.com/farion1231/cc-switch) 切换不同模型

#### 命令行安装

- 参考: https://docs.bigmodel.cn/cn/coding-plan/tool/claude

```bash
# 使用 npm 全局安装 Claude Code. 依赖 Node.js 18+
# 或者 mac安装: `curl -fsSL https://claude.ai/install.sh | bash`
# windows ps安装: `irm https://claude.ai/install.ps1 | iex`
npm install -g @anthropic-ai/claude-code
npm update -g @anthropic-ai/claude-code

# (推荐) 使用 cc-switch 工具切换不同模型. 切换模型后 ~/.claude/settings.json 文件也会被此插件接管. 可设置通用配置和每个模型自己的配置
# 设置: 勾选"跳过 Claude Code 初次安装确认"
https://github.com/farion1231/cc-switch
# (忽略) 使用智谱 GLM 模型: 基于智谱提供的工具 @z_ai/coding-helper 进行配置智谱 API-KEY. 参考: https://docs.bigmodel.cn/cn/coding-plan/tool/claude
# npx @z_ai/coding-helper

# 验证安装是否成功. 2.1.7 (Claude Code)
# claude update # 更新到最新版本
# 配置文件在 ~/.claude 目录
claude --version
/login # 登录账户

# 进入文件夹后只需命令即可启动. 上下文会限制在这个目录
cd xxx # 进入某个文件夹作为工作空间, 不要在家目录执行
claude # 启动 Claude Code 会话, 会话会限制在这个目录下
# claude --dangerously-skip-permissions # 危险模式. 跳过一切确认完全授权执行


## 常用命令: https://code.claude.com/docs/zh-CN/cli-reference
# 基础操作
claude                    # 启动 Claude Code 会话
    claude --dangerously-skip-permissions # 危险模式. 跳过一切确认完全授权执行
claude --version          # 查看版本
claude -p "prompt"        # Headless 模式(非交互式)，可集成到 Shell 脚本或 CI/CD 流程中. eg: git diff | claude -p "解释这些更改"
    claude -p --output-format json # 结构化输出，便于脚本消费
    claude -p --output-format stream-json # 实时 JSON 事件流，适合长任务监控、增量处理、流式集成到自己的工具
claude --continue               # 恢复当前目录最近会话，隔天接着做
    claude --continue --fork    # 从已有会话分叉，同一起点不同方案
claude --resume                 # 打开选择器恢复历史会话

# 斜杠命令
/clear                    # 清空对话
/compact                  # 压缩对话
/plan	                  # 生成项目计划
/init	                  # 初始化 Claude.md 文件
/add-dir <路径>	           # 添加更多工作目录到上下文
/export conversation-260106.json # 导出当前会话的 JSON 格式记录
/context                  # 查看上下文
/cost                     # 查看费用
/model                    # 切换模型
/mcp                      # 管理 MCP
/skills                   # 查看 Skills
/hooks                    # 管理 Hooks
/agents                   # 管理子代理
/status                   # 系统状态
/doctor                   # 诊断环境
/help                     # 查看帮助
# 其他命令
/memory                   # 查看内存使用情况
/permissions              # 查看或更新权限白名单
/sandbox                  # 配置沙箱隔离，高自动化场景必备
/rewind                   # 不是”撤销”，而是回到某个会话 checkpoint 重新总结对话; 想保留前半段共识但丢掉后半段失败

# 快捷键
Ctrl+R                    # 搜索历史
Ctrl+S                    # 暂存提示词
Ctrl+C                    # 中止操作
Shift+Tab × 2             # Plan 模式
ESC ESC                   # 回溯，可以回到上一条输入重新编辑，不用重新手打
Alt+V                     # 粘贴图片

# 文件操作
@file.ts                  # 引用文件
@src/                     # 引用目录
!command                  # 执行 Bash 命令. Ctrl+o 切换显隐全部内容. eg: !ls


## 安装MCP. 常用如: Chrome DevTools (从而可操控浏览器)
claude mcp add chrome-devtools npx chrome-devtools-mcp@latest
claude mcp list # 命令行查看; claude 中查看: /mcp
claude mcp remove chrome-devtools # 移除已安装的 MCP 服务器
```

#### 配置说明

- 配置文件`~/.claude.json`
- 配置目录`~/.claude`，目录下包括
    - settings.json 参考下文
    - projects 文件夹名按项目路径命名（斜杠变横杠），每个会话是一个 .jsonl 文件
- ~/.claude/settings.json <== 项目目录 .claude/settings.json 或 .claude/settings.local.json

```json
{
    "env": {
        "ANTHROPIC_BASE_URL": "https://api.moonshot.cn/anthropic",
        "ANTHROPIC_AUTH_TOKEN": "sk-xxxx",
        "ANTHROPIC_MODEL": "kimi-k2.5",
        "ANTHROPIC_REASONING_MODEL": "kimi-k2.5",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL": "kimi-k2.5",
        "ANTHROPIC_DEFAULT_OPUS_MODEL": "kimi-k2.5",
        "ANTHROPIC_DEFAULT_SONNET_MODEL": "kimi-k2.5",
        "API_TIMEOUT_MS": "3000000",
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
    },

    // 权限. 禁用 WebSearch 功能. 或者使用 Brave<brave.com> 的 MCP 服务
    // "permissions": { "deny":[ "WebSearch" ] },

    // 禁用 WebFetch 工具前置的风控检查 (anthropic.com 会拒绝所有来自中国大陆、香港的请求)
    "skipWebFetchPreflight": true,

    // 基于插件显示状态栏 https://github.com/Wangnov/claude-code-statusline-pro
    "statusLine": {
        "command": "npx ccsp@latest --preset PMBTUS --force-emoji",
        "type": "command"
    }
}
```

#### CLAUDE.md文件

- 大小 10K - 20K
- 实用技巧与误区
    - 应该很短：只在 Claude 容易出错的地方加说明，别想着写完整手册
    - 别用 @ 引用文档：正确做法是推销这个文件，告诉它为什么和何时该读。例如：遇到复杂用法或 FooBarError 错误时，参考 path/to/docs.md 的高级故障排除
    - 别只说禁止：不要写纯否定约束，比如永远不要用某个标志。智能体真需要这个标志时就傻了。永远提供替代方案
    - 把 CLAUDE.md 当倒逼函数：对于复杂的工作应该写个简洁的 Bash 包装脚本，提供清晰的 API，然后只给包装脚本写文档
- `AGENTS.md` 可以同步维护一个 AGENTS.md 文件，兼容工程师可能用的其他 AI IDE

#### 实践技巧

- `/context` 建议编码时至少运行一次，看看 200k 个 token 的上下文窗口用了多少
- `/compact` 压缩上下文。尽量别用，自动压缩不透明、容易出错、优化不好
    - 简单重启会话用 `/clear` 清除上下文，然后通过快捷命令让 Claude 读取 git 变更记录
    - 复杂任务让 Claude 把计划和进度写进 .md 文件，/clear 清状态，然后新会话读取 .md 继续干
- 自定义子智能体存在问题：隔离上下文
    - 应该把上下文给主智能体（通过 CLAUDE.md），让它用 Task/Explore(...) 自己管理任务分配
- `claude --resume` 和 `claude --continue` 重启会话
- 技能（Skills）可能比 MCP 更重要
    - MCP 应该是管理认证、网络和安全边界，然后退居幕后。它为智能体提供入口点，智能体随后用脚本和 markdown 上下文执行实际工作
- 对话前加`ultrathink:` 开启深度思考模式(Claude 会分配高达 32k 的 Token 进行内部推理)
- 本地与云端同步开发(貌似要 pro 用户)

```bash
# 在 claude.ai/code 网页端运行几个会话
# 利用 & 命令将本地会话"甩"给网页端后台运行
& 将这个任务转到网页端继续

# 在网页版开始新任务
# 然后在终端用 claude --teleport session_id 拉回本地
```

#### 钩子

### Codex

- `AGENTS.md` 和 `~/.agents`
- `~/.codex` 为 Codex App 的配置目录，项目目录也可放置(如`~/.codex/skills`只对该项目生效)

### Trea

- 项目开发基础模块: 登录登基础页面, 统一日志, 统一提示, 统一异常, 多语言, 日期, 币制, 主题
- MCP配置
    - Figma: 支持基于个人 Token 进行调用, 对话时提供项目链接即可
    - Firebase
- Skills技能: 新版本内置技能设置; 也可参考上文手动触发
- SOLO工作模式
    - Agent: 默认模式; 适合日常开发任务、快速解决问题
    - Plan(对话前加`/plan`触发): 先制定计划, 确认后执行; 适合复杂任务
    - Spec(对话前加`/spec`触发): 先制定详细的规格(spec.md、tasks.md、checklist.md), 再确认(可多轮对话反复修改此 spec 文件), 后执行(按上述规范文件执行); 适合大型功能开发

### Antigravity

- 文档
    - 官方文档: https://antigravity.google/docs
    - 系统提示词说明: https://liduos.com/google-antigravity-system-prompts.html
- 科学使用
    - TUN模式
    - 或者Proxifier代理: `"Antigravity.app"; "Antigravity"; "Antigravity Helper"; "language_server_macos_arm"; com.google.antigravity; com.google.antigravity.helper` 注意 language_server_macos_arm 这个服务, 不同 CPU 可能是 language_server_macos_x64
- MCP配置(AI对话框右上角3个点进入)
    - **自定义 MCP 配置**: AI对话框右上角3个点进入 - Manage MCP Servers - View raw config
    - Figma
        - 官方提供的 MCP 只能基于 Figma 桌面端的 Dev Mode MCP Server 功能实现(需要 Figma Pro 账户)
        - 可使用 https://github.com/GLips/Figma-Context-MCP 进行自定义

## HarnessEngineering驾驭工程

- [superpowers](https://github.com/obra/superpowers)
    - [superpowers-zh](https://github.com/jnMetaCode/superpowers-zh)

    ```bash
    # 进入项目目录执行后安装到项目目录. 需要提前创建好 .claude / .codex / .trae 等文件夹
    npx superpowers-zh
    ```
- [Get-Shit-Done](https://github.com/gsd-build/get-shit-done)
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) 一套可复用的 Claude Code 工程开发工作流组件库
- [OpenSpec](https://github.com/studyzy/OpenSpec-cn) 面向 AI 辅助工作流的规范驱动开发技术白皮书

## Claw

### HermesAgent‌

### OpenClaw小龙虾

- [官网](https://openclaw.ai/), [文档](https://docs.openclaw.ai/zh-CN), [github](https://github.com/openclaw/openclaw)
- [ClawHub](https://clawhub.ai/) OpenClaw 的官方技能注册平台
    - 技能推荐: https://github.com/VoltAgent/awesome-openclaw-skills
- 安装及命令
    - 参考: https://cloud.tencent.com/developer/article/2626160
    - 或基于阿里云镜像服务器: https://www.aliyun.com/activity/ecs/clawdbot
    - 模型选择
        - 使用 Qwen 进行页面认证后有一定的免费额度
        - 使用自定义模型配置阿里百炼API, 参考: https://help.aliyun.com/zh/model-studio/openclaw

```bash
# 或者使用curl安装: curl -fsSL https://openclaw.ai/install.sh | bash
# NodeJS 安装: https://nodejs.org/en/download
# 安装/更新openclaw
npm install -g openclaw@latest
# 初始化openclaw (之后会随电脑自动启动)
# 配置文件在 ~/.openclaw/openclaw.json
# 自己安装的插件在 ~/.openclaw/extensions/ 目录
# 工作空间在 ~/.openclaw/workspace/ 目录
openclaw onboard --install-daemon
# 启动网关
openclaw gateway run
openclaw gateway restart # 重启网关

## 其他命令
openclaw status # 查看状态
openclaw logs --follow # 查看日志
openclaw tui # 打开命令行UI对话界面
```
- 内网访问/宿主机访问: https://blog.csdn.net/weixin_43248394/article/details/159504854
- 不支持代理访问(web_fetch), 参考: https://github.com/openclaw/openclaw/issues/27597
    - 基于安全考虑，OpenClaw 不支持 SSRF 访问 (不允许直接访问内网, 否则可能读取到内网敏感信息)

### 消息渠道

- 微信: 微信插件
- 飞书: https://docs.openclaw.ai/zh-CN/channels/feishu
    - [安装飞书openclaw/feishu插件报错spawn EINVAL](https://developer.huawei.com/consumer/cn/blog/topic/03207503902722227) 解决后可以把全局openclaw包下的extensions/feishu文件夹删掉
    - 配置飞书渠道
        - 创建飞书应用 - 添加机器人能力 - 权限管理中添加`im:*`和`contact:contact.base:readonly` - 发布飞书应用 - 在OpenClaw中配置此 Channel 的 App ID/Secret - 重启Gateway - 飞书后台配置事件订阅 - 订阅方式: 使用长连接接收事件 - 添加事件: `im.message.receive_v1` - 重新发布飞书应用 (顺序很重要)
    - 如果是首次私聊飞书机器人，可能会回复一个配对码。此时需要在服务器上执行 `openclaw pairing approve feishu <配对码>` 完成授权
        - 没有测试成功，可以将模式改为allowlist私聊白名单，如`"channels": { "feishu": { "dmPolicy": "allowlist", "allowFrom": ["ou_1a4bfd418ae7bf556b42589d28e05586"] } }`
    - 私聊定时任务没测通过，群组的定时任务可以

### 创建多个 Agent

```bash
# 查看所有 Agent. 默认的为 main
openclaw agents list

# 创建新 Agent
openclaw agents add operation --workspace ~/.openclaw/workspace-operation
# 为每个 Agent 配置飞书渠道后重启: openclaw.json
{
  "channels": {
    "feishu": {
      "enabled": true,
      "domain": "feishu",
      "groupPolicy": "open", // 注意：生产环境建议改为 "allowlist" 以提高安全性
      "accounts": {
        "main": {
          "appId": "cli_a91be1951578dcca",
          "appSecret": "你的主应用Secret",
          "botName": "小虾米"
        },
        "operation": {
          "appId": "cli_a910c62c59b8dcb5",
          "appSecret": "你的新应用Secret",
          "botName": "运营虾"
        }
      }
    }
  },
  "bindings": [
    {
      "agentId": "main",
      "match": {
        "channel": "feishu",
        "accountId": "main"
      }
    },
    {
      "agentId": "operation",
      "match": {
        "channel": "feishu",
        "accountId": "operation"
      }
    }
  ]
}
```

### 搜索

- 搜索方案
    - [Tavily](https://app.tavily.com/): 免费额度, 日常够用
    - DuckDuckGo: 免费, 科学上网
    - SearXNG: 自建开源聚合搜索引擎(可Docker部署), 隐私高, 免费, 科学上网



