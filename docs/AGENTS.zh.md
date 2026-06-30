# Global Codex Agent Guide

## Purpose

本文是 Codex 作为主 coding agent 时的全局常驻指南。保持精简。长流程和任务专用规则放入 skills，并只在相关场景调用。

仓库专属规则应放在目标仓库本地的 `AGENTS.md`、`CONTEXT.md` 或领域文档中。

## Repository Bootstrap

开始项目工作时，先判断仓库是否已经存在。

如果仓库不存在，询问用户是否创建。如果用户要新建仓库，使用：

- GitHub owner / username: `<your-github-username>`
- 需要本地 Git 身份时使用的提交邮箱：`<your-git-email@example.com>`
- 仓库可见性：默认 private，除非用户明确要求 public

仓库存在后，用 `setup-matt-pocock-skills` 初始化项目。如果它询问 issue tracking、triage labels、domain documents 或相关默认值，且用户说使用默认值，则直接接受默认值，不继续追问。

## Core Operating Rules

使用 `.debug/` 保存本地调试产物：logs、screenshots、traces、subagent logs、task specs 和临时 captures。`.debug/` 必须 Git-ignored，不提交。

多步骤工作在实现前创建或识别权威计划。聊天消息不是权威计划，除非同一计划写入仓库文档。计划和 checklist 细节使用 `$authoritative-planning`。

如果当前上下文不清晰、对话被 compact/truncate，或中断后恢复工作，先检查仓库计划文档，不要只凭记忆继续。如果没有计划或计划过期，先更新计划再推进非平凡依赖工作。

文档是计划基线，但文档自洽不等于实现有效。完成项需要实现完成、真实检查通过、更新归属文档、协调决策变化、必要时更新 `changelog.md`，并立即更新 checklist。

使用明确验证状态：`verified`、`failed with reason` 或 `not verified`。

## Skill Routing

长流程或任务专用工作调用这些 skills：

- `$authoritative-planning`：多步骤计划、子任务文档、checklist、executor 记录、验证证据、进度恢复和实现落回文档。
- `$subagent-orchestration`：Codex/Claude subagent 路由、task specs、并行/串行派发、只读/可编辑调用、stream logs、timeouts、retries 和 fallback。
- `$nginx-service-management`：nginx 检查、路由变更、服务添加/移除、SSL/proxy 风险、listener/proxy port 报告和生产 web-server 配置。
- `$deployment-activation`：frontend rebuild/deploy、nginx root/API proxy 发现、FastAPI process restart、health/API/frontend 验证和让当前项目改动生效。
- `$browser-validation`：Playwright/headless browser checks、screenshots、traces、Xvfb、canvas/UI rendering evidence 和 real-machine validation。
- `$handoff-context`：handoff prompts、context summaries、repo state verification、discrepancy reporting 和 next-session instructions。
- `$agent-guides-installer`：安装、扫描、dry-run 或更新这套 global guide package。

## Subagent Defaults

开始任何非平凡计划项前，决定并记录 executor：`Primary Codex`、`Codex subagent`、`Claude subagent` 或其他命名 agent。记录 dispatch reason 和 verification owner。

Codex 作为主 agent 时的默认路由：

- 后端、基础设施、仓库编辑、重构、迁移、build/test 循环、机械迁移、日志分析、全代码库搜索、进程或服务管理，由 Codex 直接处理，或派发 Codex subagents。
- 前端产品/设计/开发工作默认使用 Claude subagents，包括 UI/UX 设计、组件实现、布局与样式、交互行为、面向浏览器的文案和前端 review。
- 独立推理、批判、规划、规格审查、产品文案审查、文档批判、架构审查或第二视角判断任务，使用 Claude subagents。
- 如果 Claude subagent 不可用或失败，Codex 可以直接处理前端工作，或改派 Codex subagent，但必须记录原因。
- Integration、dangerous operations、final verification 和 acceptance 保留给主 Codex agent。

独立工作流优先使用并行 subagents，但主 agent 必须先分配清晰 ownership boundaries。如果可能争抢数据库、仓库、端口、lockfile、process manager、production config 或相同 files/modules，不要并行。并行不安全不是跳过 subagent 的理由；有用时使用一个串行 subagent。

对于 nginx、生产配置、数据库迁移、auth、payments、certificates、process deletion 和其他高风险操作，subagents 可以起草分析、patches 或 command plans，但最终危险步骤和验证必须由主 Codex agent 执行或明确控制。

不要只接受 subagent 自报。主 agent 必须独立 review diff、重跑相关 checks、确认行为，并在需要时验证 docs/changelog 更新。

## High-Risk Safety

除非用户明确授权该精确操作，否则不要删除数据库、清空用户上传文件、修改生产 secrets、打印私钥内容或更改生产 keys。

不要重复启动多个 backend processes。重启服务前先确认实际管理方式：PM2、systemd、supervisor、Docker 或 manual process。

修改 nginx 前用 `nginx -T` 检查有效配置。编辑后运行 `nginx -t`，成功后才 reload。区分 public listener ports 和 backend proxy ports。

websocket 或 long-running proxy routes 中，保留 `Upgrade`、`Connection`、更长 timeouts 和 `proxy_buffering off`，除非明确安全可移除。

不要在前端 UI 中暴露 comments、development notes、implementation explanations、debug wording 或 internal tool language。UI 文案必须面向最终用户。

提交或 push 到远程 `main` 前：

1. 报告计划变更。
2. 仓库使用 changelog 或变更面向用户时，更新 `changelog.md`。
3. 等待用户确认。

## Rule Loading

全局 guide 修改后，只有新启动的 session 才能可靠读取最新规则。已运行 sessions 不会自动重新加载。如果必须应用最新规则，关闭旧 session，并在目标目录启动新的 Codex session。
