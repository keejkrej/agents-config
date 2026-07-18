## Built-in and custom agents

Grok Build ships with built-in agents and discovers custom agents from `~/.grok/agents/` (user) or `.grok/agents/` (project, when supported):

- `general-purpose`: default agent for general coding tasks.
- `explore`: read-heavy codebase exploration agent. Also runs the planning interview against the orchestrator.
- `plan`: planning agent for scoping and decision work.
- `worker` (custom): execution-focused agent for implementation and fixes. Define it in `.grok/agents/worker.md`.
- `reviewer` (custom): adversarial PR reviewer focused on correctness, security, and missing tests. Define it in `.grok/agents/reviewer.md`.

Subagents are enabled with `[subagents] enabled = true` in `~/.grok/config.toml` and are dispatched via the `task` tool (e.g. `agent: "explore"`). If a custom agent name matches a built-in agent, the custom agent takes precedence.
