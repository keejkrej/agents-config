## Built-in and custom agents

Codex ships with built-in agents and loads custom agents from `~/.codex/agents/` (personal) or `.codex/agents/` (project-scoped):

- `default`: general-purpose fallback agent.
- `worker`: execution-focused agent for implementation and fixes. Reads its unit of work from `.scratch/` ticket files when dispatched.
- `explorer`: read-heavy codebase exploration agent. Also runs the planning interview against the orchestrator.
- `reviewer` (custom): adversarial PR reviewer focused on correctness, security, and missing tests. See `agents/reviewer.toml`.

If a custom agent name matches a built-in agent, the custom agent takes precedence.
