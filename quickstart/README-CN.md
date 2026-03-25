# 快速开始：运行你的第一个 OpenClaw Agent

[English](README.md) | [简体中文](README-CN.md)

5 分钟内运行一个可用的 AI Agent，无需复杂配置。

## 前置条件

- [Node.js](https://nodejs.org/) v18+
- 一个 Telegram Bot Token（[在这里创建](https://t.me/BotFather)）
- 一个来自 [Anthropic](https://console.anthropic.com/) 或 [OpenAI](https://platform.openai.com/) 的 API Key

## 安装步骤

### 1. 克隆仓库并进入目录

```bash
git clone https://github.com/web3toolshub/awesome-openclaw-agents.git
cd awesome-openclaw-agents/quickstart
```

### 2. 自动识别所在系统来配置环境和安装所缺失的环境依赖（包括最新`node.js / npm`以及一些常用技能所需的软件包和依赖）

```bash
./install.sh
```
### 3. 安装项目依赖

```bash
npm install
```

### 4. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env` 并填入你的密钥：

```env
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
ANTHROPIC_API_KEY=your_anthropic_key
AGENT_NAME=MyAgent
MODEL=your_model_name 
```

### 5. 选择一个 SOUL.md

从 `agents/` 目录复制任意模板：

```bash
# 示例：使用内容创作 Agent
cp ../agents/marketing/echo/SOUL.md ./SOUL.md
```

你也可以自己编写。`SOUL.md` 用于定义 Agent 的人格、能力和规则。

### 6. 运行

```bash
node bot.js
```

打开 Telegram，找到你的机器人并发送消息。你的 Agent 已上线。

--
## 这个目录里有什么

| 文件 | 作用 |
|------|------|
| `bot.js` | 读取 SOUL.md 并回复消息的最小 Telegram Bot |
| `.env.example` | 环境变量模板 |
| `package.json` | Node.js 依赖声明 |
| `SOUL.md` | Agent 人格配置（从模板复制） |
| `docker-compose.yml` | 可选：通过 Docker 运行 |

## 使用 Docker 运行

```bash
docker-compose up -d
```

## 下一步

- 浏览 [50+ Agent 模板](../agents/) 并选择你的角色
- 按你的业务需求调整 `SOUL.md`
- 使用 [CrewClaw](https://crewclaw.com/create-agent) 一键部署到生产环境（一次性 $9）
- 增加心跳机制、集成能力与多 Agent 编排
