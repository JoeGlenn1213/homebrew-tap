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
  version "1.2.1"

  # Prebuilt binaries; built by .github/workflows/release.yml (CGO_ENABLED=0,
  # pure-Go SQLite) on tag pushes.
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.2.1/actiond-darwin-arm64"
      sha256 "0e1bd91de9b9d3c513d83124b1d1cc7b7f958b31387a92f2d8c0bc83ee096cd5"

      def install
        bin.install "actiond-darwin-arm64" => "actiond"
      end
    else
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.2.1/actiond-darwin-amd64"
      sha256 "0cc32dd8128048c92138805b2fd2fe238ec94048dd3e9699d12c9e836dc75f43"

      def install
        bin.install "actiond-darwin-amd64" => "actiond"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.2.1/actiond-linux-arm64"
      sha256 "c62d2dd009aafb64cc74d4558221e868d2cdb922999142e7942fcf636a0d96d1"

      def install
        bin.install "actiond-linux-arm64" => "actiond"
      end
    else
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.2.1/actiond-linux-amd64"
      sha256 "1711c290183fcaf571d2839325bcd61d15213667e6e0858faaadc6f69aacceda"

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
        - 'actiond mcp' starts the MCP server (23 tools, incl. dev_cycle_run)
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
