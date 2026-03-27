# Repository Guidelines

## Project Structure & Module Organization
- `install.yml`, `uninstall.yml`, and `test.yml` are the top-level Ansible playbooks that drive installs, removals, and role tests.
- `roles/` contains the Ansible roles (mirrored under `collections/ansible_collections/ryjen/dotfiles/roles/` for collection usage).
- `inventory/` holds host files (`hosts`, `deploy/hosts`, `test/hosts`) and `group_vars/` contains shared vars.
- `vault/` stores encrypted or example secrets referenced by playbooks.

## Build, Test, and Development Commands
- `./bootstrap.sh install` — install dotfiles on the local machine.
- `./bootstrap.sh uninstall` — uninstall and unlink dotfiles.
- `./bootstrap.sh install -t <basic|default|extra>` — run a tag group (example: `./bootstrap.sh install -t default`).
- `./bootstrap.sh install -t <role>` — run a single role (example: `./bootstrap.sh install -t neovim`).
- `./bootstrap.sh --test install` / `./bootstrap.sh --test uninstall` — run against the test inventory.
- `ansible-playbook -i inventory/test/hosts test.yml` — run role tests directly.

## Coding Style & Naming Conventions
- Ansible YAML uses 2-space indentation; avoid tabs.
- Keep task names imperative and specific (example: `Ensure mcp gateway config is present`).
- Templates live in each role’s `templates/` directory and use Jinja2 naming (e.g., `*.j2`).

## Testing Guidelines
- Role tests live under `roles/<role>/tests/` and are aggregated in `test.yml`.
- Add new role tests to `test.yml` so they run in CI and via `bootstrap.sh --test`.

## Commit & Pull Request Guidelines
- Commits follow Conventional Commits (`feat: ...`, `fix: ...`, optional scope like `feat(mcp): ...`).
- PRs should include: what changed, how to test (commands run), and any config or inventory updates.

## Security & Configuration Tips
- Secrets are loaded from `vault/config.yml` and `vault/gpg_key.yml`; keep real secrets encrypted and out of git history.
- Use the provided vault password helper in `.bin/ansible-vault-pass` when available; otherwise expect a vault prompt.
