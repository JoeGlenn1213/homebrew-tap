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

  # Plugins are Python; git is used for checkouts; LGH is the event source.
  depends_on "git" => :recommended

  # Prebuilt binaries; built by .github/workflows/release.yml (CGO_ENABLED=0,
  # pure-Go SQLite) on tag pushes.
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.3.1/actiond-darwin-arm64"
      sha256 "4c73233b828a7eb68de7d9b16c367ed58a363ab73f962c64ce845eed173e9723"
    else
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.3.1/actiond-darwin-amd64"
      sha256 "db5a80e794d7694d6eb82e94e3937214c056ff6f9958c6287e254a783d039a72"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.3.1/actiond-linux-arm64"
      sha256 "ee4a0e7d6ce1beab3ab7970c2be5dbd2a46f1de0717e1f04973aa93daa4b16b4"
    else
      url "https://github.com/JoeGlenn1213/ActionD/releases/download/v1.3.1/actiond-linux-amd64"
      sha256 "79f17f58f5b8188bbc85bc70acb877500c0e50c74a85d0f9356d47a00e9a6a94"
    end
  end

  def install
    binary = if OS.mac?
      Hardware::CPU.arm? ? "actiond-darwin-arm64" : "actiond-darwin-amd64"
    else
      Hardware::CPU.arm? ? "actiond-linux-arm64" : "actiond-linux-amd64"
    end
    bin.install binary => "actiond"
  end

  service do
    run [opt_bin/"actiond", "start"]
    # A clean exit (for example, another instance is already running) must
    # not restart forever. Restart only after a non-zero exit.
    keep_alive successful_exit: false
    environment_variables PATH: std_service_path_env
    working_dir var
    log_path var/"log/actiond.log"
    error_log_path var/"log/actiond.log"
  end

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
