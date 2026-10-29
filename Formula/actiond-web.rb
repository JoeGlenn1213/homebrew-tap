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

# ActionD Web Homebrew Formula
# To use: brew tap JoeGlenn1213/tap && brew install actiond-web

class ActiondWeb < Formula
  desc "Static web console for ActionD - live dashboard, SSE log streaming, failure diagnosis"
  homepage "https://github.com/JoeGlenn1213/actiond-web"
  license "MIT"
  version "0.1.1"

  # TODO: Replace placeholder sha256 once v0.1.1 release is published with tarball asset.
  # The release workflow (separate PR) will publish:
  #   https://github.com/JoeGlenn1213/actiond-web/releases/download/v0.1.1/actiond-web-0.1.1.tar.gz
  url "https://github.com/JoeGlenn1213/actiond-web/releases/download/v0.1.1/actiond-web-0.1.1.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  def install
    (share/"actiond-web/out").install Dir["*"]
  end

  def caveats
    <<~EOS
      ActionD Web - Static web console for ActionD

      The web console has been installed to:
        #{share}/actiond-web/out

      ActionD looks for the console in these locations (in order):
        1. ~/.localgithub/actiond-web/out
        2. The Homebrew share path above

      To create the symlink for automatic discovery:
        mkdir -p ~/.localgithub/actiond-web
        ln -s #{share}/actiond-web/out ~/.localgithub/actiond-web/out

      To use with ActionD:
        actiond start          # serves the console at http://localhost:3000
        # Or explicitly:
        actiond start --web-dir #{share}/actiond-web/out

      Requires ActionD to be installed and running:
        brew install JoeGlenn1213/tap/actiond
        actiond setup && actiond start -d
    EOS
  end

  test do
    assert_predicate share/"actiond-web/out", :directory?
  end
end
