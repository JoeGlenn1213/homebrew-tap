#!/usr/bin/env python3
"""Behavior tests for scripts/update_formulae.py. No network."""

import importlib.util
import io
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "update_formulae.py"

PLACEHOLDER = "0" * 64
REAL = "ab" * 32
OTHER = "cd" * 32


def load_updater():
    spec = importlib.util.spec_from_file_location("update_formulae", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def tarball_formula(sha, version="0.1.1", extra=""):
    return (
        "class ActiondWeb < Formula\n"
        '  desc "Static web console for ActionD"\n'
        '  homepage "https://github.com/JoeGlenn1213/actiond-web"\n'
        f'  version "{version}"\n'
        f'  url "https://github.com/JoeGlenn1213/actiond-web/releases/download/v{version}/actiond-web-{version}.tar.gz"\n'
        f'  sha256 "{sha}"\n'
        '  license "MIT"\n'
        f"{extra}"
        "  def install\n"
        '    (share/"actiond-web/out").install Dir["*"]\n'
        "  end\n"
        "end\n"
    )


TARBALL_PROJECT = {
    "repo": "JoeGlenn1213/actiond-web",
    "formula": "Formula/actiond-web.rb",
    "prefix": "actiond-web",
    "versioned_asset": True,
    "tarball": True,
}


def tarball_release(tag="v0.1.1", digest=REAL, filename="actiond-web-0.1.1.tar.gz"):
    return {
        "tag_name": tag,
        "assets": [{"name": filename, "digest": f"sha256:{digest}"}],
    }


def platform_formula(shas, version="1.3.4"):
    """Minimal lgh-style formula. shas is darwin-arm, darwin-amd, linux-arm, linux-amd."""
    darwin_arm, darwin_amd, linux_arm, linux_amd = shas
    blocks = [
        ("on_macos", "darwin", "arm64", darwin_arm, True),
        ("on_macos", "darwin", "amd64", darwin_amd, False),
        ("on_linux", "linux", "arm64", linux_arm, True),
        ("on_linux", "linux", "amd64", linux_amd, False),
    ]
    macos = []
    linux = []
    for block, goos, goarch, sha, arm in blocks:
        chunk = (
            f'      url "https://github.com/JoeGlenn1213/lgh/releases/download/v{version}/lgh-{goos}-{goarch}"\n'
            f'      sha256 "{sha}"\n'
        )
        (macos if block == "on_macos" else linux).append((arm, chunk))

    def cond(parts):
        arm, intel = parts
        return (
            "    if Hardware::CPU.arm?\n"
            f"{arm[1]}"
            "    else\n"
            f"{intel[1]}"
            "    end\n"
        )

    return (
        "class Lgh < Formula\n"
        f'  version "{version}"\n'
        "  on_macos do\n"
        f"{cond(macos)}"
        "  end\n"
        "  on_linux do\n"
        f"{cond(linux)}"
        "  end\n"
        "end\n"
    )


PLATFORM_PROJECT = {
    "repo": "JoeGlenn1213/lgh",
    "formula": "Formula/lgh.rb",
    "prefix": "lgh",
    "versioned_asset": False,
}


def platform_release(digests, tag="v1.3.4"):
    names = [
        "lgh-darwin-arm64",
        "lgh-darwin-amd64",
        "lgh-linux-arm64",
        "lgh-linux-amd64",
    ]
    return {
        "tag_name": tag,
        "assets": [
            {"name": name, "digest": f"sha256:{digest}"}
            for name, digest in zip(names, digests)
        ],
    }


class UpdateFormulaeTest(unittest.TestCase):
    def setUp(self):
        self.updater = load_updater()
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        tap = Path(self.tmp.name)
        (tap / "Formula").mkdir()
        self.tap = tap
        self.updater.TAP_DIR = str(tap)

    def write_formula(self, project, text):
        path = self.tap / project["formula"]
        path.write_text(text, encoding="utf-8")
        return path

    def test_placeholder_sha_is_replaced_when_version_is_unchanged(self):
        path = self.write_formula(TARBALL_PROJECT, tarball_formula(PLACEHOLDER))
        with patch.object(self.updater, "api", return_value=tarball_release()):
            result = self.updater.update_formula(TARBALL_PROJECT)
        updated = path.read_text(encoding="utf-8")
        self.assertIsNotNone(result)
        self.assertIn("refreshed checksums for v0.1.1", result)
        self.assertIn(f'sha256 "{REAL}"', updated)
        self.assertNotIn(PLACEHOLDER, updated)
        self.assertIn('version "0.1.1"', updated)

    def test_mismatched_sha_is_replaced_when_version_is_unchanged(self):
        path = self.write_formula(TARBALL_PROJECT, tarball_formula(OTHER))
        with patch.object(self.updater, "api", return_value=tarball_release()):
            result = self.updater.update_formula(TARBALL_PROJECT)
        updated = path.read_text(encoding="utf-8")
        self.assertIsNotNone(result)
        self.assertIn(f'sha256 "{REAL}"', updated)
        self.assertNotIn(OTHER, updated)

    def test_matching_version_and_sha_is_left_alone(self):
        original = tarball_formula(REAL)
        path = self.write_formula(TARBALL_PROJECT, original)
        with patch.object(self.updater, "api", return_value=tarball_release()):
            result = self.updater.update_formula(TARBALL_PROJECT)
        self.assertIsNone(result)
        self.assertEqual(path.read_text(encoding="utf-8"), original)

    def test_version_bump_still_rewrites_url_and_sha(self):
        path = self.write_formula(TARBALL_PROJECT, tarball_formula(OTHER, version="0.1.0"))
        with patch.object(self.updater, "api", return_value=tarball_release()):
            result = self.updater.update_formula(TARBALL_PROJECT)
        updated = path.read_text(encoding="utf-8")
        self.assertIn("0.1.0 -> 0.1.1", result)
        self.assertIn("download/v0.1.1/actiond-web-0.1.1.tar.gz", updated)
        self.assertIn(f'sha256 "{REAL}"', updated)
        self.assertIn('version "0.1.1"', updated)

    def test_placeholder_sha_on_platform_formula_is_replaced(self):
        shas = [PLACEHOLDER, "11" * 32, "22" * 32, "33" * 32]
        digests = ["aa" * 32, "11" * 32, "22" * 32, "33" * 32]
        path = self.write_formula(PLATFORM_PROJECT, platform_formula(shas))
        with patch.object(self.updater, "api", return_value=platform_release(digests)):
            result = self.updater.update_formula(PLATFORM_PROJECT)
        updated = path.read_text(encoding="utf-8")
        self.assertIsNotNone(result)
        self.assertNotIn(PLACEHOLDER, updated)
        self.assertIn(f'sha256 "{"aa" * 32}"', updated)

    def test_version_between_url_and_sha_is_rewritten(self):
        text = (
            "class ActiondWeb < Formula\n"
            '  desc "Static web console for ActionD"\n'
            '  homepage "https://github.com/JoeGlenn1213/actiond-web"\n'
            '  url "https://github.com/JoeGlenn1213/actiond-web/releases/download/v0.1.1/actiond-web-0.1.1.tar.gz"\n'
            '  version "0.1.1"\n'
            f'  sha256 "{PLACEHOLDER}"\n'
            '  license "MIT"\n'
            "end\n"
        )
        path = self.write_formula(TARBALL_PROJECT, text)
        with patch.object(self.updater, "api", return_value=tarball_release()):
            result = self.updater.update_formula(TARBALL_PROJECT)
        updated = path.read_text(encoding="utf-8")
        self.assertIn("refreshed checksums for v0.1.1", result)
        self.assertEqual(updated.count('version "'), 1)
        self.assertIn('version "0.1.1"', updated)
        self.assertIn(f'sha256 "{REAL}"', updated)
        self.assertLess(updated.index('url "'), updated.index('version "'))
        self.assertLess(updated.index('version "'), updated.index("sha256 "))

    def test_placeholder_without_version_line_uses_url_tag(self):
        text = (
            "class ActiondWeb < Formula\n"
            '  desc "Static web console for ActionD"\n'
            '  homepage "https://github.com/JoeGlenn1213/actiond-web"\n'
            '  url "https://github.com/JoeGlenn1213/actiond-web/releases/download/v0.1.1/actiond-web-0.1.1.tar.gz"\n'
            f'  sha256 "{PLACEHOLDER}"\n'
            '  license "MIT"\n'
            "end\n"
        )
        path = self.write_formula(TARBALL_PROJECT, text)
        with patch.object(self.updater, "api", return_value=tarball_release()):
            result = self.updater.update_formula(TARBALL_PROJECT)
        updated = path.read_text(encoding="utf-8")
        self.assertIn("refreshed checksums for v0.1.1", result)
        self.assertNotIn('version "', updated)
        self.assertIn(f'sha256 "{REAL}"', updated)

    def test_missing_tarball_is_not_a_commit(self):
        original = tarball_formula(PLACEHOLDER, version="0.1.1")
        path = self.write_formula(TARBALL_PROJECT, original)
        release = {"tag_name": "v0.1.0", "assets": []}
        github_output = Path(self.tmp.name) / "github_output"
        stdout = io.StringIO()
        with (
            patch.object(self.updater, "api", return_value=release),
            patch.object(self.updater, "PROJECTS", [TARBALL_PROJECT]),
            patch.dict(os.environ, {"GITHUB_OUTPUT": str(github_output)}),
            redirect_stdout(stdout),
        ):
            self.updater.main()
        self.assertEqual(path.read_text(encoding="utf-8"), original)
        self.assertIn("missing tarball actiond-web-0.1.0.tar.gz", stdout.getvalue())
        self.assertNotIn("up-to-date", stdout.getvalue())
        self.assertEqual(github_output.read_text(encoding="utf-8"), "changed=false\n")

    def test_placeholder_disable_is_removed_when_checksum_is_refreshed(self):
        extra = (
            '  # Placeholder until v0.1.1 is published. brew install refuses via disable!.\n'
            '  # The update script removes this disable! when it writes the real checksum.\n'
            '  disable! date: "2026-10-30", because: "is a placeholder until the v0.1.1 release tarball is published"\n'
        )
        path = self.write_formula(TARBALL_PROJECT, tarball_formula(PLACEHOLDER, extra=extra))
        with patch.object(self.updater, "api", return_value=tarball_release()):
            self.updater.update_formula(TARBALL_PROJECT)
        updated = path.read_text(encoding="utf-8")
        self.assertNotIn("disable!", updated)
        self.assertNotIn("Placeholder until", updated)
        self.assertIn(f'sha256 "{REAL}"', updated)


if __name__ == "__main__":
    unittest.main()
