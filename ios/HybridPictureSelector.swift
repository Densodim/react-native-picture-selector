import Foundation
import UIKit
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
//
// API REQUIRES VERIFICATION:
//   - PhotoPickerControllerDelegate method signatures in HXPhotoPicker v5.0.5.
//   - PhotoAsset.getURL(compression:result:) callback API availability.
//   - PickerResult.photoAssets field name.
//   - PhotoAsset.mediaType enum values (.photo / .video).
//   - PhotoAsset.imageSize property name.
//   - PhotoAsset.videoDuration unit (seconds vs ms).
//   - AssetURLResult.fileSize field name / optionality.
//   - PhotoAsset.Compression type name and initialiser parameters.
//   - EditorConfiguration.Photo.CropSize.isRoundCrop property name.
// ─────────────────────────────────────────────────────────────────────────────

final class HybridPictureSelector: HybridHybridPictureSelectorSpec_base, HybridHybridPictureSelectorSpec_protocol {

  // MARK: - Private state

  /// Bundles the pending resolver together with the options so the delegate
  /// can perform compression-aware result mapping.
  private struct PendingSession {
    let resolver: (Result<[MediaAsset], Error>) -> Void
    let options: PictureSelectorOptions
  }

  private var session: PendingSession?

  /// Strong reference prevents picker deallocation before delegate fires.
  private var activePicker: UIViewController?

  // MARK: - openPicker

  func openPicker(options: PictureSelectorOptions) -> Promise<[MediaAsset]> {
    return Promise { [weak self] resolver in
      guard let self = self else {
        resolver.reject(PictureSelectorError.unknown("Instance deallocated"))
        return
      }

      DispatchQueue.main.async {
        guard let topVC = self.topViewController() else {
          resolver.reject(PictureSelectorError.unknown(
            "No active UIViewController. Ensure the picker is called from a mounted component."
          ))
          return
        }

        self.session = PendingSession(
          resolver: { result in
            switch result {
            case .success(let assets): resolver.resolve(assets)
            case .failure(let err):    resolver.reject(err)
            }
          },
          options: options
        )

        let config = self.buildPickerConfig(from: options)
        let picker = PhotoPickerController(picker: config)
        picker.pickerDelegate = self

        self.activePicker = picker
        topVC.present(picker, animated: true)
      }
    }
  }

  // MARK: - openCamera

  func openCamera(options: PictureSelectorOptions) -> Promise<[MediaAsset]> {
    return Promise { [weak self] resolver in
      guard let self = self else {
        resolver.reject(PictureSelectorError.unknown("Instance deallocated"))
        return
      }

      DispatchQueue.main.async {
        guard let topVC = self.topViewController() else {
          resolver.reject(PictureSelectorError.unknown("No active UIViewController."))
          return
        }

        var cameraConfig = CameraConfiguration()
        cameraConfig.mediaType = (options.mediaType == .video) ? .video : .photo
        if let maxDur = options.maxVideoDuration {
          cameraConfig.videoMaximumDuration = maxDur
        }

        // API REQUIRES VERIFICATION:
        // Photo.camera(_:fromViewController:completion:cancel:) method signature.
        // If this overload doesn't exist, use CameraController directly:
        //   let cam = CameraController(config: cameraConfig)
        //   cam.onCompletion = { ... }
        //   topVC.present(cam, animated: true)
        Photo.camera(
          cameraConfig,
          fromViewController: topVC
        ) { [weak self] result, _ in
          guard let self = self else { return }
          guard let photoAsset = result?.photoAsset else {
            resolver.reject(PictureSelectorError.cancelled)
            return
          }
          Task {
            do {
              let asset = try await self.mapAsset(
                photoAsset,
                compress: options.compress,
                isOriginal: false
              )
              resolver.resolve([asset])
            } catch {
              resolver.reject(error)
            }
          }
        } cancel: { _ in
          resolver.reject(PictureSelectorError.cancelled)
        }
      }
    }
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
    config.allowCustomCamera = options.enableCamera ?? true

    // Video duration limits
    if let maxDur = options.maxVideoDuration {
      config.maximumSelectedVideoDuration = maxDur
    }
    if let minDur = options.minVideoDuration {
      config.minimumSelectedVideoDuration = minDur
    }

    // Editor / crop  (only when maxCount == 1)
    let maxCount = Int(options.maxCount ?? 1)
    if let crop = options.crop, crop.enabled, maxCount == 1 {
      config.editorOptions = [.photo]
      var editorConfig = EditorConfiguration()

      var cropSizeConfig = EditorConfiguration.Photo.CropSize()
      if crop.circular == true {
        // API REQUIRES VERIFICATION: isRoundCrop property name in v5.0.5
        cropSizeConfig.isRoundCrop = true
      } else if crop.freeStyle == true {
        cropSizeConfig.aspectRatios = []   // empty array = free style
      } else {
        let x = crop.ratioX ?? 1.0
        let y = crop.ratioY ?? 1.0
        cropSizeConfig.aspectRatios = [
          .init(title: "", ratio: .init(width: x, height: y))
        ]
      }
      editorConfig.photo.cropSize = cropSizeConfig
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
    // Obtain file URL via callback, bridged to async/await.
    // API REQUIRES VERIFICATION: getURL(compression:result:) availability in v5.0.5.
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

    // Determine if the user applied edits
    let wasEdited = photoAsset.editedResult != nil
    let finalUri  = urlResult.url.absoluteString
    let editedUri: String? = wasEdited ? finalUri : nil

    // Image / video dimensions
    // API REQUIRES VERIFICATION: imageSize property name in v5.0.5
    let size: CGSize = photoAsset.imageSize

    // Duration: HXPhotoPicker returns seconds; bridge spec expects ms.
    // API REQUIRES VERIFICATION: videoDuration property name and unit.
    let durationMs: Double = (photoAsset.videoDuration ?? 0) * 1_000

    // File size
    // API REQUIRES VERIFICATION: AssetURLResult.fileSize field name.
    let fileSize: Double = Double(urlResult.fileSize ?? 0)

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

  // MARK: - Compression helper

  /// API REQUIRES VERIFICATION: PhotoAsset.Compression type name and init params in v5.0.5.
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
    // Capture and clear session atomically before dismiss completes
    let captured = session
    session = nil
    activePicker = nil

    pickerController.dismiss(animated: true) { [weak self] in
      guard let self = self, let s = captured else { return }
      Task {
        do {
          let assets = try await self.mapResults(result, compress: s.options.compress)
          s.resolver(.success(assets))
        } catch {
          s.resolver(.failure(error))
        }
      }
    }
  }

  func pickerController(didCancel pickerController: PhotoPickerController) {
    let captured = session
    session = nil
    activePicker = nil

    pickerController.dismiss(animated: true) {
      captured?.resolver(.failure(PictureSelectorError.cancelled))
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
/// Creates a HybridPictureSelector instance and returns a retained raw pointer
/// to its HybridHybridPictureSelectorSpec_cxx wrapper.
/// The caller (C++ factory) takes ownership via create_std__shared_ptr_HybridHybridPictureSelectorSpec_.
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
