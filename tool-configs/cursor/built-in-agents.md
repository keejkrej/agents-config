## Built-in and custom agents

Cursor ships with built-in subagents and loads custom subagents from `~/.cursor/agents/` (personal) or `.cursor/agents/` (project-scoped):

- `Explore`: searches and analyzes codebases. Uses a faster model to run many parallel searches and returns a summary.
- `Bash`: runs a series of shell commands. Isolates noisy command output from the main conversation.
- `Browser`: controls the browser via MCP tools. Isolates noisy DOM snapshots and screenshots.
- `worker` (custom): execution-focused subagent for implementation and fixes. Define it in `.cursor/agents/worker.md` with YAML frontmatter (`name`, `description`, `model`, `readonly`, `is_background`) followed by the prompt.
- `reviewer` (custom): adversarial PR reviewer focused on correctness, security, and missing tests. Define it in `.cursor/agents/reviewer.md`.

If a custom subagent name matches a built-in subagent, the custom subagent takes precedence. Project subagents in `.cursor/agents/` win over user subagents in `~/.cursor/agents/`.
