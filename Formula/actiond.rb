# Copyright (c) 2025 JoeGlenn1213
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# ActionD Homebrew Formula
# To use: brew tap JoeGlenn1213/tap && brew install actiond

class Actiond < Formula
  desc "Local CI/CD engine for AI agents - event-driven plugin execution on LGH"
  homepage "https://github.com/JoeGlenn1213/ActionD"
  license "MIT"
  version "1.3.0"

  # Prebuilt binaries; built by .github/workflows/release.yml (CGO_ENABLED=0,
  # pure-Go SQLite) on tag pushes.
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.3.0/actiond-darwin-arm64"
      sha256 "75e8944ff02683b8852363c6eb06678dd78563fbb9753ba94d74fc5d8a4a2b1c"

      def install
        bin.install "actiond-darwin-arm64" => "actiond"
      end
    else
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.3.0/actiond-darwin-amd64"
      sha256 "ad0fbd750794f85e6243a415946b7307bf3c359be1eb6a3fa3f92f82e3e2bbec"

      def install
        bin.install "actiond-darwin-amd64" => "actiond"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.3.0/actiond-linux-arm64"
      sha256 "d1eac840f6c67c7ff57d7063e963e8992faa5193bbd110dc093c0a15ab0d0d9f"

      def install
        bin.install "actiond-linux-arm64" => "actiond"
      end
    else
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.3.0/actiond-linux-amd64"
      sha256 "fa2a8d5ad6fa945a8f841fde85ef0d458771dfbb804c7f9b072fede989616b2c"

      def install
        bin.install "actiond-linux-amd64" => "actiond"
      end
    end
  end

  # Plugins are Python; git is used for checkouts; LGH is the event source.
  depends_on "git" => :recommended

  def caveats
    <<~EOS
      ActionD - Local CI/CD engine for AI agents (part of the LGH ecosystem)

      Prerequisite: LGH must be running (ActionD listens to its git events)
        brew install JoeGlenn1213/tap/lgh
        lgh serve -d

      To get started:
        1. Run 'actiond setup' to initialize ~/.localgithub/* and check deps
        2. Run 'actiond start -d' to launch the daemon
        3. Open the web console at http://localhost:3000
        4. Run 'actiond doctor' any time to diagnose the environment

      AI agent integration:
        - 'actiond mcp' starts the MCP server (22 tools, incl. dev_cycle_run)
        - Set ACTIOND_MCP_ALLOW_LIFECYCLE=1 to allow start/stop over MCP
        - LGH not on localhost:9418? Set ACTIOND_LGH_URL accordingly

      Runtime state lives in ~/.localgithub/ (SQLite, logs, plugins).
    EOS
  end

  test do
    assert_match "ActionD", shell_output("#{bin}/actiond --help")
    assert_match version.to_s, shell_output("#{bin}/actiond version")
  end
end
