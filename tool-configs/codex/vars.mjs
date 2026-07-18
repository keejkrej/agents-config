export default {
  output: 'codex/instructions.md',
  replacements: {
    TOOL_NAME: 'Codex',
    DELEGATION_MECHANISM: 'within `agents.max_threads` and `agents.max_depth`',
    MAIN_THREAD: 'the Codex main thread is the orchestrator and validator; Codex subagents do the bulk implementation, exploration, and adversarial review',
    SUBAGENT_ORCHESTRATION_DETAIL: '',
    EXPLORE_AGENT_NAME: 'explorer',
    GRILLING_DISPATCH_DETAIL: '',
    HELPER_AGENT_NAME: 'worker',
    SPAWN_HELPER_DETAIL: '',
    EXPLORE_DISPATCH_DETAIL: '',
    WORKER_DISPATCH_DETAIL: '',
    REVIEWER_DISPATCH_DETAIL: '',
    INTERVIEW_RESUME_DETAIL: '(`send_input` / `resume_agent`)',
  },
};
