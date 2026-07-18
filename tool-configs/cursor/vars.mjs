export default {
  output: 'cursor/instructions.md',
  replacements: {
    TOOL_NAME: 'Cursor',
    DELEGATION_MECHANISM: 'via the Agent subagent mechanism (built-in subagents or custom `.cursor/agents/*.md`)',
    MAIN_THREAD: 'the Cursor agent is the orchestrator and validator; Cursor subagents do the bulk implementation, exploration, and adversarial review',
    SUBAGENT_ORCHESTRATION_DETAIL: ' via the Agent subagent mechanism',
    EXPLORE_AGENT_NAME: 'Explore',
    GRILLING_DISPATCH_DETAIL: ' (via the Agent subagent mechanism)',
    HELPER_AGENT_NAME: 'worker',
    SPAWN_HELPER_DETAIL: ' (via the Agent subagent mechanism)',
    EXPLORE_DISPATCH_DETAIL: ' (use Cursor\'s built-in `Explore` subagent or a custom `.cursor/agents/explore.md`)',
    WORKER_DISPATCH_DETAIL: ' (by invoking the custom `worker` subagent defined in `.cursor/agents/worker.md`)',
    REVIEWER_DISPATCH_DETAIL: ' (by invoking the custom `reviewer` subagent defined in `.cursor/agents/reviewer.md`)',
    INTERVIEW_RESUME_DETAIL: '(continue the Cursor conversation; subagent state is tracked automatically)',
  },
};
