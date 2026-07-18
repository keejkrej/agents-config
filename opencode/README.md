# opencode-config

Portable [opencode](https://opencode.ai) configuration: global agent
delegation guidance, a custom reviewer agent, an MCP server template, and
permissions set to always-allow (yolo mode). Synced into `~/.config/opencode/`.

## Layout

```
opencode/
  instructions.md        global orchestration guidance, copied to ~/.config/opencode/AGENTS.md
  opencode.json          template merged into ~/.config/opencode/opencode.json
                           (model, small_model, instructions, permission, mcp)
  agent/
    reviewer.md          adversarial PR reviewer subagent (edit: deny, bash: ask)
    explore.md           read-only codebase explorer / grilling interviewer
scripts/
  merge-json.mjs         non-destructive JSON merge helper used by install
```

Install from the repo root with the single `install.sh` / `install.ps1` script:

```bash
./install.sh opencode
```

## What this config does

- Registers a custom **Ollama (local)** provider pointing at
  `http://localhost:11434/v1` — the same setup `ollama launch opencode` uses
  — and defines the **glm-5.2:cloud** model under it. Ollama routes the
  `:cloud` suffix to Ollama Cloud, so you don't need the separate
  `ollama-cloud` provider or its API key.
- Sets the default session model to **ollama/glm-5.2:cloud** via `opencode.json`.
- Sets `permission: "allow"` — every tool action is auto-approved (yolo mode).
  No confirmation prompts for edits, bash, or anything else.
- Registers an optional **vision-mcp** server (Ollama-backed vision model)
  via the `mcp` block in `opencode.json`.
- Copies `instructions.md` to `~/.config/opencode/AGENTS.md`, which instructs the
  main agent to **delegate eagerly to subagents** for research, exploration,
  search, verification, code review, and any multi-file investigation.
  Subagents run in their own context and return a short summary, keeping the
  main agent's context lean.
- Copies two custom subagents under `~/.config/opencode/agent/`:
  - **reviewer** — adversarial PR reviewer (read-only, no edits).
  - **explore** — read-only codebase explorer / grilling interviewer.

## Prerequisites

- `bash` or PowerShell, `node`/`npm` (18+)
- [Ollama](https://ollama.com) installed locally. Pull the model first so
  opencode can see it:
  ```bash
  ollama pull glm-5.2:cloud
  ```
  The `:cloud` suffix routes through Ollama Cloud; the request itself goes via
  the local Ollama endpoint at `http://localhost:11434/v1`.

## Notes

- `opencode.json` uses the literal token `$HOME` in any string paths;
  `scripts/merge-json.mjs` expands it to the real home directory when writing to
  `~/.config/opencode/opencode.json`, so the repo stays portable across
  machines/users.
