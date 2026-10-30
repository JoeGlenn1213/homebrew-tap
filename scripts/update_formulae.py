#!/usr/bin/env python3
"""Update Homebrew formulae from the latest GitHub releases.

For each configured project, compare the formula against the latest
published release. Rewrite the version line, the url/sha256 pairs, and
(for versioned asset names) the bin.install source names when the version
differs, when a sha256 is the all-zero placeholder, or when a sha256 does
not match the release asset's digest. A matching version alone is not
enough — otherwise a formula that already declares the new version with a
placeholder checksum would never be corrected.

A `disable!` line whose reason contains "placeholder" is removed in the
same rewrite, so a formula blocked until its release exists becomes
installable once the real checksum is written.

Safety: if a release is missing ANY expected platform asset, the formula is
left untouched and the script exits non-zero — a partial formula is never
written. A missing tarball asset skips that formula without writing it.

Env:
  GITHUB_TOKEN  optional; authenticated API access (recommended on CI)
  TAP_DIR       tap root, defaults to the script's repo (testability)

Writes "changed=true" to $GITHUB_OUTPUT when any formula was updated.
"""

import json
import os
import re
import sys
import urllib.request

GITHUB_API = os.environ.get("GITHUB_API", "https://api.github.com")
TOKEN = os.environ.get("GITHUB_TOKEN")
TAP_DIR = os.environ.get("TAP_DIR", os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# repo, formula path, asset prefix, whether asset names embed the version
# (both projects now ship unversioned assets — prefix-<os>-<arch> — which
# keeps /releases/latest/download/ README links stable; versioned_asset is
# retained for future projects that name assets with the tag)
PROJECTS = [
    {
        "repo": "JoeGlenn1213/lgh",
        "formula": "Formula/lgh.rb",
        "prefix": "lgh",
        "versioned_asset": False,
    },
    {
        "repo": "JoeGlenn1213/ActionD",
        "formula": "Formula/actiond.rb",
        "prefix": "actiond",
        "versioned_asset": False,
    },
    {
        "repo": "JoeGlenn1213/actiond-web",
        "formula": "Formula/actiond-web.rb",
        "prefix": "actiond-web",
        "versioned_asset": True,
        "tarball": True,
    },
]

PLATFORMS = [("darwin", "arm64"), ("darwin", "amd64"), ("linux", "arm64"), ("linux", "amd64")]
PLACEHOLDER_SHA256 = "0" * 64


class FormulaSkipped:
    """A release was not applied and the formula file was not written."""

    def __init__(self, message):
        self.message = message


def api(path):
    req = urllib.request.Request(
        GITHUB_API + path, headers={"Accept": "application/vnd.github+json"}
    )
    if TOKEN:
        req.add_header("Authorization", f"Bearer {TOKEN}")
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)


def asset_name(project, tag, goos, goarch):
    if project["versioned_asset"]:
        return f"{project['prefix']}-v{tag}-{goos}-{goarch}"
    return f"{project['prefix']}-{goos}-{goarch}"


def formula_sha256s(text):
    return [digest.lower() for digest in re.findall(r'sha256 "([0-9a-fA-F]{64})"', text)]


def expected_sha256s(project, tag, digests):
    """Checksums this release should write, in formula order.

    None means a required asset is absent, so the caller must not treat a
    checksum mismatch as something it can repair.
    """
    if project.get("tarball"):
        name = f"{project['prefix']}-{tag}.tar.gz"
        digest = digests.get(name)
        if digest is None:
            return None
        return [digest.lower()]

    names = [asset_name(project, tag, goos, goarch) for goos, goarch in PLATFORMS]
    if any(name not in digests for name in names):
        return None
    return [digests[name].lower() for name in names]


def release_already_applied(text, current, tag, project, digests):
    """True when the formula already records this release's real checksums."""
    if tag != current:
        return False
    found = formula_sha256s(text)
    if not found or any(digest == PLACEHOLDER_SHA256 for digest in found):
        return False
    expected = expected_sha256s(project, tag, digests)
    # Version matches and the checksums are not placeholders, but this
    # release does not list the assets we would compare. Leave it alone
    # rather than failing the scheduled run.
    if expected is None:
        return True
    return found == expected


def strip_placeholder_disable(text):
    """Drop a disable! that exists only to block an unpublished placeholder."""
    return re.sub(
        r"(?m)^(?:  #.*(?:placeholder|disable!).*\n)*  disable!.*placeholder.*\n",
        "",
        text,
        count=1,
    )


def describe_change(repo, current, tag):
    if current == tag:
        return f"{repo}: refreshed checksums for v{tag}"
    return f"{repo}: {current} -> {tag}"


def formula_version(text, path):
    """Current formula version from a `version` line, or from the release URL.

    An explicit `version` line is optional. Homebrew treats it as redundant
    when the tag is already in `releases/download/vX.Y.Z/`, so formulae may
    omit it. Every such URL in one formula must name the same tag.
    """
    version_match = re.search(r'^  version "([^"]+)"', text, re.M)
    if version_match:
        return version_match.group(1)
    urls = re.findall(r"releases/download/v([^\"/]+)/", text)
    if not urls:
        sys.exit(f"{path}: no `version` line or releases/download/vX.Y.Z URL found")
    if any(url != urls[0] for url in urls):
        sys.exit(f"{path}: release tags in urls disagree: {sorted(set(urls))}")
    return urls[0]


def update_formula(project):
    path = os.path.join(TAP_DIR, project["formula"])
    with open(path, encoding="utf-8") as fh:
        text = fh.read()

    current = formula_version(text, path)

    release = api(f"/repos/{project['repo']}/releases/latest")
    tag = release["tag_name"].lstrip("v")

    digests = {
        a["name"]: a["digest"].removeprefix("sha256:")
        for a in release["assets"]
        if a.get("digest")
    }

    if release_already_applied(text, current, tag, project, digests):
        return None

    # Handle tarball-based formulae (e.g., actiond-web)
    if project.get("tarball"):
        tarball_name = f"{project['prefix']}-{tag}.tar.gz"
        if tarball_name not in digests:
            return FormulaSkipped(
                f"{project['repo']}: release v{tag} is missing tarball {tarball_name}; skipping"
            )

        url = f"https://github.com/{project['repo']}/releases/download/v{tag}/{tarball_name}"
        # Homebrew's stanza order puts `version` between `url` and `sha256`.
        # Older formulae keep `version` above `url`. Accept either, and do not
        # invent a `version` line when the formula does not have one.
        pattern = re.compile(
            r'url "https://github\.com/[^"]+/releases/download/[^"]+\.tar\.gz"\n'
            r'(  version "[^"]+"\n)?'
            r'[ \t]*sha256 "[0-9a-fA-F]{64}"'
        )

        def rewrite_tarball(match, url=url, sha=digests[tarball_name], tag=tag):
            if match.group(1):
                return f'url "{url}"\n  version "{tag}"\n  sha256 "{sha}"'
            return f'url "{url}"\n  sha256 "{sha}"'

        text, n = pattern.subn(rewrite_tarball, text, count=1)
        if n != 1:
            sys.exit(f"{path}: could not locate the tarball url+sha256 block")

        text = re.sub(r'^  version "[^"]+"$', f'  version "{tag}"', text, count=1, flags=re.M)
        text = strip_placeholder_disable(text)

        with open(path, "w", encoding="utf-8") as fh:
            fh.write(text)
        return describe_change(project["repo"], current, tag)

    # Handle platform-specific binary formulae
    for goos, goarch in PLATFORMS:
        expected = asset_name(project, tag, goos, goarch)
        if expected not in digests:
            sys.exit(
                f"{project['repo']}: release v{tag} is missing asset {expected}; "
                "refusing to update the formula"
            )

    for goos, goarch in PLATFORMS:
        name = asset_name(project, tag, goos, goarch)
        url = f"https://github.com/{project['repo']}/releases/download/v{tag}/{name}"
        # The url line plus the sha256 line immediately following it. The
        # platform suffix before the closing quote makes the match unique.
        pattern = re.compile(
            r'url "https://github\.com/[^"]+/releases/download/[^"]+'
            + rf'-{goos}-{goarch}"\n\s+sha256 "[0-9a-f]{{64}}"'
        )
        text, n = pattern.subn(f'url "{url}"\n      sha256 "{digests[name]}"', text, count=1)
        if n != 1:
            sys.exit(f"{path}: could not locate the {goos}/{goarch} url+sha256 block")

    # bin.install source names embed the version only for versioned assets;
    # for unversioned ones, strip any legacy versioned names (one-time
    # transition from the old naming scheme).
    if project["versioned_asset"]:
        text = text.replace(f"{project['prefix']}-v{current}-", f"{project['prefix']}-v{tag}-")
    else:
        text = re.sub(
            rf'{re.escape(project["prefix"])}-v\d+(\.\d+)*-',
            f"{project['prefix']}-",
            text,
        )
    text = re.sub(r'^  version "[^"]+"$', f'  version "{tag}"', text, count=1, flags=re.M)
    text = strip_placeholder_disable(text)

    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)
    return describe_change(project["repo"], current, tag)


def main():
    changed = []
    for project in PROJECTS:
        result = update_formula(project)
        if isinstance(result, FormulaSkipped):
            print(result.message)
        elif result:
            print(result)
            changed.append(result)
        else:
            print(f"{project['repo']}: up-to-date")

    if github_output := os.environ.get("GITHUB_OUTPUT"):
        with open(github_output, "a", encoding="utf-8") as fh:
            fh.write(f"changed={'true' if changed else 'false'}\n")


if __name__ == "__main__":
    main()
