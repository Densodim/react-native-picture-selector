require "json"
package = JSON.parse(File.read(File.join(__dir__, "..", "package.json")))

Pod::Spec.new do |s|
  s.name             = "NitroPictureSelector"
  s.version          = package["version"]
  s.summary          = package["description"]
  s.homepage         = package["repository"]["url"]
  s.license          = { :type => "MIT" }
  s.author           = "react-native-picture-selector contributors"

  s.platforms        = { :ios => "13.0" }
  s.swift_version    = "5.9"
  s.requires_arc     = true

  # ── Sources ─────────────────────────────────────────────────────────────
  # Include both our hand-written Swift and the nitrogen-generated bridge files.
  s.source_files = [
    "ios/**/*.{h,m,mm,swift}",
    "../nitrogen/generated/ios/**/*.{h,m,mm,swift,hpp,cpp}",
  ]

  # ── Dependencies ─────────────────────────────────────────────────────────
  s.dependency "React-Core"
  s.dependency "react-native-nitro-modules"

  # HXPhotoPicker v5 — default subspec includes Picker + Editor + Camera
  s.dependency "HXPhotoPicker", "~> 5.0.5"

  # ── Compiler flags ───────────────────────────────────────────────────────
  # Enable HXPhotoPicker conditional compilation flags
  # Enable Swift/C++ interop required by Nitro for zero-overhead calls
  s.pod_target_xcconfig = {
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS" =>
      "HXPICKER_ENABLE_CORE HXPICKER_ENABLE_PICKER HXPICKER_ENABLE_EDITOR HXPICKER_ENABLE_CAMERA",
    "OTHER_SWIFT_FLAGS" => "-enable-experimental-cxx-interop",
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++20",
  }
end
