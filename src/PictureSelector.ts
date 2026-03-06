import { NitroModules } from 'react-native-nitro-modules'
import type { HybridPictureSelector } from './specs/PictureSelector.nitro'
import type { MediaAsset, PictureSelectorOptions } from './types'
import { MediaType, toPickerError } from './types'

// ─────────────────────────────────────────────────────────────────────────────
// Lazy singleton — created once and reused across calls
// ─────────────────────────────────────────────────────────────────────────────

let _native: HybridPictureSelector | null = null

function getNative(): HybridPictureSelector {
  if (_native == null) {
    _native = NitroModules.createHybridObject<HybridPictureSelector>(
      'PictureSelector'
    )
  }
  return _native
}

// ─────────────────────────────────────────────────────────────────────────────
// Default options
// ─────────────────────────────────────────────────────────────────────────────

const defaultOptions: PictureSelectorOptions = {
  mediaType: MediaType.IMAGE,
  maxCount: 1,
  enableCamera: true,
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared native call helper
// ─────────────────────────────────────────────────────────────────────────────

async function callNative(
  method: 'openPicker' | 'openCamera',
  options: PictureSelectorOptions
): Promise<MediaAsset[]> {
  try {
    return await getNative()[method]({ ...defaultOptions, ...options })
  } catch (err) {
    throw toPickerError(err)
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Static API
// ─────────────────────────────────────────────────────────────────────────────

export const PictureSelector = {
  /**
   * Open the gallery picker.
   *
   * @example
   * const assets = await PictureSelector.openPicker({ maxCount: 9 })
   *
   * @throws PickerError with code CANCELLED when the user dismisses
   * @throws PickerError with code PERMISSION_DENIED on permission failure
   */
  openPicker(options: PictureSelectorOptions = {}): Promise<MediaAsset[]> {
    return callNative('openPicker', options)
  },

  /**
   * Open the camera for capture.
   *
   * @example
   * const [asset] = await PictureSelector.openCamera({ mediaType: MediaType.VIDEO })
   *
   * @throws PickerError with code CANCELLED when the user dismisses
   */
  openCamera(options: PictureSelectorOptions = {}): Promise<MediaAsset[]> {
    return callNative('openCamera', options)
  },
}
