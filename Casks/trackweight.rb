cask "trackweight" do
  version "1.0.3"
  sha256 :no_check # built from source — checksum indeterminable ahead of build

  desc "Turn your MacBook's trackpad into a precise digital weighing scale"
  homepage "https://github.com/krishkrosh/TrackWeight"
  url "https://github.com/krishkrosh/TrackWeight.git",
      branch:   "main",
      using:    :git

  name "TrackWeight"

  # Hardware prerequisites
  depends_on macos: ">= :ventura"   # macOS 13 or newer
  depends_on arch:  :arm64          # Force‑Touch trackpad availability

  # ────────────────────────────────────────────────────────────
  # Build the .app from source during cask installation
  # ────────────────────────────────────────────────────────────
  preflight do
    require "fileutils"

    Dir.chdir(staged_path) do
      # Check if Xcode is properly installed
      xcode_path = `/usr/bin/xcode-select -p`.strip
      unless File.exist?("#{xcode_path}/usr/bin/xcodebuild")
        odie <<~EOS
          TrackWeight requires Xcode (not just Command Line Tools) to build from source.

          Please install Xcode from the Mac App Store, then run:
            sudo xcode-select -s /Applications/Xcode.app/Contents/Developer 
        EOS
      end

      # 1. Create an ad‑hoc entitlements plist that disables the macOS App Sandbox
      entitlements_path = "#{staged_path}/TrackWeight.entitlements"
      File.write(entitlements_path, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>com.apple.security.app-sandbox</key>
          <false/>
        </dict>
        </plist>
      XML

      # 2. Build the project
      build_args = [
        "xcodebuild",
        "-project", "TrackWeight.xcodeproj",
        "-scheme", "TrackWeight",
        "-configuration", "Release",
        "-derivedDataPath", "build",
        "-IDEPackageSupportDisableManifestSandbox=YES",
        "-IDEPackageSupportDisablePluginExecutionSandbox=YES",
        "OTHER_SWIFT_FLAGS=$(inherited) -disable-sandbox",
        "CODE_SIGN_IDENTITY=-",
        "CODE_SIGNING_REQUIRED=NO",
        "CODE_SIGNING_ALLOWED=NO",
        "OTHER_CODE_SIGN_FLAGS=--entitlements=#{entitlements_path}",
        "build"
      ]

      # Execute build with proper error handling
      unless system(*build_args, out: File::NULL, err: File::NULL)
        odie <<~EOS
          Failed to build TrackWeight from source.

          This could be due to:
          • Missing Xcode installation
          • Outdated Xcode version
          • Build environment issues

          Please try:
          1. Update Xcode from Mac App Store
          2. Run: sudo xcode-select --install
          3. Or download pre-built version from: https://github.com/krishkrosh/TrackWeight/releases
        EOS
      end

      # 3. Verify the build output exists
      built_app_path = "build/Build/Products/Release/TrackWeight.app"
      unless File.exist?(built_app_path)
        odie "Build completed but TrackWeight.app not found at expected location: #{built_app_path}"
      end

      # 4. Copy the built app to staging directory
      FileUtils.cp_r built_app_path, staged_path

      # 5. Verify the copy succeeded
      unless File.exist?("#{staged_path}/TrackWeight.app")
        odie "Failed to copy TrackWeight.app to staging directory"
      end
    end
  end

  app "TrackWeight.app"
  binary "#{appdir}/TrackWeight.app/Contents/MacOS/TrackWeight", target: "trackweight"

  # Refresh Launch Services to ensure icon appears
  postflight do
    system_command "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
                   args: ["-f", "#{appdir}/TrackWeight.app"],
                   sudo: false
  end

  # Clean‑up leftovers if the user later runs `brew uninstall --zap trackweight`
  zap trash: [
    "~/Library/Application Support/TrackWeight",
    "~/Library/Preferences/com.krishkrosh.TrackWeight.plist",
    "~/Library/Saved Application State/com.krishkrosh.TrackWeight.savedState",
  ]
end