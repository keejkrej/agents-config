export default {
  output: 'grok/instructions.md',
  replacements: {
    TOOL_NAME: 'Grok Build',
    DELEGATION_MECHANISM: 'via the `task` tool with the appropriate `agent` parameter',
    MAIN_THREAD: 'the Grok Build main thread is the orchestrator and validator; Grok subagents do the bulk implementation, exploration, and adversarial review',
    SUBAGENT_ORCHESTRATION_DETAIL: ' via the `task` tool',
    EXPLORE_AGENT_NAME: 'explore',
    GRILLING_DISPATCH_DETAIL: ' (via the `task` tool)',
    HELPER_AGENT_NAME: 'worker',
    SPAWN_HELPER_DETAIL: ' (via the `task` tool)',
    EXPLORE_DISPATCH_DETAIL: ' (via the `task` tool with `agent: "explore"`)',
    WORKER_DISPATCH_DETAIL: ' (via the `task` tool, using a custom `worker` agent in `.grok/agents/worker.md` or the built-in `general-purpose` agent)',
    REVIEWER_DISPATCH_DETAIL: ' (via the `task` tool, using a custom `reviewer` agent in `.grok/agents/reviewer.md`)',
    INTERVIEW_RESUME_DETAIL: '(passing its `task_id` to resume via the `task` tool)',
  },
};
