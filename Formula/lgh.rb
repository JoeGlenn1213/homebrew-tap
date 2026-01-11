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
  version "1.2.2"

  # Use prebuilt binaries for faster installation
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.2.2/lgh-v1.2.2-darwin-arm64"
      sha256 "f5d96b5be685d7d36c40e10cc75f9caf9e71fc0b8852f1f5e521fed3a247fd5e"

      def install
        bin.install "lgh-v1.2.2-darwin-arm64" => "lgh"
      end
    else
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.2.2/lgh-v1.2.2-darwin-amd64"
      sha256 "ce094411253a044ace0c5601cd7c98e40b09e785683dc465f4527bc04ad4b049"

      def install
        bin.install "lgh-v1.2.2-darwin-amd64" => "lgh"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.2.2/lgh-v1.2.2-linux-arm64"
      sha256 "9e10a5c19888c3335d5ef5f2abf87bb85a8fa8e6cc861c55ae3bb94aaf438510"

      def install
        bin.install "lgh-v1.2.2-linux-arm64" => "lgh"
      end
    else
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.2.2/lgh-v1.2.2-linux-amd64"
      sha256 "dff0a9a4fea4a9ce6a5c700a2443d8db2047a68f8eb402a82c2f44db0c133959"

      def install
        bin.install "lgh-v1.2.2-linux-amd64" => "lgh"
      end
    end
  end

  # Runtime dependency only - git should already be installed on most systems
  # Using :recommended instead of required to avoid Xcode dependency issues
  depends_on "git" => :recommended

  def caveats
    <<~EOS
      LGH (LocalGitHub) - Lightweight local Git hosting service

      To get started:
        1. Run 'lgh serve' to start the server
        2. In your project: 'lgh up "initial commit"' (Smart Ignore enabled!)
          - Or manually: 'lgh add .' then 'git push lgh HEAD'

      New in v1.2.1:
        - "Smart Ignore": Auto-generate .gitignore for Py/Go/Node/AI projects
        - "Trash Detection": Prevents committing large files (>50MB) and secrets
        - "One-click Backup": 'lgh up' and 'lgh save' commands
        - "MCP Server": AI Agent integration

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
