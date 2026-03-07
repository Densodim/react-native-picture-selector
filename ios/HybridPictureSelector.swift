import Foundation
import UIKit
import AVFoundation
import HXPhotoPicker
import NitroModules

// ─────────────────────────────────────────────────────────────────────────────
// HybridPictureSelector
//
// Main iOS implementation. Inherits from the nitrogen-generated
// HybridHybridPictureSelectorSpec_base and conforms to
// HybridHybridPictureSelectorSpec_protocol (together they form the
// HybridHybridPictureSelectorSpec typealias).
//
// Threading contract:
//   - Nitro calls openPicker / openCamera on the JS thread.
//   - All UIKit calls are dispatched to DispatchQueue.main.
//   - Async result mapping runs in a Swift Task (cooperative thread pool).
// ─────────────────────────────────────────────────────────────────────────────

final class HybridPictureSelector: HybridHybridPictureSelectorSpec_base, HybridHybridPictureSelectorSpec_protocol {

  // MARK: - Private state

  private struct PendingSession {
    let promise: Promise<[MediaAsset]>
    let options: PictureSelectorOptions
  }

  private var session: PendingSession?

  /// Strong reference prevents picker deallocation before delegate fires.
  private var activePicker: UIViewController?

  // MARK: - openPicker

  func openPicker(options: PictureSelectorOptions) -> Promise<[MediaAsset]> {
    let promise = Promise<[MediaAsset]>()

    DispatchQueue.main.async { [weak self] in
      guard let self else {
        promise.reject(withError: PictureSelectorError.unknown("openPicker: native module was deallocated"))
        return
      }

      if self.session != nil {
        promise.reject(withError: PictureSelectorError.unknown(
          "A picker or camera session is already active. Dismiss it before opening a new one."
        ))
        return
      }

      guard let topVC = self.topViewController() else {
        promise.reject(withError: PictureSelectorError.unknown(
          "No active UIViewController. Ensure the picker is called from a mounted component."
        ))
        return
      }

      self.session = PendingSession(promise: promise, options: options)

      let config = self.buildPickerConfig(from: options)
      let picker = PhotoPickerController(picker: config)
      picker.pickerDelegate = self

      self.activePicker = picker
      topVC.present(picker, animated: true)
    }

    return promise
  }

  // MARK: - openCamera

  func openCamera(options: PictureSelectorOptions) -> Promise<[MediaAsset]> {
    let promise = Promise<[MediaAsset]>()

    DispatchQueue.main.async { [weak self] in
      guard let self else {
        promise.reject(withError: PictureSelectorError.unknown("openCamera: native module was deallocated"))
        return
      }

      if self.session != nil {
        promise.reject(withError: PictureSelectorError.unknown(
          "A picker or camera session is already active. Dismiss it before opening a new one."
        ))
        return
      }

      guard let topVC = self.topViewController() else {
        promise.reject(withError: PictureSelectorError.unknown("No active UIViewController."))
        return
      }

      var cameraConfig = CameraConfiguration()
      if let maxDur = options.maxVideoDuration {
        cameraConfig.videoMaximumDuration = maxDur
      }

      let captureType: CameraController.CaptureType
      switch options.mediaType {
      case .video: captureType = .video
      case .all:   captureType = .all
      default:     captureType = .photo
      }

      let camera = CameraController(config: cameraConfig, type: captureType)
      camera.completion = { [weak self] result, _, _ in
        guard let self else {
          promise.reject(withError: PictureSelectorError.unknown("openCamera: native module was deallocated"))
          return
        }
        Task {
          do {
            let asset = try await self.mapCameraResult(result, compress: options.compress)
            promise.resolve(withResult: [asset])
          } catch {
            promise.reject(withError: error)
          }
        }
      }
      camera.cancelHandler = { _ in
        promise.reject(withError: PictureSelectorError.cancelled)
      }

      self.activePicker = camera
      topVC.present(camera, animated: true)
    }

    return promise
  }

  // MARK: - Config builder

  private func buildPickerConfig(from options: PictureSelectorOptions) -> PickerConfiguration {
    var config = PickerConfiguration()

    // Media type
    switch options.mediaType {
    case .video:
      config.selectOptions = [.video]
    case .all:
      config.selectOptions = [.photo, .video]
    default:
      config.selectOptions = [.photo]
    }

    // Selection limit
    config.maximumSelectedCount = Int(options.maxCount ?? 1)

    // In-picker camera button
    config.photoList.allowAddCamera = options.enableCamera ?? true

    // Video duration limits (Int in HXPhotoPicker)
    if let maxDur = options.maxVideoDuration {
      config.maximumSelectedVideoDuration = Int(maxDur)
    }
    if let minDur = options.minVideoDuration {
      config.minimumSelectedVideoDuration = Int(minDur)
    }

    // Editor / crop (only when maxCount == 1)
    let maxCount = Int(options.maxCount ?? 1)
    if let crop = options.crop, crop.enabled, maxCount == 1 {
      config.editorOptions = [.photo]
      var editorConfig = EditorConfiguration()

      if crop.circular == true {
        editorConfig.cropSize.isRoundCrop = true
      } else if crop.freeStyle == true {
        editorConfig.cropSize.isFixedRatio = false
      } else {
        let x = crop.ratioX ?? 1.0
        let y = crop.ratioY ?? 1.0
        editorConfig.cropSize.isFixedRatio = true
        editorConfig.cropSize.aspectRatio = .init(width: x, height: y)
      }
      config.editor = editorConfig
    }

    // Theme color
    if let hex = options.themeColor, let color = UIColor(hex: hex) {
      config.themeColor = color
    }

    return config
  }

  // MARK: - Result mapping

  private func mapResults(
    _ result: PickerResult,
    compress: CompressOptions?
  ) async throws -> [MediaAsset] {
    var mapped: [MediaAsset] = []
    for photoAsset in result.photoAssets {
      let asset = try await mapAsset(
        photoAsset,
        compress: compress,
        isOriginal: result.isOriginal
      )
      mapped.append(asset)
    }
    return mapped
  }

  private func mapAsset(
    _ photoAsset: PhotoAsset,
    compress: CompressOptions?,
    isOriginal: Bool
  ) async throws -> MediaAsset {
    let urlResult: AssetURLResult = try await withCheckedThrowingContinuation { cont in
      photoAsset.getURL(
        compression: buildCompression(from: compress)
      ) { result in
        switch result {
        case .success(let r): cont.resume(returning: r)
        case .failure(let e): cont.resume(throwing: e)
        }
      }
    }

    let wasEdited = photoAsset.editedResult != nil
    let finalUri  = urlResult.url.absoluteString
    let editedUri: String? = wasEdited ? finalUri : nil

    let size: CGSize = photoAsset.imageSize

    // HXPhotoPicker returns seconds; bridge spec expects ms.
    let durationMs: Double = (photoAsset.videoDuration ?? 0) * 1_000

    // AssetURLResult has no fileSize; read from disk.
    let fileSize: Double
    if let attrs = try? FileManager.default.attributesOfItem(atPath: urlResult.url.path),
       let bytes = attrs[.size] as? UInt64 {
      fileSize = Double(bytes)
    } else {
      fileSize = 0
    }

    let typeStr: String = (photoAsset.mediaType == .video) ? "video" : "image"

    return MediaAsset(
      uri:        finalUri,
      type:       typeStr,
      mimeType:   mimeType(for: urlResult.url),
      width:      Double(size.width),
      height:     Double(size.height),
      duration:   durationMs,
      fileName:   urlResult.url.lastPathComponent,
      fileSize:   fileSize,
      editedUri:  editedUri,
      isOriginal: isOriginal,
      bucketName: nil
    )
  }

  // MARK: - Camera result mapping

  private func mapCameraResult(
    _ result: CameraController.Result,
    compress: CompressOptions?
  ) async throws -> MediaAsset {
    switch result {
    case .image(let image):
      let quality = compress?.quality ?? 0.8
      guard let data = image.jpegData(compressionQuality: quality) else {
        throw PictureSelectorError.unknown("Failed to encode captured image")
      }
      let fileName = "camera_\(UUID().uuidString).jpg"
      let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
      try data.write(to: tempURL)
      let fileSize = Double(data.count)
      return MediaAsset(
        uri:        tempURL.absoluteString,
        type:       "image",
        mimeType:   "image/jpeg",
        width:      Double(image.size.width * image.scale),
        height:     Double(image.size.height * image.scale),
        duration:   0,
        fileName:   fileName,
        fileSize:   fileSize,
        editedUri:  nil,
        isOriginal: false,
        bucketName: nil
      )
    case .video(let url):
      let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
      let fileSize = Double((attrs?[.size] as? UInt64) ?? 0)
      let asset = AVURLAsset(url: url)
      let duration = CMTimeGetSeconds(asset.duration) * 1_000
      let tracks = asset.tracks(withMediaType: .video)
      let size = tracks.first?.naturalSize ?? .zero
      return MediaAsset(
        uri:        url.absoluteString,
        type:       "video",
        mimeType:   mimeType(for: url),
        width:      Double(size.width),
        height:     Double(size.height),
        duration:   duration,
        fileName:   url.lastPathComponent,
        fileSize:   fileSize,
        editedUri:  nil,
        isOriginal: false,
        bucketName: nil
      )
    }
  }

  // MARK: - Compression helper

  private func buildCompression(from options: CompressOptions?) -> PhotoAsset.Compression? {
    guard let opts = options, opts.enabled else { return nil }
    return PhotoAsset.Compression(
      imageCompressionQuality: opts.quality ?? 0.8
    )
  }

  // MARK: - Top view controller

  private func topViewController() -> UIViewController? {
    let windowScene = UIApplication.shared.connectedScenes
      .filter { $0.activationState == .foregroundActive }
      .compactMap { $0 as? UIWindowScene }
      .first

    guard let window = windowScene?.windows.first(where: { $0.isKeyWindow }) else {
      return nil
    }

    var top: UIViewController? = window.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }

  // MARK: - MIME type helper

  private func mimeType(for url: URL) -> String {
    switch url.pathExtension.lowercased() {
    case "jpg", "jpeg": return "image/jpeg"
    case "png":         return "image/png"
    case "gif":         return "image/gif"
    case "heic":        return "image/heic"
    case "heif":        return "image/heif"
    case "webp":        return "image/webp"
    case "mp4":         return "video/mp4"
    case "mov":         return "video/quicktime"
    case "m4v":         return "video/x-m4v"
    default:            return "application/octet-stream"
    }
  }
}

// MARK: - PhotoPickerControllerDelegate

extension HybridPictureSelector: PhotoPickerControllerDelegate {

  func pickerController(
    _ pickerController: PhotoPickerController,
    didFinishSelection result: PickerResult
  ) {
    let captured = session
    session = nil
    activePicker = nil

    pickerController.dismiss(animated: true) { [weak self] in
      guard let s = captured else { return }
      guard let self else {
        s.promise.reject(withError: PictureSelectorError.unknown("pickerController: native module was deallocated"))
        return
      }
      Task {
        do {
          let assets = try await self.mapResults(result, compress: s.options.compress)
          s.promise.resolve(withResult: assets)
        } catch {
          s.promise.reject(withError: error)
        }
      }
    }
  }

  func pickerController(didCancel pickerController: PhotoPickerController) {
    let captured = session
    session = nil
    activePicker = nil

    pickerController.dismiss(animated: true) {
      captured?.promise.reject(withError: PictureSelectorError.cancelled)
    }
  }
}

// MARK: - Error type

enum PictureSelectorError: Error, LocalizedError {
  case cancelled
  case permissionDenied
  case unknown(String)

  var errorDescription: String? {
    switch self {
    case .cancelled:          return "CANCELLED"
    case .permissionDenied:   return "PERMISSION_DENIED"
    case .unknown(let msg):   return "UNKNOWN: \(msg)"
    }
  }
}

// MARK: - Nitro registration helper

/// Called from NitroPictureSelectorOnLoad.mm at startup.
@_cdecl("NitroPictureSelectorMakeHybrid")
public func NitroPictureSelectorMakeHybrid() -> UnsafeMutableRawPointer {
  HybridPictureSelector().getCxxWrapper().toUnsafe()
}

// MARK: - UIColor hex initialiser

extension UIColor {
  convenience init?(hex: String) {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("#") { s = String(s.dropFirst()) }
    guard s.count == 6, let rgb = UInt64(s, radix: 16) else { return nil }
    self.init(
      red:   CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgb & 0x00FF00) >>  8) / 255.0,
      blue:  CGFloat( rgb & 0x0000FF        ) / 255.0,
      alpha: 1.0
    )
  }
}
