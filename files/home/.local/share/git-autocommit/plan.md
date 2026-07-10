Plan signed Conventional Commits for the staged Git changes below.

{{grouping_instruction}}

Return only a JSON array with this exact shape:
[
  {"message": "type(scope): imperative summary", "files": ["path/to/file"]}
]

Rules:
- Every staged path must appear exactly once across the plan.
- Do not invent, omit, duplicate, or rename paths.
- Group by intent and dependency, not merely directory.
- Keep related implementation, tests, and documentation together.
- Separate unrelated fixes, refactors, infrastructure, and generated changes.
- Never split one file across commits; file-level grouping is the safety boundary.
- Order foundational commits before dependent commits.
- Allowed types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
- Use a scope only when obvious and useful.
- Keep the first line concise and imperative.
- Add a body only when it explains important rationale.
- Never claim tests passed unless the diff proves it.
- Produce at most {{max_commits}} commits.

Authoritative staged paths:
{{files_json}}

Staged changes:
{{context}}
