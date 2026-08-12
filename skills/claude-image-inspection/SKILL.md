---
name: claude-image-inspection
description: Use when Claude or a Claude subagent must personally inspect local images, screenshots, visual references, UI mockups, or image-based evidence.
---

# Claude Image Inspection

## Claude image-reading rules

When Claude or a Claude subagent must personally read or judge image content, use Claude's own image-reading path through the local Claude Agent SDK. The SDK path is required for Claude-native visual judgment.

Codex may inspect images with native vision. Claude may also delegate image judgment to Codex, but that is delegated Codex judgment and must not be described as Claude-native inspection.

Use a small local script that converts the image to base64, sends it to `@anthropic-ai/claude-agent-sdk`, and keeps:

- `maxTurns: 1`
- `allowedTools: []`
- A specific checklist prompt
- Text-only judgment output

Example script:

```js
import { query } from '@anthropic-ai/claude-agent-sdk'
import fs from 'node:fs'

const imageData = fs.readFileSync('/path/to/reference-image.png').toString('base64')

async function* generateMessages() {
  yield {
    type: 'user',
    message: {
      role: 'user',
      content: [
        { type: 'text', text: 'Analyze this image against the given checklist.' },
        {
          type: 'image',
          source: {
            type: 'base64',
            media_type: 'image/png',
            data: imageData,
          },
        },
      ],
    },
    parent_tool_use_id: null,
  }
}

for await (const message of query({
  prompt: generateMessages(),
  options: {
    maxTurns: 1,
    permissionMode: 'bypassPermissions',
    allowDangerouslySkipPermissions: true,
    allowedTools: [],
  },
})) {
  if (message.type === 'result') console.log(message.result)
}
```

In a Node project, install the SDK with the project's actual package manager, normally as a development or tooling dependency, and update the lockfile:

```bash
npm install --save-dev @anthropic-ai/claude-agent-sdk
```

Then use:

```js
import { query } from '@anthropic-ai/claude-agent-sdk'
```

In a non-Node project, use an isolated tooling directory under `.debug/YYYY-MM-DD/image-inspection/tooling/`, keep it ignored, and install the SDK there. If an existing global installation must be used, resolve its root dynamically with the active package manager, such as `npm root -g`; never hard-code a Linux global-module path.

Example dynamic global import bridge:

```js
import { createRequire } from 'node:module'
import { execFileSync } from 'node:child_process'

const globalRoot = execFileSync('npm', ['root', '-g'], { encoding: 'utf8' }).trim()
const require = createRequire(`${globalRoot}/`)
const sdkPath = require.resolve('@anthropic-ai/claude-agent-sdk')
const sdk = await import(sdkPath)

const { query } = sdk
```

For image inspection:

- Use a script for visual judgment.
- Make the prompt specific: subject, count, layout, text correctness, readability, style consistency, cropping, edge quality, and task-specific acceptance criteria.
- Store the script, prompt, and judgment log under `.debug/YYYY-MM-DD/image-inspection/`.
- Keep `permissionMode: 'bypassPermissions'`, `allowDangerouslySkipPermissions: true`, `allowedTools: []`, and `maxTurns: 1` unchanged for this no-tool, single-turn image request.
- The primary agent decides whether to accept, regenerate, or fix based on the judgment and the task spec.
- Programmatic metadata such as dimensions, channels, alpha range, and histograms can be read directly with tools such as `sharp`; that is not visual judgment.
