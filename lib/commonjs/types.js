"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
Object.defineProperty(exports, "MediaType", {
  enumerable: true,
  get: function () {
    return _PictureSelector.MediaType;
  }
});
Object.defineProperty(exports, "PickerTheme", {
  enumerable: true,
  get: function () {
    return _PictureSelector.PickerTheme;
  }
});
exports.toPickerError = toPickerError;
var _PictureSelector = require("./specs/PictureSelector.nitro");
// Re-export spec types for public consumption

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
function toPickerError(err) {
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