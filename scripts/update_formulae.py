#!/usr/bin/env python3
"""Update Homebrew formulae from the latest GitHub releases.

For each configured project, compare the formula's version against the
latest published release; when they differ, rewrite the version line, the
per-platform url/sha256 pairs, and (for versioned asset names) the
bin.install source names, using the release assets' official digests.

Safety: if a release is missing ANY expected platform asset, the formula is
left untouched and the script exits non-zero — a partial formula is never
written.

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
]

PLATFORMS = [("darwin", "arm64"), ("darwin", "amd64"), ("linux", "arm64"), ("linux", "amd64")]


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


def update_formula(project):
    path = os.path.join(TAP_DIR, project["formula"])
    with open(path, encoding="utf-8") as fh:
        text = fh.read()

    version_match = re.search(r'^  version "([^"]+)"', text, re.M)
    if not version_match:
        sys.exit(f"{path}: no `version` line found")
    current = version_match.group(1)

    release = api(f"/repos/{project['repo']}/releases/latest")
    tag = release["tag_name"].lstrip("v")
    if tag == current:
        return None

    digests = {
        a["name"]: a["digest"].removeprefix("sha256:")
        for a in release["assets"]
        if a.get("digest")
    }
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

    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)
    return f"{project['repo']}: {current} -> {tag}"


def main():
    changed = []
    for project in PROJECTS:
        result = update_formula(project)
        print(result or f"{project['repo']}: up-to-date")
        if result:
            changed.append(result)

    if github_output := os.environ.get("GITHUB_OUTPUT"):
        with open(github_output, "a", encoding="utf-8") as fh:
            fh.write(f"changed={'true' if changed else 'false'}\n")


if __name__ == "__main__":
    main()
