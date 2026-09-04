---
name: global-search
version: 1.0.2
description: 全网内容搜索（知乎开放平台 global_search API 的 CLI 封装），返回结构化 JSON（标题/链接/作者/摘要）。何时调用：需要可引用来源的网页搜索、搜索 MCP 不可用时的 CLI 兜底、deep-research 等流程的降级链终端。触发词：全网搜索、搜一下、搜索网页、查全网、global search、web search。何时不调用：只要知乎站内内容（用 zhihu-search）；需要网页完整正文（用 web-reader 类工具）。
homepage: ../../docs/global_search.md
metadata: {"openclaw":{"emoji":"🌐","requires":{"bins":["python3"]}}}
---

# Global Search Skill

## 概述
本 Skill 用于调用知乎开放平台的 `global_search` API。
完整的 API 文档请参考：https://developer.zhihu.com/docs

通过 OpenAPI Platform `GET /api/v1/content/global_search` 检索全网内容，并把响应整理为适合 agent 消费的精简 JSON 结构。

## 认证
使用环境变量 `ZHIHU_ACCESS_SECRET` 进行认证
用户可以在知乎开放平台控制台获取 Access Secret

可选配置：

- `ZHIHU_OPENAPI_BASE_URL`（默认：`https://developer.zhihu.com`）
- `ZHIHU_GLOBAL_SEARCH_URL`（完整 endpoint 覆盖；设置后优先于 `ZHIHU_OPENAPI_BASE_URL` + 默认 path）

## 快速开始

`{baseDir}` 是 agent 框架在运行时自动替换的变量，指向当前 skill 目录的绝对路径（即 `skills/global-search/`）。

```bash
python3 {baseDir}/scripts/global-search.py '{"query":"如何理解 rave 文化","count":8,"filter":"host==\"example.com\"","search_db":"all"}'
```

## 输入约定

传入一个 JSON 参数：

```json
{"query":"...", "count":10, "filter":"host==\"example.com\" AND publish_time>=1778494631", "search_db":"all"}
```

规则：

- `query` 必填，且不能是空字符串。
- `count` 可选；脚本会自动限制到 1-20（接口上限）。
- `filter` 可选；高级语法筛选表达式。
- `search_db` 可选；索引库选择，支持全部 `all`、实时库 `realtime`、静态库 `static`，默认 `all`。

## 输出约定

### 成功

返回 JSON，包括：

- `code`, `message`
- `item_count`
- `items[]`，包含 `title`, `summary`, `url`, `author_name`, `edit_time`

### 失败

`error` 字段为动态错误描述，常见情况：

```json
{"error":"query is required","exit_code":1}
{"error":"Invalid JSON payload","exit_code":1}
{"error":"Set ZHIHU_ACCESS_SECRET first (Bearer auth only)","exit_code":1}
{"error":"HTTP request failed (timeout or network error)","exit_code":1}
```

HTTP 非 2xx 时额外携带 `body`：

```json
{"error":"HTTP 403","body":"Forbidden","exit_code":1}
```
