export default {
  output: 'opencode/instructions.md',
  replacements: {
    TOOL_NAME: 'opencode',
    DELEGATION_MECHANISM: 'via the `task` tool with the appropriate `subagent_type`',
    MAIN_THREAD: 'the opencode main thread is the orchestrator and validator; subagents do the bulk implementation, exploration, and adversarial review',
    SUBAGENT_ORCHESTRATION_DETAIL: ' via the `task` tool',
    EXPLORE_AGENT_NAME: 'explore',
    GRILLING_DISPATCH_DETAIL: ' (via the `task` tool)',
    HELPER_AGENT_NAME: 'general',
    SPAWN_HELPER_DETAIL: ' (via the `task` tool)',
    EXPLORE_DISPATCH_DETAIL: ' (via the `task` tool with `subagent_type: "explore"`)',
    WORKER_DISPATCH_DETAIL: ' (via the `task` tool with `subagent_type: "general"`)',
    REVIEWER_DISPATCH_DETAIL: ' (via the `task` tool with `subagent_type: "general"`)',
    INTERVIEW_RESUME_DETAIL: '(passing its `task_id` to resume via the `task` tool)',
  },
};
