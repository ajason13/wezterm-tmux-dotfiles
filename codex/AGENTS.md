# Codex Role Routing

Use the role requested by the user. For mixed work, the Lead Architect defines
the approved plan and the Builder implements it.

- Research-only tasks: use `deep-researcher` before making recommendations.
- Architecture, specs, or ambiguous planning: use `lead-architect`.
- Notion, status, handoffs, and release checklists: use `workflow-coordinator`.
- Code changes, debugging, tests, CI, and documentation: use `builder`.
- Do not silently change an agent's model or reasoning effort. Record an
  unavailable model or effort as an exception in the handoff.

For a guaranteed top-level role pin in the CLI, start the session with
`codex-role <role>` instead of relying on task wording.
