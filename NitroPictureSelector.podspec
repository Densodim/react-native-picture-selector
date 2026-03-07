require "json"
load File.join(__dir__, 'nitrogen', 'generated', 'ios', 'NitroPictureSelector+autolinking.rb')

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name             = "NitroPictureSelector"
  s.version          = package["version"]
  s.summary          = package["description"]
  s.homepage         = package["homepage"] || "https://github.com/nicepkg/react-native-picture-selector"
  s.license          = { :type => "MIT" }
  s.author           = "react-native-picture-selector contributors"
  s.source           = { :git => "https://github.com/nicepkg/react-native-picture-selector.git", :tag => s.version.to_s }

  s.platforms        = { :ios => "13.0" }
  s.swift_version    = "5.9"
  s.requires_arc     = true

  # ── Sources ─────────────────────────────────────────────────────────────
  # Hand-written Swift/ObjC++ implementation lives in ios/.
  s.source_files = "ios/**/*.{h,m,mm,swift}"

  # ── Dependencies ─────────────────────────────────────────────────────────
  s.dependency "React-Core"

  # HXPhotoPicker v5 — Picker + Editor + Camera
  s.dependency "HXPhotoPicker", "~> 5.0.5"

  # ── Compiler flags ───────────────────────────────────────────────────────
  # HXPhotoPicker feature flags + Swift/C++ interop for Nitro.
  # CLANG_CXX_LANGUAGE_STANDARD and DEFINES_MODULE are merged in by add_nitrogen_files.
  s.pod_target_xcconfig = {
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS" =>
      "HXPICKER_ENABLE_CORE HXPICKER_ENABLE_PICKER HXPICKER_ENABLE_EDITOR HXPICKER_ENABLE_CAMERA",
  }

  # ── Nitrogen ─────────────────────────────────────────────────────────────
  # Adds nitrogen/generated/shared/**/* + nitrogen/generated/ios/**/* to source_files,
  # sets public/private headers, adds NitroModules dependency, merges C++20 xcconfig.
  add_nitrogen_files(s)
end
