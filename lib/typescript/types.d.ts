export type { MediaAsset, PictureSelectorOptions, CropOptions, CompressOptions, } from './specs/PictureSelector.nitro';
export { MediaType, PickerTheme } from './specs/PictureSelector.nitro';
export type PickerResult = import('./specs/PictureSelector.nitro').MediaAsset[];
/**
 * Errors thrown by openPicker / openCamera.
 *
 * code === 'CANCELLED'         — user dismissed the picker
 * code === 'PERMISSION_DENIED' — runtime permission not granted
 * code === 'UNKNOWN'           — any other native error
 */
export interface PickerError extends Error {
    code: 'CANCELLED' | 'PERMISSION_DENIED' | 'UNKNOWN';
}
/** Normalise a raw native error to a typed PickerError. */
export declare function toPickerError(err: unknown): PickerError;
//# sourceMappingURL=types.d.ts.map