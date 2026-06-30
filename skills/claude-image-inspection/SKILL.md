---
name: claude-image-inspection
description: Use Claude Code or the Claude Agent SDK path to inspect local images, screenshots, visual references, UI mockups, and image-based evidence while keeping scripts, prompts, and judgment logs under .debug. Use when Codex or Claude needs Claude-specific image reading, visual inspection through the Claude SDK, or image judgment logs.
---

# Claude Image Inspection

## Claude image-reading rules

When Claude is the primary agent and the task requires reading or judging image content, prefer Claude's own image-reading path through the local Claude Agent SDK. Do not route to Codex only for image reading.

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

If the SDK is installed in the current project, prefer a normal bare import:

```bash
npm install @anthropic-ai/claude-agent-sdk
```

Then use:

```js
import { query } from '@anthropic-ai/claude-agent-sdk'
```

If the SDK is installed globally, normal bare imports may not resolve from an arbitrary project. In that case, use a global-path import bridge:

```js
import { createRequire } from 'node:module'

const require = createRequire('/usr/lib/node_modules/')
const sdkPath = require.resolve('@anthropic-ai/claude-agent-sdk')
const sdk = await import(sdkPath)

const { query } = sdk
```

For image inspection:

- Use a script for visual judgment.
- Make the prompt specific: subject, count, layout, text correctness, readability, style consistency, cropping, edge quality, and task-specific acceptance criteria.
- Store the script, prompt, and judgment log under `.debug/YYYY-MM-DD/image-inspection/`.
- The primary agent decides whether to accept, regenerate, or fix based on the judgment and the task spec.
- Programmatic metadata such as dimensions, channels, alpha range, and histograms can be read directly with tools such as `sharp`; that is not visual judgment.
