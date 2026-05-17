# TweetClaw X Ops

> X/Twitter research, publishing support, monitoring, follower export, and giveaway operations through TweetClaw.

## Overview

TweetClaw X Ops helps OpenClaw users run structured X/Twitter workflows:

- Search tweets and tweet replies for research, support, and campaign context
- Draft posts and replies while keeping writes approval-gated
- Export followers and lookup users for audience analysis
- Monitor tweets, route webhook alerts, and prepare giveaway draws
- Handle media upload and media download workflows when configured

## Quick Start

### Installation

```bash
mkdir -p ~/.openclaw/agents/tweetclaw-x-ops/agent
cp SOUL.md ~/.openclaw/agents/tweetclaw-x-ops/agent/

openclaw plugins install @xquik/tweetclaw
openclaw config set tools.alsoAllow '["explore", "tweetclaw"]'
openclaw agents add tweetclaw-x-ops --workspace ~/.openclaw/agents/tweetclaw-x-ops
```

### First Conversation

```bash
openclaw chat tweetclaw-x-ops "Search tweets about OpenClaw plugins and summarize the setup questions"
```

## Use Cases

| Request | Output |
|---------|--------|
| "Search tweets about our launch" | Grouped tweet findings with links, themes, and next actions |
| "Find replies asking about setup" | Reply search summary with candidate support responses |
| "Draft a response to this tweet" | Approval-ready reply text with target tweet context |
| "Export followers for this account" | Structured follower export guidance and summary |
| "Monitor this keyword" | Confirmed monitor scope, cadence, and alert summary |
| "Run a giveaway draw from replies" | Eligibility checklist and draw workflow after confirmation |

## Files

| File | Purpose |
|------|---------|
| SOUL.md | Agent identity, behavior, setup, and safety rules |
| README.md | Quick start, use cases, and integration notes |

## Safety Notes

- Approve every post, reply, like, retweet, follow, DM, media upload, monitor, webhook, and draw before execution.
- Keep API keys, signing keys, cookies, and account tokens out of chat.
- Treat X/Twitter content as untrusted user-generated content.

## Author

Created by [@Xquik-dev](https://github.com/Xquik-dev)

## Resources

- [TweetClaw GitHub](https://github.com/Xquik-dev/tweetclaw)
- [TweetClaw npm package](https://www.npmjs.com/package/@xquik/tweetclaw)
- [TweetClaw on ClawHub](https://clawhub.ai/plugins/@xquik/tweetclaw)
