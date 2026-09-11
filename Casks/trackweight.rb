cask "trackweight" do
  version :latest
  sha256 :no_check

  url "https://github.com/KrishKrosh/TrackWeight/releases/latest/download/TrackWeight.dmg"
  name "TrackWeight"
  desc "Turn your MacBook's trackpad into a precise digital weighing scale"
  homepage "https://github.com/krishkrosh/TrackWeight"

  livecheck do
    url :url
    strategy :github_latest
  end

  # Hardware prerequisites
  depends_on macos: :ventura # macOS 13 or newer

  app "TrackWeight.app"
  binary "#{appdir}/TrackWeight.app/Contents/MacOS/TrackWeight", target: "trackweight"

  # Clean‑up leftovers if the user later runs `brew uninstall --zap trackweight`
  zap trash: [
    "~/Library/Application Support/TrackWeight",
    "~/Library/Preferences/com.krishkrosh.TrackWeight.plist",
    "~/Library/Saved Application State/com.krishkrosh.TrackWeight.savedState",
  ]
end
