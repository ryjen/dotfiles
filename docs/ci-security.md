# CI security and trust boundary

GitHub Actions is treated as privileged repository infrastructure because this repository configures developer workstations, user services, credentials paths, and cross-repository integration contracts.

## Trust model

- Pull-request validation runs on GitHub-hosted runners with workflow-level `contents: read` permissions.
- Read-only checkout steps disable credential persistence.
- Third-party Actions are pinned to immutable 40-character commit SHAs. The reviewed release/tag remains in an adjacent comment for maintainability.
- Jobs have explicit timeouts so hung or compromised work cannot consume runner capacity indefinitely.
- `pull_request_target` is not permitted for workflows that execute repository code.
- Job-level write permissions are rejected by the repository workflow-security policy. A future write workflow requires an explicit policy change and security review.
- Workflows that accept `pull_request` must not invoke authenticated cache actions that require OIDC or cache-write authority. Pull-request Nix CI relies on ordinary trusted substituters instead.
- Any future authenticated cache publisher must be isolated in a trusted-only workflow or execution class and receive only the minimum permissions required for that publication path.
- Self-hosted Dubnium execution is not part of the untrusted pull-request path. Host-specific trusted integration remains a separate consumer-side concern.

## Repository policy check

Run the workflow policy directly from a clean checkout:

```bash
python3 checks/verify-workflow-security.py .
```

The check validates every workflow under `.github/workflows/` and fails when:

- a third-party Action uses a mutable tag or branch;
- `actions/checkout` persists its token;
- workflow permissions are broader than `contents: read`;
- a job grants write permission;
- a job omits `timeout-minutes`;
- `pull_request_target` is present;
- a workflow that accepts `pull_request` invokes an authenticated FlakeHub cache action.

`Nix CI` runs this policy before installing Nix or executing the rest of the repository validation surface.

## Nix cache policy

Pull-request CI intentionally does not run `DeterminateSystems/flakehub-cache-action`. Live CI evidence showed that under the read-only PR permission boundary the action cannot authenticate, emits expected cache/OIDC warnings, and does not provide a useful cache path. The builds continue through ordinary trusted Nix substituters such as `cache.nixos.org`.

Caching is a performance concern, not a correctness or provenance requirement. The repository therefore does not grant `id-token: write` or cache-write authority to untrusted PR validation merely to enable a cache optimization.

If authenticated cache publication is introduced later, it should be implemented as a separate trusted-only workflow or job with an explicit security review. That execution class must not accept untrusted pull-request code and should receive only the narrow permissions required for cache publication.

## Action updates

Dependabot opens GitHub Actions update pull requests weekly. Updates are reviewed as ordinary privileged-code changes; they are not auto-merged.

When updating an Action manually:

1. Resolve the intended upstream release/tag to its current commit SHA.
2. Replace the pinned SHA in every use site.
3. Keep the human-readable release/tag comment adjacent to the SHA.
4. Run `python3 checks/verify-workflow-security.py .`.
5. Run the normal repository checks relevant to the workflow change.

A cache hit or restored artifact is a performance input, not provenance or authorization evidence.

## Profile coverage

CI evaluates the activation-package derivation for every declared Home Manager profile so unsupported or drifting profile composition fails during pull-request validation. Selected portable configurations are then built explicitly to retain deployment-contract coverage without requiring live host state.
