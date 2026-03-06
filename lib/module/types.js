"use strict";

// Re-export spec types for public consumption

export { MediaType, PickerTheme } from './specs/PictureSelector.nitro';

// ─────────────────────────────────────────────────────────────────────────────
// Convenience aliases
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Errors thrown by openPicker / openCamera.
 *
 * code === 'CANCELLED'         — user dismissed the picker
 * code === 'PERMISSION_DENIED' — runtime permission not granted
 * code === 'UNKNOWN'           — any other native error
 */

/** Normalise a raw native error to a typed PickerError. */
export function toPickerError(err) {
  const base = err instanceof Error ? err : new Error(String(err));
  // Nitro serialises Kotlin exceptions as "<ClassName>: <message>", so the
  // raw code ("CANCELLED") never appears verbatim — match case-insensitively.
  const msg = (base.message ?? '').toLowerCase();
  let code = 'UNKNOWN';
  if (msg.includes('cancelled')) code = 'CANCELLED';else if (msg.includes('permission_denied') || msg.includes('permission denied')) code = 'PERMISSION_DENIED';
  return Object.assign(base, {
    code
  });
}
//# sourceMappingURL=types.js.map