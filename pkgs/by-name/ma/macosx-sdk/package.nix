{ lib, stdenv, fetchurl, mold-macho, xcbuild }:

stdenv.mkDerivation rec {
  pname = "macosx-sdk";
  version = "27.0.0";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/opendarwin-project/src/main/overlay/sys-devel/macosx-sdk/macosx-sdk-27.0.ebuild";
    sha256 = "3661c0a3721898bf979ed48dbefc8cb0542e5c03ffa28387753c7c980efda9af";
  };

  buildInputs = [ mold-macho xcbuild ];

  buildCommand = ''
    plat_dir="$out/Platforms/MacOSX.platform"
    sdk_name="MacOSX14.0.sdk"
    sdk_dir="$plat_dir/Developer/SDKs/$sdk_name"
    tc_dir="$out/Toolchains/XcodeDefault.xctoolchain"

    mkdir -p "$plat_dir" "$sdk_dir" "$tc_dir/usr/bin" "$plat_dir/Developer/SDKs"

    cat << 'EOF' > "$plat_dir/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Identifier</key>
  <string>com.apple.platform.macosx</string>
  <key>Name</key>
  <string>macosx</string>
  <key>Type</key>
  <string>Platform</string>
  <key>Version</key>
  <string>1</string>
  <key>FamilyIdentifier</key>
  <string>com.apple.platform.macosx</string>
  <key>FamilyName</key>
  <string>macOS</string>
  <key>MinimumSDKVersion</key>
  <string>14.0</string>
  <key>IsDeploymentPlatform</key>
  <true/>
</dict>
</plist>
EOF

    cat << 'EOF' > "$sdk_dir/SDKSettings.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CanonicalName</key>
  <string>macosx14.0</string>
  <key>Aliases</key>
  <array>
    <string>macosx</string>
    <string>macosx.internal</string>
    <string>macosx14.0</string>
    <string>macosx14.0.internal</string>
  </array>
  <key>DisplayName</key>
  <string>macOS 14.0</string>
  <key>Version</key>
  <string>14.0</string>
  <key>IsBaseSDK</key>
  <true/>
  <key>DefaultDeploymentTarget</key>
  <string>14.0</string>
  <key>MaximumDeploymentTarget</key>
  <string>14.0.99</string>
  <key>DefaultProperties</key>
  <dict>
    <key>PLATFORM_NAME</key>
    <string>macosx</string>
    <key>ARCHS</key>
    <string>arm64</string>
    <key>VALID_ARCHS</key>
    <string>arm64 x86_64</string>
  </dict>
</dict>
</plist>
EOF

    ln -sf "$sdk_name" "$plat_dir/Developer/SDKs/MacOSX.sdk"
    ln -sf "$sdk_name" "$plat_dir/Developer/SDKs/MacOSX.internal.sdk"
    ln -sf "$sdk_name" "$plat_dir/Developer/SDKs/MacOSX14.0.internal.sdk"

    cat << 'EOF' > "$tc_dir/ToolchainInfo.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Identifier</key>
  <string>com.apple.dt.toolchain.XcodeDefault</string>
  <key>DisplayName</key>
  <string>Open Darwin LLVM Toolchain</string>
  <key>Version</key>
  <string>1.0</string>
</dict>
</plist>
EOF

    for tool in clang clang++ ld64.mold llvm-ar llvm-ranlib llvm-nm llvm-strip llvm-lipo llvm-otool llvm-install-name-tool llvm-libtool-darwin dsymutil; do
      if command -v "$tool" >/dev/null 2>&1; then
        ln -sf "$(command -v $tool)" "$tc_dir/usr/bin/$tool"
      fi
    done
  '';

  meta = {
    description = "Open-source Xcode-compatible xcrun SDK and LLVM+mold toolchain layout";
    homepage = "https://github.com/facebookarchive/xcbuild";
    license = "MIT";
  };
}
