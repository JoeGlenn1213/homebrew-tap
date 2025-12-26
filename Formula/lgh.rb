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
  version "1.0.6"

  # Use prebuilt binaries for faster installation
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.0.6/lgh-1.0.6-darwin-arm64"
      sha256 "24483eb2952562f4db27125d344473e98693c5da3cd97c1fde9bc2696a642d6d"

      def install
        bin.install "lgh-1.0.6-darwin-arm64" => "lgh"
      end
    else
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.0.6/lgh-1.0.6-darwin-amd64"
      sha256 "6b155f67624f4fc95a372cc8dc0bebd4203f9dac4e2078e69226f91a34c32f75"

      def install
        bin.install "lgh-1.0.6-darwin-amd64" => "lgh"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.0.6/lgh-1.0.6-linux-arm64"
      sha256 "0533a363560e6ffcdb189ceeab0bae6a0da29e5556e69da3ad9f08316326b045"

      def install
        bin.install "lgh-1.0.6-linux-arm64" => "lgh"
      end
    else
      url "https://github.com/JoeGlenn1213/lgh/releases/download/v1.0.6/lgh-1.0.6-linux-amd64"
      sha256 "4e082089cf4e3907acdf2bcac13f6f750c6ad3c390a927ad1a3d131c03ce01b0"

      def install
        bin.install "lgh-1.0.6-linux-amd64" => "lgh"
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
        1. Run 'lgh init' to set up the environment
        2. Run 'lgh serve' to start the HTTP server
        3. In your project, run 'lgh add .' to register it
        4. Push with 'git push lgh main'

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
