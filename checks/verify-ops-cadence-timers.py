#!/usr/bin/env python3
"""Verify security and scheduling invariants for the ops-cadence Home Manager module."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else Path.cwd().resolve()
MODULE = ROOT / "modules" / "home" / "ops-cadence.nix"


def require(content: str, value: str, description: str) -> None:
    if value not in content:
        raise SystemExit(f"ops-cadence module missing {description}: {value}")


def forbid(content: str, value: str, description: str) -> None:
    if value in content:
        raise SystemExit(f"ops-cadence module contains forbidden {description}: {value}")


def main() -> int:
    content = MODULE.read_text()

    required = {
        'SuccessExitStatus = [ "75" ];': "overlap exit handling",
        'TimeoutStartSec = cfg.timers.timeout;': "bounded execution time",
        'UMask = "0077";': "private runtime files",
        'NoNewPrivileges = true;': "privilege escalation prevention",
        'ProtectSystem = "strict";': "read-only system protection",
        'ProtectHome = "read-only";': "read-only home protection",
        'ReadWritePaths = [ "%h/.local/state/ops-cadence" ];': "narrow state write path",
        'systemd.user.tmpfiles.rules': "declarative state directory provisioning",
        '"d %h/.local/state/ops-cadence 0700 - - -"': "private state directory mode",
        'LoadCredential = credentialLoads;': "systemd credential loading",
        'githubCredentialEnabled = cfg.liveSources.enable && cfg.liveSources.github;': "GitHub credential capability gate",
        'gmailCredentialEnabled = cfg.liveSources.enable && cfg.liveSources.gmail;': "Gmail credential capability gate",
        'lib.optional (githubCredentialEnabled && cfg.credentials.githubTokenFile != null)': "null-safe conditional GitHub credential loading",
        'lib.optional (gmailCredentialEnabled && cfg.credentials.gmailAccessTokenFile != null)': "null-safe conditional Gmail credential loading",
        'Enabled GitHub ingestion requires credentials.githubTokenFile.': "fail-closed GitHub credential assertion",
        'Enabled Gmail ingestion requires credentials.gmailAccessTokenFile.': "fail-closed Gmail credential assertion",
        'credentialPathSafe cfg.credentials.githubTokenFile': "GitHub credential path validation",
        'credentialPathSafe cfg.credentials.gmailAccessTokenFile': "Gmail credential path validation",
        '"/nix/store/"': "Nix-store secret path rejection",
        '"PYTHONNOUSERSITE=1"': "Python user package isolation",
        '"ANTHROPIC_API_KEY"': "ambient Anthropic credential removal",
        '"CLOUDFLARE_API_TOKEN"': "ambient Cloudflare credential removal",
        '"DOCKER_CONFIG"': "ambient Docker credential removal",
        '"GITHUB_TOKEN"': "GitHub token removal",
        '"GMAIL_ACCESS_TOKEN"': "Gmail token removal",
        '"KUBECONFIG"': "ambient Kubernetes credential removal",
        '"NPM_TOKEN"': "ambient npm credential removal",
        '"SSH_AUTH_SOCK"': "SSH agent removal",
        'ExecStartPre = "${package}/bin/opsctl doctor --probe --json";': "pre-run contract probe",
        'Persistent = true;': "missed-run persistence",
        'AccuracySec = cfg.timers.accuracy;': "timer accuracy bound",
        'RandomizedDelaySec = cfg.timers.randomizedDelay;': "timer jitter",
        '"*-*-* 08:00:00"': "daily Career Intelligence schedule",
        '"Mon *-*-* 09:30:00"': "Monday Engineering Portfolio schedule",
        '"Fri *-*-* 16:30:00"': "Friday Weekly Review schedule",
        'enabled = ${lib.boolToString cfg.liveSources.enable}': "explicit live-source gate",
        'professional_context_snapshot_path = "${professionalContextPath}"': "professional-context snapshot path",
        'tracker_snapshot_path = "${careerOpsStateDir}/application-state.json"': "tracker projection path",
        'discovery_bundle_path = "${careerOpsStateDir}/discovery-candidates.json"': "discovery path",
        'capacity_path = "${careerOpsStateDir}/execution-capacity.json"': "capacity path",
        'follow_up_queue_path = "${careerOpsStateDir}/follow-up-queue.json"': "follow-up path",
        'issue_priorities_path = "${careerOpsStateDir}/issue-priorities.json"': "issue-priority path",
        'blockers_path = "${careerOpsStateDir}/blockers.json"': "blocker path",
    }
    for value, description in required.items():
        require(content, value, description)

    forbidden = {
        'lib.optional (cfg.credentials.githubTokenFile != null)': "credential loading without GitHub capability gate",
        'lib.optional (cfg.credentials.gmailAccessTokenFile != null)': "credential loading without Gmail capability gate",
        'Environment = [ "GITHUB_TOKEN=': "inline GitHub token",
        'Environment = [ "GMAIL_ACCESS_TOKEN=': "inline Gmail token",
        'SetCredential =': "inline systemd credential",
        'Restart = "always";': "unbounded restart loop",
        'ProtectHome = false;': "unprotected home access",
        'Persistent = false;': "missed-run suppression",
        '"d %h/.local/state/ops-cadence 0777': "world-writable state directory",
    }
    for value, description in forbidden.items():
        forbid(content, value, description)

    print("ops-cadence timer invariants verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
