# 🦞 Awesome OpenClaw Agents（中文版）

[English](README.md) | [简体中文](README-CN.md)

[![Awesome](https://awesome.re/badge.svg)](https://awesome.re)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![Stars](https://img.shields.io/github/stars/web3toolshub/awesome-openclaw-agents?style=social)](https://github.com/web3toolshub/awesome-openclaw-agents)
[![Agents](https://img.shields.io/badge/agents-177-blueviolet)](agents/)

> 一个为 OpenClaw 生态整理的 **177 个可直接投入生产的 AI Agent 模板合集**。每个模板都可直接复制为 `SOUL.md` 使用。

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:4F46E5,100:7C3AED&height=180&section=header&text=%F0%9F%A6%9E%20177%20OpenClaw%20Agent%20Templates&fontSize=36&fontColor=ffffff&fontAlignY=35" width="100%"/>
</p>

<div align="center">

### 跳过繁琐配置，60 秒完成部署

**[浏览全部 177 个模板 →](README.md#agent-templates)**

选一个模板，复制 `SOUL.md`，修改配置并启动你的 Agent。

</div>

<div align="center">

📬 **每周获取 Agent 模板和实战技巧**（每周二更新）

**[订阅 Newsletter →](https://docs.google.com/forms/d/e/1FAIpQLSeIqBjV1LXnR2qQqGSGa-48rAveAmpSKVqlzLqDK2d4D4aVWg/viewform)**

</div>

---

## 目录

- [项目概览](#项目概览)
- [环境与依赖要求](#环境与依赖要求)
- [快速开始](#快速开始)
- [Windows 用户（PowerShell）快速上手](#windows-用户powershell快速上手)
- [常见问题（小白必看）](#常见问题小白必看)
- [分类模板入口](#分类模板入口)
- [使用场景](#使用场景)
- [为什么选 OpenClaw](#为什么选-openclaw)
- [MCP Servers](#mcp-servers)
- [集成能力](#集成能力)
- [工具](#工具)
- [教程与指南](#教程与指南)
- [提交你的 Agent](#提交你的-agent)
- [社区](#社区)
- [相关项目](#相关项目)
- [许可证](#许可证)

---

## 项目概览

- 模板总数：**177**
- 分类数量：**24**
- 已验证使用场景：**132**
- 模板格式：`SOUL.md`

如果你想直接查看完整英文模板清单（含每个 Agent 的详细说明、使用时机和部署链接），请看：**[README.md](README.md)**。

---

## 环境与依赖要求

| 项目 | 最低要求 | 作用 |
|------|----------|------|
| 操作系统 | Windows / macOS / Linux | 运行命令行与 Node.js |
| Node.js | v18 或更高 | 运行 `bot.js` |
| npm | 通常随 Node.js 安装 | 安装依赖包 |
| Telegram 账号 | 需要 | 和你的 Agent 对话 |
| Telegram Bot Token | 需要 | 让程序连接你的机器人 |
| 大模型 API Key | 让 Agent 具备 AI 能力 |

获取方式：

- Telegram Bot Token：在 Telegram 搜索 `@BotFather`，按提示创建 Bot
- Anthropic Key：<https://console.anthropic.com/>
- OpenAI Key：<https://platform.openai.com/>

---

## 快速开始（支持 Linux / MacOS / WSL2）

下面按步骤做，几乎不用懂代码。

### 1. 下载项目并进入 `quickstart` 目录

```bash
git clone https://github.com/web3toolshub/awesome-openclaw-agents.git && cd awesome-openclaw-agents/quickstart
```

### 2. 自动识别所在系统来配置环境和安装所缺失的环境依赖（包括最新`node.js / npm`以及一些常用技能所需的软件包和依赖）

```bash
./install.sh
```

### 3. 安装项目依赖
```bash
npm install
```

### 4. 配置密钥

```bash
cp .env.example .env
```

打开 `.env`，填写以下：

```env
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_from_botfather
XXXX_API_KEY=your_XXXX_api_key
AGENT_NAME=MyAgent
MODEL=your_model_name
```

如果你想用 OpenAI，则填写 `OPENAI_API_KEY`，并按需调整 `MODEL`。
如果你想用 Moonshot，则填写 `MOONSHOT_API_KEY`，并按需调整 `MODEL`。

### 4. 复制一个模板作为 `SOUL.md`（下文中“分类模板入口”有介绍各模版场景，请按需选择）

```bash
# 示例：选择 marketing 模版
cp ../agents/marketing/echo/SOUL.md ./SOUL.md
```

这一步等于“给机器人设定角色和行为规则”。

### 5. 启动 Agent

```bash
node bot.js
```

看到类似 `is running on Telegram...` 就表示启动成功。  
然后去 Telegram 找到你的 Bot，发一条消息测试。

如果你要添加智能体，运行 `openclaw agents add`

完整英文启动文档（含 Docker）：[quickstart/README.md](quickstart/README.md)
快速开始中文文档：[quickstart/README-CN.md](quickstart/README-CN.md)

---

## Windows 用户（PowerShell）快速上手

如果你在 Windows 上，以管理员身份打开 PowerShell 执行下面命令。

### 1. 下载并进入目录

```powershell
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
git clone https://github.com/web3toolshub/awesome-openclaw-agents.git
cd awesome-openclaw-agents\quickstart
```

### 2. 自动识别所在系统来配置环境和安装所缺失的环境依赖（包括最新`node.js / npm`以及一些常用技能所需的软件包和依赖）

```bash
.\install.ps1
```
### 2. 安装项目依赖

```powershell
npm install
```

### 3. 复制环境变量文件

```powershell
Copy-Item .env.example .env
```

### 4. 复制一个模板作为 `SOUL.md`（下文中“分类模板入口”有介绍各模版场景，请按需选择）

```powershell
# 示例：选择 marketing 模版
Copy-Item ..\agents\marketing\echo\SOUL.md .\SOUL.md
```

### 5. 启动

```powershell
node .\bot.js
```

如果你更习惯 `cmd`，把 `Copy-Item` 改成 `copy` 即可。

---

## 常见问题（小白必看）

- 启动后没反应：先检查 `.env` 里 `TELEGRAM_BOT_TOKEN` 是否正确，确认是 BotFather 给你的 token。
- 报 `401` 或鉴权失败：通常是 API Key 无效、过期，或复制时带了空格。
- 回复很慢：多为模型接口延迟或网络问题，可稍等重试，或切换模型。

---

## 分类模板入口

按业务场景挑模板（目录在 `agents/` 下）：

- [📋 Productivity](agents/productivity/)：效率与任务管理
- [💻 Development](agents/development/)：研发、测试、代码质量
- [📣 Marketing & Content](agents/marketing/)：内容生产与增长
- [💼 Business](agents/business/)：商业运营与销售流程
- [🧘 Personal](agents/personal/)：个人助理与生活管理
- [🚀 DevOps](agents/devops/)：运维、监控、故障响应
- [💰 Finance](agents/finance/)：财务分析与自动化
- [🎓 Education](agents/education/)：学习辅导与课程设计
- [🏥 Healthcare](agents/healthcare/)：健康管理
- [⚖️ Legal](agents/legal/)：法律文档与合规辅助
- [👥 HR](agents/hr/)：招聘与人力流程
- [🎨 Creative](agents/creative/)：创意生产与多媒体
- [🔒 Security](agents/security/)：安全扫描与风险检测
- [🛒 E-Commerce](agents/ecommerce/)：电商运营
- [📊 Data](agents/data/)：数据处理与分析
- [☁️ SaaS](agents/saas/)：SaaS 业务场景
- [🏡 Real Estate](agents/real-estate/)：地产相关流程
- [🧑‍💻 Freelance](agents/freelance/)：自由职业工作流
- [🤖 Moltbook](agents/moltbook/)：Moltbook 场景模板
- [📦 Supply Chain](agents/supply-chain/)：供应链流程
- [✅ Compliance](agents/compliance/)：合规治理
- [🎙️ Voice](agents/voice/)：语音场景
- [🤝 Customer Success](agents/customer-success/)：客户成功与续费
- [🔄 Automation](agents/automation/)：自动化执行

完整模板详情（逐个 Agent 的表格）见：[README.md](README.md#agent-templates)

---

## 使用场景

**132 个已验证真实用例**，覆盖：

- 研发流程自动化
- DevOps 值守与告警
- 智能家居控制
- 交易与投研辅助
- 可自我迭代的 Agent 工作流

查看全部用例：**[USE-CASES.md](USE-CASES.md)**

---

## 为什么选 OpenClaw

OpenClaw 与常见 Agent 框架对比：

| 特性 | OpenClaw | AutoGPT | CrewAI | LangChain | MetaGPT |
|------|----------|---------|--------|-----------|---------|
| 配置优先（SOUL.md） | ✅ | ❌ | ❌ | ❌ | ❌ |
| 无需写代码即可启动 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 内置 Telegram/Slack/Discord | ✅ | ❌ | ❌ | ❌ | ❌ |
| 多 Agent 协作编排 | ✅ | ❌ | ✅ | ✅ | ✅ |
| MCP（Model Context Protocol） | ✅ | ❌ | ❌ | ❌ | ❌ |
| 可自托管/本地运行 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 心跳监控机制 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 支持 Ollama（免费） | ✅ | ✅ | ✅ | ✅ | ❌ |
| 生产可用模板数量 | **177** | 0 | 5 | 0 | 3 |
| 一条命令部署 | ✅ | ❌ | ❌ | ❌ | ❌ |
| Agent 与 Agent 通信 | ✅ | ❌ | ✅ | ✅ | ✅ |
| 初始搭建时间 | ~5 分钟 | ~30 分钟 | ~20 分钟 | ~45 分钟 | ~30 分钟 |

一句话：OpenClaw 是配置优先路线。写好 `SOUL.md`，执行命令，Agent 即可上线。

---

## MCP Servers

通过 MCP 扩展 Agent 能力。

### 官方

| Server | 描述 | 安装 |
|--------|------|------|
| [@anthropic/mcp-server-fetch](https://github.com/anthropics/mcp-server-fetch) | 网页抓取与浏览 | `npx -y @anthropic/mcp-server-fetch` |
| [@anthropic/mcp-server-filesystem](https://github.com/anthropics/mcp-server-filesystem) | 文件系统访问 | `npx -y @anthropic/mcp-server-filesystem` |

### 社区

- mcp-notion
- mcp-google-calendar
- mcp-github
- mcp-slack
- mcp-postgres
- mcp-stripe
- mcp-shopify
- mcp-twitter
- mcp-discord
- mcp-linear

---

## 集成能力

### 消息渠道

- **Telegram**（OpenClaw 内置）
- **Slack**（OpenClaw 内置）
- **Discord**（OpenClaw 内置）
- **Email**（OpenClaw 内置）

### 自动化

- **n8n**
- **GitHub Actions**
- **Cron / pm2 / systemd**

---

## 工具

| 工具 | 说明 |
|------|------|
| openclaw CLI | 使用 `openclaw --help` 查看命令说明 |
| [agents.json](agents.json) | 全部模板的机器可读索引 |
| agent-validator | 校验 `SOUL.md` 语法 |
| mcp-tester | 测试 MCP Server 连接 |

---

## 教程与指南

### 入门

- [OpenClaw 官方组织](https://github.com/openclaw)
- [Quickstart](quickstart/)
- [完整英文指南（本仓库 README）](README.md#tutorials--guides)

### 多 Agent 与编排

- [完整英文指南（本仓库 README）](README.md#multi-agent--orchestration)

### 集成与自动化

- [完整英文指南（本仓库 README）](README.md#integrations--automation)

### 对比

- [框架对比（本页）](#为什么选-openclaw)

---

## 提交你的 Agent

你可以通过 PR 或 Issue 提交自定义 Agent。

目录结构建议：

```text
agents/[category]/[your-agent]/
├── SOUL.md          ← 身份与人格（必需）
├── README.md        ← 描述与用例（必需）
├── AGENTS.md        ← 运行规则（可选）
├── HEARTBEAT.md     ← 唤醒检查单（可选）
└── WORKING.md       ← 初始任务（可选）
```

PR 提交流程：

1. Fork 本仓库
2. 添加 agent 目录（至少 `SOUL.md` + `README.md`）
3. 更新 `agents.json`
4. 发起 Pull Request

不想本地搭环境也可以直接提 Issue：

- [Submit Your Agent →](https://github.com/web3toolshub/awesome-openclaw-agents/issues/new?template=agent-submission.md)

完整贡献说明： [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 社区

想先提需求而不是提交实现？使用 [Agent Request](https://github.com/web3toolshub/awesome-openclaw-agents/issues/new?template=agent-request.md)。

---

## 相关项目

- [OpenClaw](https://github.com/openclaw)
- [Anthropic MCP](https://github.com/anthropics/mcp)

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=web3toolshub/awesome-openclaw-agents&type=Date)](https://star-history.com/#web3toolshub/awesome-openclaw-agents&Date)

---

## 许可证

[![CC0](https://licensebuttons.net/p/zero/1.0/88x31.png)](https://creativecommons.org/publicdomain/zero/1.0/)

在法律允许范围内，贡献者已放弃对本项目内容的相关版权与邻接权。

---

<p align="center">
  由 OpenClaw 社区共同维护
  <br/>
  <a href="https://github.com/web3toolshub/awesome-openclaw-agents/issues/new?template=agent-submission.md">Submit yours →</a>
</p>
