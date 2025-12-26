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
  version "1.0.9"

  # Use prebuilt binaries for faster installation
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.0.9/lgh-1.0.9-darwin-arm64"
      sha256 "a1c5b2560fc8c139c7a998adc44bcab76528bf4f140a589362f7284c6c986509"

      def install
        bin.install "lgh-1.0.9-darwin-arm64" => "lgh"
      end
    else
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.0.9/lgh-1.0.9-darwin-amd64"
      sha256 "c47ef6b8fec201e6da24cf2a4276cad6064740bf87eaf02461a1466019f48170"

      def install
        bin.install "lgh-1.0.9-darwin-amd64" => "lgh"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.0.9/lgh-1.0.9-linux-arm64"
      sha256 "ac64a5568f69bf26bd143169065b8b9ba4322342185ac5c6ceb300bf419c93e8"

      def install
        bin.install "lgh-1.0.9-linux-arm64" => "lgh"
      end
    else
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.0.9/lgh-1.0.9-linux-amd64"
      sha256 "190e55a6bf462c90c0ec6ca9f3d29dcb53f74a4221699fc8cf947cc0d28f52c7"

      def install
        bin.install "lgh-1.0.9-linux-amd64" => "lgh"
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
      To get started:
        1. Run 'lgh serve' to start the server
        2. In your project: 'lgh add . --push' (One-click setup!)
          - Or manually: 'lgh add .' then 'git push lgh HEAD'

      New in v1.0.4:
        - 'lgh repo status': Check connection state clearly
        - 'lgh remote use': Switch active remote easily
        - 'lgh clone': Simplified cloning
        - 'lgh doctor': Check system health

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
