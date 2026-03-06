// Re-export spec types for public consumption
export type {
  MediaAsset,
  PictureSelectorOptions,
  CropOptions,
  CompressOptions,
} from './specs/PictureSelector.nitro'

export { MediaType, PickerTheme } from './specs/PictureSelector.nitro'

// ─────────────────────────────────────────────────────────────────────────────
// Convenience aliases
// ─────────────────────────────────────────────────────────────────────────────

export type PickerResult = import('./specs/PictureSelector.nitro').MediaAsset[]

/**
 * Errors thrown by openPicker / openCamera.
 *
 * code === 'CANCELLED'         — user dismissed the picker
 * code === 'PERMISSION_DENIED' — runtime permission not granted
 * code === 'UNKNOWN'           — any other native error
 */
export interface PickerError extends Error {
  code: 'CANCELLED' | 'PERMISSION_DENIED' | 'UNKNOWN'
}

/** Normalise a raw native error to a typed PickerError. */
export function toPickerError(err: unknown): PickerError {
  const base = err instanceof Error ? err : new Error(String(err))
  // Nitro serialises Kotlin exceptions as "<ClassName>: <message>", so the
  // raw code ("CANCELLED") never appears verbatim — match case-insensitively.
  const msg = (base.message ?? '').toLowerCase()

  let code: PickerError['code'] = 'UNKNOWN'
  if (msg.includes('cancelled')) code = 'CANCELLED'
  else if (msg.includes('permission_denied') || msg.includes('permission denied'))
    code = 'PERMISSION_DENIED'

  return Object.assign(base, { code }) as PickerError
}
