# Homebrew formula for Undertitle (CLI + MCP server).
#
# This file belongs in a tap repo — create `cocodrino/homebrew-undertitle`
# and drop it at `Formula/undertitle.rb`. Users then run:
#
#     brew install cocodrino/undertitle/undertitle           # from the latest tagged release
#     brew install --HEAD cocodrino/undertitle/undertitle     # from main, right now
#
# Because Homebrew builds from source on the user's machine, the resulting
# binaries are NOT quarantined — no Gatekeeper "unverified" prompt.
class Undertitle < Formula
  desc "On-device .srt subtitle generator for macOS (CLI + MCP server)"
  homepage "https://github.com/cocodrino/undertitle"
  license "MIT"
  head "https://github.com/cocodrino/undertitle.git", branch: "main"

  # For a stable release, cut a tag that includes the SwiftPM package, then set:
  # url "https://github.com/cocodrino/undertitle/archive/refs/tags/vX.Y.Z.tar.gz"
  # sha256 "<shasum -a 256 of that tarball>"

  depends_on macos: :tahoe # macOS 26+
  depends_on xcode: ["26.0", :build]

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin.install ".build/release/undertitle"
    bin.install ".build/release/undertitle-mcp"
  end

  test do
    assert_match "USAGE", shell_output("#{bin}/undertitle --help")
  end
end
