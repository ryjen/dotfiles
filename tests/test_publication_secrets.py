from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "scripts" / "verify-publication-secrets.py"
spec = importlib.util.spec_from_file_location("publication_secrets", SOURCE)
assert spec is not None and spec.loader is not None
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class CredentialPublicationTests(unittest.TestCase):
    def test_rejects_local_secrets_but_allows_templates(self):
        for name in (".env", ".env.production", "files/home/.env.local",
                     "id_ed25519", "tls/client.key", "user.p12", "db/users.sqlite"):
            with self.subTest(name=name):
                self.assertTrue(guard.is_blocked_name(Path(name)))
        for name in (".env.example", ".env.production.example", ".sops.yaml",
                     "docs/secrets.md", "keys/id_ed25519.pub", "secrets.yaml.example"):
            with self.subTest(name=name):
                self.assertFalse(guard.is_blocked_name(Path(name)))

    def test_secret_pem_in_unusual_extension_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "safe.conf").write_bytes(
                b"some config\n" + b"-----BEGIN " + b"OPENSSH PRIVATE KEY-----\nTEST-ONLY"
            )
            result = guard.inspect(root, [Path("safe.conf")])
            self.assertEqual(result, [("safe.conf", "private key PEM marker")])

    def test_plaintext_sops_file_rejected_encrypted_form_allowed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            p = root / "secrets.yaml"
            p.write_text('github_token: "synthetic"\n')
            self.assertEqual(guard.inspect(root, [Path("secrets.yaml")]),
                             [("secrets.yaml", "unencrypted SOPS file")])
            p.write_text(
                "github_token: ENC[AES256_GCM,data:synthetic,iv:example,tag:example,type:str]\n"
                "openai_api_key: ENC[AES256_GCM,data:synthetic,iv:example,tag:example,type:str]\n"
                "sops:\n  version: '3.9.4'\n"
            )
            self.assertEqual(guard.inspect(root, [Path("secrets.yaml")]), [])

    def test_rejects_unencrypted_known_field_inside_sops_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "secrets.yaml").write_text(
                "github_token: ENC[AES256_GCM,data:example]\n"
                "openai_api_key: plaintext-marker-not-real\n"
                "sops:\n  version: '3.9.4'\n"
            )
            self.assertEqual(guard.inspect(root, [Path("secrets.yaml")]),
                             [("secrets.yaml", "unencrypted SOPS file")])

    def test_missing_files_and_symlinks_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "link").symlink_to(root / "missing")
            self.assertEqual(guard.inspect(root, [Path("link")]),
                             [("link", "tracked symlink needs review")])
            self.assertEqual(guard.inspect(root, [Path("missing")]),
                             [("missing", "missing tracked file")])

    def test_public_examples_do_not_fail(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "secrets.yaml.example").write_text('github_token: ""\n')
            self.assertEqual(guard.inspect(root, [Path("secrets.yaml.example")]), [])


if __name__ == "__main__":
    unittest.main()
