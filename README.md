# JoeGlenn1213 Homebrew Tap

Homebrew tap for the [LGH](https://github.com/JoeGlenn1213/lgh) ecosystem — local-first Git hosting and CI/CD for AI agents.

## Usage

```bash
brew tap JoeGlenn1213/tap
brew install lgh       # LGH: local Git server (http://127.0.0.1:9418)
brew install actiond   # ActionD: local CI/CD engine listening to LGH events
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

## Formulae

| Formula | Version | Description |
|---|---|---|
| [lgh](Formula/lgh.rb) | 1.3.1 | Local Git Hub — turn a local directory into a Git server with events, MCP, and LAN sync |
| [actiond](Formula/actiond.rb) | 1.2.1 | Local CI/CD engine for AI agents — plugin execution, MCP server (23 tools), rollback |

Formulae download prebuilt binaries from GitHub Releases (linux + macOS, amd64 + arm64).
