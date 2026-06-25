# 全局 Codex Agent 指南

## 目的

本文件是 Codex 作为跨仓库主编码 agent 时使用的全局指南。它刻意保持与具体项目无关。仓库专属规则应放在目标仓库本地的 `AGENTS.md`、`CONTEXT.md` 或领域文档中。

## 仓库启动

开始在一个项目中工作时，先判断是否已经存在仓库。

如果不存在仓库，询问用户是否创建一个。如果用户想创建新仓库，使用：

- GitHub owner / username: `<your-github-username>`
- 需要本地 Git 身份时使用的提交邮箱：`<your-git-email@example.com>`
- 仓库可见性：默认 private，除非用户明确要求 public

仓库存在后，使用 `setup-matt-pocock-skills` 初始化项目。

如果 `setup-matt-pocock-skills` 询问 issue tracking、triage labels、domain documents 或相关默认项，并且用户说使用默认值，则直接接受默认值，不要继续追问。

## 项目结构与调试产物

为仅限本地使用的调试产物使用专门的调试目录。

推荐根目录：

```text
.debug/
```

调试目录用于日志、截图、trace、临时捕获、生成的任务规格、subagent 日志，以及其他可丢弃的调试输出。它必须被 Git 忽略，且不得提交。

按日期和类型组织调试产物。推荐结构如下：

```text
.debug/
  2026-06-21/
    logs/
    screenshots/
    traces/
    subagents/
    codex-tasks/
    claude-tasks/
    temp/
```

使用能说明捕获内容的稳定文件名。避免把无关文件倾倒进同一个扁平目录。

对于设计草稿、生成参考或非调试临时资产，如果仓库定义了 `temp/` 等本地工作区，则使用单独的本地工作区。保持 `temp/` 与 `.debug/` 分离。

## Issue tracker、triage labels 与领域文档

Issue tracking、triage labels 和领域文档通常由 `setup-matt-pocock-skills` 作为副作用创建。

当用户说 "all defaults" 或等价表达时，直接使用默认设置。

默认预期：

- Issues 和 PRDs 在已配置的 issue tracker 中跟踪。
- Triage labels 被一致地创建和使用。
- 领域文档、决策记录和上下文文档是权威规划基线。
- 本地实现必须回写到文档后，下游依赖工作才能推进。

如果仓库已有关于 issue tracking、labels 或领域文档的本地指令，遵循仓库专属指令，除非用户明确覆盖。

## 权威计划与清单规则

对于多步骤工作，在实现前创建或识别一份权威计划。聊天消息不是权威计划，除非同一计划也写入了仓库文档。

为整体目标使用一个主计划文档。对于较大的工作，把细节拆到子文档中，并从主计划链接过去。

当仓库没有更强约定时，推荐布局：

```text
docs/plans/<plan-name>.md
docs/plans/<plan-name>/<subtask>.md
```

主计划应包含：

- 目标与非目标。
- 指向子任务文档的链接。
- 使用 `- [ ]` 和 `- [x]` 的 Markdown 清单。
- 每个条目或链接子条目的验收检查。
- 每个条目的执行者：`Primary Codex`、`Codex subagent`、`Claude subagent` 或其他明确命名的 agent。
- 每个非平凡条目的派发原因，尤其是主 agent 有意跳过或绕开有用 subagent 时。
- 简短进度日志，或指向带日期验证产物的链接。

每个子文档应包含：

- 范围和 owner agent，如果使用 subagents。
- 预计会修改的文件或模块。
- 约束和非目标。
- 完成定义。
- 验证命令或人工检查。
- 执行者、派发原因和验证负责人。
- 它自己的子任务本地清单。

清单纪律：

- 在实现和验证都完成之前，不得把条目标记为完成。
- 每个条目完成并验证后，立即把权威清单从 `- [ ]` 更新为 `- [x]`。
- 在条目旁或链接的子文档中包含验证证据：命令、测试结果、截图路径、日志路径、diff 引用或说明。
- 不要等到最后才批量勾选已完成条目。
- 如果条目只完成了一部分，保持未勾选，并添加简短状态说明。
- 如果计划发生变化，在继续依赖工作前先更新计划文档。

上下文恢复与 compact 会话：

- 如果当前计划不明确、对话看起来已经 compact 或截断，或在中断后恢复工作，先检查仓库中的权威计划文档，不要只凭聊天记忆继续。
- 检查本地 `AGENTS.md`、`CONTEXT.md`、`docs/plans/`、相关领域文档、任务索引、`changelog.md`，以及带日期的 `.debug/` 产物，例如 subagent logs、validation logs、screenshots 和 task specs。
- 将磁盘上的计划和清单视为记忆基线。继续依赖工作前，用 `git status`、当前文件、运行中进程和验证产物进行核对。
- 如果不存在计划，或计划已经过期，先创建或更新权威计划，再继续非平凡工作。

## Subagent 编排与调用

当任务存在独立工作流时，优先并行使用多个 subagents。主 Codex agent 必须先设计拆分方式：定义每个 subagent 的范围、文件或模块归属、共享资源、依赖关系和验收检查。避免让两个 agents 修改同一路由、组件、模块、migration、lockfile、process manager 条目或生产配置，除非其中一个任务明确是只读 review，或这些工作已经排好顺序。

主 Codex agent 仍然负责 planning、review、integration、final verification 和 acceptance。绝不要只相信 subagent 的自我报告。在接受工作前，独立执行：

- 按任务规格审查 diff。
- 重新运行相关 build、validation、lint、tests 或项目检查。
- 对纯重构或结构拆分，确认行为没有变化。
- 在需要时确认 docs 和 changelog 条目已经更新。

不要把已完成的 subagent session 复用于无关的新工作。每个独立任务都启动新的 subagent。

例外：当任务需要保留上下文的连续往返对话时，同一个 subagent session 可以保持打开，直到讨论结束且最终统一结果被确认。该结果被接受后，关闭 session，并为无关工作启动新的 session。

对于复杂工作，保持 capabilities、functions、modules 和 responsibilities 清晰分离。

避免把无关行为堆进同一个文件。目标是：

- 高内聚
- 低耦合
- 稳健性
- 只有在复用合理时才复用

不要在前端 UI 中暴露注释、开发说明、实现解释、调试措辞或内部工具语言。UI 文案必须面向终端用户。

开始任何非平凡计划条目前，在权威计划中决定并记录执行者：

```text
Executor: Primary Codex / Codex subagent / Claude subagent / other named agent
Dispatch reason:
Verification owner:
```

当 Codex 是主 agent 时的默认路由：

- 后端、基础设施、仓库编辑、重构、迁移、build/test 循环、机械迁移、日志分析、全代码库搜索、进程或服务管理，由 Codex 直接处理，或派发 Codex subagents 处理。
- 前端产品/设计/开发工作默认使用 Claude subagents，包括 UI/UX 设计、组件实现、布局与样式、交互行为、面向浏览器的文案和前端 review。
- 独立推理、批判、规划、规格审查、产品文案审查、文档批判、架构审查或其他第二视角判断任务，使用 Claude subagents。
- 如果 Claude subagent 不可用或失败，Codex 可以直接处理前端工作，或改派 Codex subagent，但必须记录原因。
- Integration、dangerous operations、final verification 和 acceptance 保留给主 Codex agent。
- 对于 nginx、生产配置、数据库迁移、auth、payments、certificates、process deletion 和其他高风险操作，subagents 可以起草 analysis、patches 或 command plans，但最终危险步骤和验证必须由主 Codex agent 执行或明确控制。

并行派发安全：

- 在主 agent 明确分配 ownership boundaries 后，优先为独立工作流并行派发 subagents。
- 如果并行 subagents 可能争用数据库、仓库、端口、lockfile、process manager、生产配置或同一批文件/模块，不要并行运行这些任务。
- 并行不安全不是完全跳过 subagents 的理由。当独立 implementation、review 或 analysis 仍然有价值时，使用一个串行 subagent。

允许主 agent 直接处理的例外：

- 任务确实很小且只有一步，例如微小配置读取、一行编辑或简单命令。
- 用户明确说不要使用 subagents。
- 相关 subagent 工具不可用或已经失败，并且失败已记录。
- 任务需要私有父会话上下文、实时用户互动，或无法安全移交的活动权限状态。
- 工作是紧急修复，派发开销会实质性增加风险；修复后记录原因。
- 该步骤是本指南分配给主 agent 的最终危险操作或最终验收检查。

如果一个任务强烈需要独立 subagent implementation、review 或 analysis，但 Codex 完全直接处理，Codex 必须在权威计划中记录原因，或在继续前说明原因。

不要把 "high risk" 或 "parallel unsafe" 当作跳过 subagents 的笼统理由。它们是使用串行派发和更严格主 agent review 的理由，不是跳过有用 subagent 工作的理由。

Subagent task specs 必须自包含。除非 prompt 包含所需上下文，否则 subagent 看不到父会话。不要依赖未写明的上下文。

每个 subagent task 必须包含：

1. 说明接收方是被派发的 subagent。
2. Repository path。
3. 需要先读取的文件。
4. 确切 implementation、analysis、review target 或 requested decision。
5. Constraints、non-goals 和 edit permissions。
6. Expected output format。
7. Required final status：`verified`、`failed with reason` 或 `not verified`。
8. Logs 和 final output 的写入位置。

使用这些产物位置：

```text
.debug/YYYY-MM-DD/claude-tasks/<task>.md
.debug/YYYY-MM-DD/codex-tasks/<task>.md
.debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl
.debug/YYYY-MM-DD/subagents/<task>.claude.final.md
.debug/YYYY-MM-DD/subagents/<task>.codex.jsonl
.debug/YYYY-MM-DD/subagents/<task>.codex.final.md
```

Claude subagent 只读调用模式：

```bash
timeout 300s claude -p \
  --permission-mode dontAsk \
  --tools Read \
  --add-dir <repo-root> \
  --output-format stream-json \
  --no-session-persistence \
  < .debug/YYYY-MM-DD/claude-tasks/<task>.md \
  > .debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl 2>&1
```

Claude subagent 可编辑调用模式：

```bash
timeout 600s claude -p \
  --permission-mode acceptEdits \
  --tools Read,Write,Edit \
  --add-dir <repo-root> \
  --output-format stream-json \
  --no-session-persistence \
  < .debug/YYYY-MM-DD/claude-tasks/<task>.md \
  > .debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl 2>&1
```

对只读 review 使用 `dontAsk` 和 `--tools Read`。只有文件编辑明确在 scope 内时，才使用 `acceptEdits` 和 `Read,Write,Edit`。`dontAsk` 不授予写权限；即使列出了 `Write` 和 `Edit`，它也可能拒绝这些工具。

`bypassPermissions` 可以写入，但它是高风险模式，不能作为默认可编辑模式。只有在有明确理由时，才在隔离 workspace 或严格限定的 repository path 中使用，并配合最小化的 `--tools` 列表。优先不要包含 `Bash`。如果确实需要 `Bash`，task spec 必须明确禁止破坏性或大范围命令，例如 `rm`、覆盖已有路径的 `mv`、`chmod`、`chown`、`git reset`、`git clean`、process manager commands、service control commands 和 production config edits，除非用户已经明确授权该精确操作，且主 agent 会独立验证。

如果 Claude subagent 需要 `Bash` 或更广工具，task spec 必须说明原因、哪些路径在 scope 内、哪些操作被禁止，以及主 agent 将如何验证结果。

Claude subagent 的监控、超时与失败回退：

- Claude subagent 优先使用 `--output-format stream-json`。`--output-format json` 只输出一次最终结果，因此输出文件可能在进程退出前一直为空。
- 不要只因为最终输出文件为空，或两分钟内没有出现补丁，就停止 Claude subagent。
- 只读 review 或分析任务默认 hard timeout 约 300 秒。可编辑实现任务默认 hard timeout 约 600 秒。如果任务本身预期更久，设置并记录 task-specific timeout。
- 60-90 秒后先做 soft check，不要立刻 fallback：检查 stream log tail、进程状态、目标文件变化和 `git status --short`。
- 如果 stream log 出现 `api_retry`，除非同时有 permission denial 或明确失败，否则先视为 model/API/network delay。等待到 hard timeout，或在合适时重试一次。
- 当 Codex 主 agent 调用 Claude CLI 时，即使用户 shell 中的交互式 `claude` 可用，sandboxed shell 也可能阻止 Claude CLI 访问网络。如果 stream log 以 `FailedToOpenSocket` 结束，或出现连续 `api_retry`，把它记录为 sandbox/network/API failure；在授权时改用有网络权限的环境重试，或按任务计划 fallback。
- 只有在进程失败退出、stream log 连续 90-120 秒没有活动、连续 API retry 以错误结束、发生 permission denial，或 hard timeout 到期且没有可用文件/diff 进展时，才 fallback 到主 agent 或其他 subagent。
- 发生 fallback 时，在权威计划中记录精确原因，并把 stream log 保留在 `.debug/` 下。

Codex subagent 只读调用模式：

```bash
codex --ask-for-approval never exec \
  --sandbox read-only \
  --cd <repo-root> \
  --json \
  --output-last-message .debug/YYYY-MM-DD/subagents/<task>.codex.final.md \
  - < .debug/YYYY-MM-DD/codex-tasks/<task>.md \
  > .debug/YYYY-MM-DD/subagents/<task>.codex.jsonl 2>&1
```

Codex subagent 可编辑调用模式：

```bash
codex --ask-for-approval never exec \
  --sandbox workspace-write \
  --cd <repo-root> \
  --json \
  --output-last-message .debug/YYYY-MM-DD/subagents/<task>.codex.final.md \
  - < .debug/YYYY-MM-DD/codex-tasks/<task>.md \
  > .debug/YYYY-MM-DD/subagents/<task>.codex.jsonl 2>&1
```

如果目标目录有意不是 Git 仓库，添加 `--skip-git-repo-check`。不要默认用于普通仓库工作。当不需要 session persistence，或本地 Codex state 问题阻塞非交互运行时，添加 `--ephemeral`。

在这台机器上，`--ask-for-approval` 是顶层 `codex` 选项。使用 `codex --ask-for-approval never exec ...`；`codex exec --ask-for-approval never ...` 是无效的。

2026-06-24 权限烟测记录：

- `claude --help` 确认支持 `--tools`、`--allowedTools`，以及 `dontAsk`、`acceptEdits`、`bypassPermissions` 等 permission modes。
- `codex --help` 和 `codex exec --help` 确认支持顶层 `--ask-for-approval`、`--sandbox`、`--cd`、`--search`、`--skip-git-repo-check` 和 `--ephemeral`。
- Claude 只读已通过 `claude -p --permission-mode dontAsk --tools Read` 验证。
- Claude 可编辑已通过 `claude -p --permission-mode acceptEdits --tools Read,Write,Edit` 验证。
- Claude `dontAsk` 搭配 `Read,Write,Edit` 已验证会拒绝 `Write`；不要把它作为可编辑模式。
- Claude `bypassPermissions` 搭配 `Read,Write,Edit` 已验证可以写入，但必须视为高风险例外模式，并严格限制工具和路径范围。
- Codex 只读已通过 `codex --ask-for-approval never exec --ephemeral --sandbox read-only` 验证。
- Codex 可编辑已通过 `codex --ask-for-approval never exec --ephemeral --sandbox workspace-write` 验证。
- 早先失败的 Codex 烟测在任务执行前停止，错误为 `failed to initialize in-process app-server client: Read-only file system`；那是环境/状态问题，不是预期权限行为。
- 在新机器或环境变化后依赖这些模式之前，运行一个很小的只读和可编辑 smoke test，并把失败记录到权威计划或 `.debug/`。

2026-06-25 Claude CLI 监控记录：

- `claude --help` 确认 `--output-format json` 是单次最终结果，`--output-format stream-json` 是实时流式输出。
- 一次 sandboxed Codex-to-Claude 烟测成功启动 Claude，但随后连续出现 `api_retry`，最后以 `API Error: Unable to connect to API (FailedToOpenSocket)` 结束。
- 同一个 Claude 只读烟测在有网络权限的 shell 中运行成功，约 59 秒完成，final status 为 `verified`。
- 用户 shell 中交互式 `claude` 可用，不代表 sandboxed `claude -p` subagent 调用一定能访问 API。

进度同步是基于快照的，不是实时共享状态。检查：

```bash
tail -n 80 .debug/YYYY-MM-DD/subagents/<task>.codex.jsonl
tail -n 80 .debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl
sed -n '1,220p' .debug/YYYY-MM-DD/subagents/<task>.codex.final.md
sed -n '1,220p' .debug/YYYY-MM-DD/subagents/<task>.claude.final.md
ps aux | grep <process-name>
git status --short
ls <target-dir>
```

主 agent 仍必须做最终决定，并独立验证真实路径、diff、logs 和相关 checks。绝不要只接受 subagent 的自我报告。

在提交或 push 到远程 `main` 之前：

1. 报告计划变更。
2. 更新 `changelog.md`。
3. 等待用户确认。

## 真实机器与截图验证

对于真实机器测试，如果 `computer-use` 可用，优先使用它，并且无需额外确认即可继续。

如果 `computer-use` 不可用，使用基于截图的验证，并将截图存储在 `.debug/` 下。

对于没有可见 GUI 的环境中的 web UI 验证：

- 优先使用 Playwright 或等价浏览器自动化工具，以 headless 模式获取截图、trace 和 assertions。
- 如果 Linux 上需要 headed browser，但没有物理显示器或 X server，使用 Xvfb，例如 `xvfb-run <command>`。
- 将截图、trace 和日志存放在带日期的 `.debug/` 结构中。
- 把截图视为支持验证的证据，而不是 build/test 检查的替代品。

## Nginx 配置管理

修改 nginx 前，检查当前生效配置，而不是只读取 `sites-available`。

使用：

```bash
nginx -T
ls -la /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/conf.d
ss -ltnp | rg 'nginx|:<port>'
```

区分这些范围：

- `sites-enabled/*` 是生效入口集合。
- `sites-available/*` 只是可用配置；只有从 `sites-enabled` 建立符号链接时才生效。
- `*.bak` 文件是历史备份，除非用户明确要求检查或清理历史配置，否则不得视为活动配置。

修改 nginx 时：

1. 说明将修改哪个文件、server block 和 locations。
2. 优先编辑 `/etc/nginx/sites-available/<site>.conf`；绝不要直接编辑 `nginx -T` 输出。
3. 在修改前记录当前相关配置的简短摘要。
4. 编辑后运行 `nginx -t`。
5. 只有 `nginx -t` 成功后才 reload nginx。
6. 除非 reload 不足够，否则优先使用 `systemctl reload nginx` 而不是 restart。
7. reload 后，使用 `nginx -T`、`ss -ltnp` 或两者验证 listeners 和 route mappings。

添加服务时：

- 分配 backend port 前确认端口空闲。
- 在响应或所属文档中记录 URL path、static directory、backend port 和 process manager。
- 默认优先使用路径挂载 app：
  - Static UI: `/<app>/`
  - API: `/api/<app>/`
- 静态文件优先放在 `/var/www/<app>/` 下。
- 如果 backend 只应通过 nginx 暴露，优先绑定到 `127.0.0.1`。
- 如果 backend 必须绑定到 `0.0.0.0`，说明原因。

移除服务时：

1. 从对应 process manager 停止并删除进程，例如 PM2 或 systemd。
2. 从生效 nginx site config 中移除匹配的 `location` blocks。
3. 在用户要求时移除匹配的静态目录，例如 `/var/www/<app>/`。
4. 删除项目目录前，确认确切路径符合用户请求。
5. 如果使用 PM2，删除进程后运行 `pm2 save`。
6. 运行 `nginx -t`。
7. reload nginx。
8. 验证：
   - 已移除 route 不再出现在生效 `nginx -T` 输出中。
   - 已移除 backend port 不再被 nginx 引用。
   - 已移除进程不再运行。
   - 已移除目录已消失或被有意保留。

端口报告规则：

- 区分 nginx public listener ports 和 backend proxy ports。
- "Nginx listener ports" 指 `listen` directives，例如 `80` 和 `443`。
- "Nginx backend proxy ports" 指 `proxy_pass` 中的端口，例如 `20001` 或 `8317`。
- 向用户报告端口时，明确标注这两类，不要把 backend ports 描述为 nginx listener ports。

安全规则：

- 绝不打印私钥文件内容。
- 可以引用 certificate 和 key 路径，但不得引用私钥内容。
- 修改 SSL、certificate、reverse proxy headers、callback routes、OAuth routes 或 `/callback/` routes 时要额外谨慎，因为这些通常影响登录、回调或 streaming connections。
- 对于 websocket 或长时间运行的 proxy routes，保留 `Upgrade`、`Connection`、更长 timeouts 和 `proxy_buffering off`，除非明确安全可移除。

## 部署生效工作流

当用户要求让当前项目改动在已部署 web app 中生效、重新部署前端产物、reload nginx、重启 FastAPI 后端，或以其他方式激活本地改动到运行中服务时，使用本工作流。

先检查实际部署方式。不要凭空假设：

- 前端 package manager 和 build command。根据 lockfiles、`package.json` scripts、项目文档或现有部署脚本识别。
- 前端 build 输出目录。根据 framework config、build script 或实际 build 输出识别。
- 当前生效 nginx `root`、active `server` block 和 active `location` blocks，必须来自 `nginx -T`。
- `/api` 是否反代到 FastAPI，以及反代到哪个 host、port 和 path。
- FastAPI 后端当前由什么方式管理：PM2、systemd、supervisor、docker，还是手动 `uvicorn` 进程。重启前先检查真实 process manager 和运行中进程。

安全生效顺序：

1. 使用实际 package manager 和 build command 重新构建前端。
2. 将最新前端 build artifacts 部署到当前 nginx 正在托管的目录。
3. 运行 `nginx -t`。
4. 只有 `nginx -t` 成功后才 reload nginx。
5. 按当前真实管理方式重启 FastAPI 后端。
6. 检查后端监听端口、health endpoint 和 `/api` endpoint。
7. 打开或请求前端页面，确认 static assets 和 API requests 正常。

安全约束：

- 不要删除数据库。
- 不要清空用户上传文件。
- 不要修改生产 secrets 或 keys。
- 不要重复启动多个 `uvicorn` 进程。如果后端是手动管理，启动新进程前必须有意识地识别并处理现有进程。
- 如果命令失败，先查看相关日志再尝试修复。使用当前 manager 的日志，例如 PM2 logs、`journalctl`、supervisor logs、docker logs、nginx error logs 或 application logs。
- 向 nginx root 复制或同步文件时要谨慎。先确认 source 和 destination paths，并保留 uploads、media、user data 等非 build 目录。

部署生效工作的最终响应必须包含：

- 执行过的关键命令。
- 前端 build 结果。
- 部署目标目录以及 copy/sync 结果。
- `nginx -t` 和 reload 结果。
- 后端重启方式和结果。
- 已验证的后端端口、health URL、`/api` URL 和 frontend URL。
- 遗留问题，如果有。

## 实现到文档的落地

Docs 是权威基线，但自洽的 docs 并不证明 implementation 可用。

当一个 implementation item 完成并验证后，在推进依赖工作前把结果落回 docs。

一个 item 只有在以下条件满足后才算完成：

- Implementation 完成。
- 相关真实 checks 通过。
- 所属 docs 描述实际构建的内容。
- 与先前 design 的偏差已协调。
- 被接受的 decision changes 记录在 ADRs 或等价 decision docs 中。
- `changelog.md` 有诚实条目。
- 权威 plan checklist 和任何相关 child task checklist 在验证后立即从 `- [ ]` 更新为 `- [x]`。
- 当仓库使用 progress indexes 或 task lists 时，它们已更新。

使用明确验证状态：

- `verified`
- `failed with reason`
- `not verified`

不要把混合结果压缩成 "all good" 或 "looks fine" 这类含糊说法。

## Prompt 交接规则

当用户要求把当前进展总结成 prompt、为新 AI 对话创建交接、handoff 当前上下文，或使用类似措辞时，将其视为 handoff request。

写 handoff prompt 前：

1. 从文件和 `git status` 验证当前仓库状态。
2. 读取相关 global 和 local agent docs。
3. 读取 `CONTEXT.md`、相关 domain docs、category indexes、task lists、`changelog.md`，以及与下一个任务直接相关的 docs。
4. 检查用户陈述的进度是否与磁盘上的已提交或未提交文件一致。
5. 如果 conversation history 和 files 不一致，清楚说明差异。
6. 不要编造完成情况。
7. 区分 "confirmed in files" 与 "reported by the user but not reflected on disk"。
8. 绝不要把真实 keys、tokens、passwords 或完整 secret values 复制到 tracked files、docs、changelog entries、chat summaries 或 handoff prompts 中。

生成的 handoff prompt 必须可直接复制粘贴，并包含：

- Repository path
- 下一位 agent 应先读取的文件
- 已验证的当前进度
- 仍需协调的用户报告上下文，如果有
- 来自 `git status --short` 的已知未提交变更
- 对下一个任务重要的已接受决策
- 下一位 agent 必须遵循的 workflow rules
- 立即下一目标
- 声称完成前需要的 self-checks

大型产物用路径引用，不要重复其完整内容。
