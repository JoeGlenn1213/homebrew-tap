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

# LGH Homebrew Formula
# To use: brew tap JoeGlenn1213/tap && brew install lgh

class Lgh < Formula
  desc "Lightweight local Git hosting service with authentication - LocalGitHub"
  homepage "https://github.com/JoeGlenn1213/lgh"
  license "MIT"

  # Runtime dependency only - git should already be installed on most systems
  # Using :recommended instead of required to avoid Xcode dependency issues
  depends_on "git" => :recommended

  # Use prebuilt binaries for faster installation
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.3.4/lgh-darwin-arm64"
      sha256 "4901342ddbe9b92587b7fc6353b43f6806bad0049c2ed6e4429cc93e0f28e5eb"
    else
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.3.4/lgh-darwin-amd64"
      sha256 "fb5aa1bdee6456a5ca85e8b6512123528ae12a8d68fdc173c21a5b36bd087ee1"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.3.4/lgh-linux-arm64"
      sha256 "4d337d5046c02f154922613ad86029db7c6c71e9c3f7b13060d06f5b67a42893"
    else
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.3.4/lgh-linux-amd64"
      sha256 "4ae5b542426d92494340bdc4f1500eb85d3428e78a4d09c0843d20a75f027ea3"
    end
  end

  def install
    binary = if OS.mac?
      Hardware::CPU.arm? ? "lgh-darwin-arm64" : "lgh-darwin-amd64"
    else
      Hardware::CPU.arm? ? "lgh-linux-arm64" : "lgh-linux-amd64"
    end
    bin.install binary => "lgh"
  end

  service do
    run [opt_bin/"lgh", "serve"]
    # A clean exit (for example, another instance is already running) must
    # not restart forever. Restart only after a non-zero exit.
    keep_alive successful_exit: false
    environment_variables PATH: std_service_path_env
    working_dir var
    log_path var/"log/lgh.log"
    error_log_path var/"log/lgh.log"
  end

  def caveats
    <<~EOS
      LGH (LocalGitHub) - Lightweight local Git hosting service

      To get started:
        1. Run 'lgh serve' to start the server
        2. In your project: 'lgh up "initial commit"' (Smart Ignore enabled!)
          - Or manually: 'lgh add .' then 'git push lgh HEAD'

      New in v1.3.x:
        - "Smart Ignore": Auto-generate .gitignore for Py/Go/Node/AI projects
        - "Trash Detection": Prevents committing large files (>50MB) and secrets
        - "One-click Backup": 'lgh up' and 'lgh save' commands
        - "MCP Server": AI Agent integration (SSE + streamable-http transports)

      For network sharing (with authentication):
        1. Run 'lgh auth setup' to configure username/password
        2. Run 'lgh serve --bind 0.0.0.0' to expose on network
        3. Clients use: git clone http://user:pass@host:9418/repo.git

      Data is stored in ~/.localgithub/
      Server runs on http://127.0.0.1:9418 by default

      Security tip: Always enable authentication when exposing to network!
    EOS
  end

  test do
    # Test version output
    assert_match "LGH (LocalGitHub) v#{version}", shell_output("#{bin}/lgh --version")

    # Test help command
    assert_match "LocalGitHub", shell_output("#{bin}/lgh --help")

    # Test auth command exists
    assert_match "auth", shell_output("#{bin}/lgh --help")
  end
end
