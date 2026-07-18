## Built-in and custom agents

opencode ships with built-in agents and loads custom agents from `~/.config/opencode/agent/` (personal) or `.opencode/agent/` (project-scoped):

- `build`: general-purpose primary agent (default).
- `plan`: planning agent with read-only permissions (Plan Mode).
- `general`: general-purpose fallback agent, also used for subagent work.
- `explore`: read-heavy codebase exploration agent. Also runs the planning interview against the orchestrator.
- `reviewer` (custom): adversarial PR reviewer focused on correctness, security, and missing tests. See `agent/reviewer.md`.

If a custom agent name matches a built-in agent, the custom agent takes precedence. Custom agents are defined as markdown files under `~/.config/opencode/agent/<name>.md` (or `.opencode/agent/<name>.md` for project scope), or inline under the `agent` key in `opencode.json`.
