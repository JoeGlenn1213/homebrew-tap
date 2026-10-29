# JoeGlenn1213 Homebrew Tap

Homebrew tap for the [LGH](https://github.com/JoeGlenn1213/lgh) ecosystem — local-first Git hosting and CI/CD for AI agents.

**Supported platforms:** macOS (Intel & Apple Silicon) and Linux/Linuxbrew (amd64 & arm64).

## Usage

```bash
brew tap JoeGlenn1213/tap
brew install lgh         # LGH: local Git server (http://127.0.0.1:9418)
brew install actiond     # ActionD: local CI/CD engine listening to LGH events
brew install actiond-web # ActionD Web: static web console (available after release)
```

Or one-liner without tapping first:

```bash
brew install JoeGlenn1213/tap/lgh
brew install JoeGlenn1213/tap/actiond
```

## Quick start

```bash
lgh serve -d          # start the local Git server
actiond setup         # initialize ~/.localgithub/* and check dependencies
actiond start -d      # start the CI/CD daemon
open http://localhost:3000   # web console (install actiond-web for the UI)
```

## Services

Both `lgh` and `actiond` support `brew services`:

```bash
brew services start lgh      # runs lgh serve in background
brew services start actiond  # runs actiond start in background
```

## Formulae

| Formula | Version | Description |
|---|---|---|
| [lgh](Formula/lgh.rb) | 1.3.4 | Local Git Hub — turn a local directory into a Git server with events, MCP, and LAN sync |
| [actiond](Formula/actiond.rb) | 1.3.0 | Local CI/CD engine for AI agents — plugin execution, MCP server (22 tools), rollback |
| [actiond-web](Formula/actiond-web.rb) | 0.1.1* | Static web console for ActionD — live dashboard, SSE log streaming, failure diagnosis |

\* `actiond-web` v0.1.1 is not yet released; the formula is a placeholder that will work once the release workflow publishes the tarball.

Formulae download prebuilt binaries from GitHub Releases (Linux + macOS, amd64 + arm64). They are kept in sync with the latest releases automatically — [update-formulae.yml](.github/workflows/update-formulae.yml) checks every 6 hours (or on demand) and bumps versions/checksums from the release assets' official digests.
