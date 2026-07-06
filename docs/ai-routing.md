# AI routing

This branch treats AI routing as a split between user-level client ergonomics and system-level runtime services.

## Boundary

```text
ryjen/dotfiles
  Home/user config for Plano and model-router

Dubnium
  System services for vLLM, Ollama, Plano daemons, GPUs, logs, ports, and runtime state

ryjen/model-router
  Schemas, policy semantics, route decision records, and longer-lived governance design

Anthesis
  Governed execution envelopes, approvals, replayability, and evidence
```

Rule of thumb:

- Dubnium owns runtime, ports, GPUs, and local serving
- dotfiles own client policy, provider aliases, and secrets
- model-router owns route semantics, task classes, and fallback rules

## Why Nix/Home Manager here

The `feature/nix-migration` branch should avoid growing new Ansible surface for user config. Plano and model-router client integration are declarative home-environment concerns:

- `~/.config/planoai/dubnium.yaml`
- `~/.config/model-router/profiles/local-first-dev.yaml`
- `PLANO_BASE_URL`
- `OPENAI_BASE_URL`
- `MODEL_ROUTER_PROFILE`

These belong in Home Manager-style modules.

## Modules

```text
nix/home/ai/default.nix
nix/home/ai/plano.nix
nix/home/ai/model-router.nix
nix/home/examples/ai-routing.nix
```

Enable from a user/host profile with:

```nix
{
  imports = [ ./nix/home/ai ];

  ryjen.ai.plano.enable = true;
  ryjen.ai.model-router.enable = true;
}
```

See `nix/home/examples/ai-routing.nix` for an example profile import.

## Plano module

`ryjen.ai.plano` links a static Dubnium-oriented Plano config.

Default endpoint assumptions:

```text
Plano listener: 127.0.0.1:12000
Local model endpoint: http://127.0.0.1:8000/v1
```

Dubnium should provide the actual local runtime, usually vLLM or Ollama behind an OpenAI-compatible endpoint.

Use the static Plano config to declare local and cloud providers:

- local endpoint at `http://127.0.0.1:8000/v1`
- cloud general alias through `cloud-general`
- cloud reasoning alias through `cloud-reasoning`

Keep API keys in runtime secrets or environment variables. Do not commit them.

## model-router module

`ryjen.ai.model-router` links a static local-first policy profile and exports client environment variables.

The static profile treats Plano as the runtime gateway while model-router owns:

- privacy classes
- source policy
- task-class routing
- route-decision ledger path
- fallback allow/deny semantics
- affinity key sources

Recommended task split:

- `local-code` for private code, refactors, repo analysis, and unpublished docs
- `fast-local` for summaries, rewrites, and classification
- cloud aliases for general chat, broad reasoning, or tasks you explicitly allow to leave machine

## Ansible boundary

No new AI routing implementation should be added through Ansible on this branch. AI routing config is Nix/Home Manager-first here.

If the legacy Ansible playbooks remain in the repo, they should not own Plano or model-router integration.

## Security defaults

- Private code, secrets, unpublished docs, and sensitive personal data are classified as `local_only`
- Privacy uncertainty should fail closed
- Fallback must not bypass privacy, budget, safety, or approval failures
- Cloud providers require runtime API keys before use
- Secrets remain in environment variables or external secret stores, not committed config
