import type { HybridObject } from 'react-native-nitro-modules';
export declare enum MediaType {
    IMAGE = "image",
    VIDEO = "video",
    ALL = "all"
}
export declare enum PickerTheme {
    DEFAULT = "default",
    WECHAT = "wechat",
    WHITE = "white",
    DARK = "dark"
}
export interface CropOptions {
    /** Enable cropping after selection */
    enabled: boolean;
    /** Allow free-form aspect ratio. Default: false */
    freeStyle?: boolean;
    /** Circular crop mask. iOS-only. Default: false */
    circular?: boolean;
    /** Width part of the crop aspect ratio. Default: 1 */
    ratioX?: number;
    /** Height part of the crop aspect ratio. Default: 1 */
    ratioY?: number;
}
export interface CompressOptions {
    /** Enable compression */
    enabled: boolean;
    /** JPEG quality, 0.0–1.0. Default: 0.8 */
    quality?: number;
    /** Max output width in pixels. Default: 1920 */
    maxWidth?: number;
    /** Max output height in pixels. Default: 1920 */
    maxHeight?: number;
}
export interface PictureSelectorOptions {
    /** Media type to display. Default: IMAGE */
    mediaType?: MediaType;
    /** Maximum number of selectable items. Default: 1 */
    maxCount?: number;
    /** Show camera button inside the picker. Default: true */
    enableCamera?: boolean;
    /** Crop configuration. Only applies when maxCount === 1 */
    crop?: CropOptions;
    /** Compression configuration */
    compress?: CompressOptions;
    /** Max video duration in seconds */
    maxVideoDuration?: number;
    /** Min video duration in seconds. Default: 0 */
    minVideoDuration?: number;
    /** Picker UI theme */
    theme?: PickerTheme;
    /** Accent color as hex string, e.g. "#007AFF". iOS: themeColor; Android: accent */
    themeColor?: string;
    /** Pre-selected asset URIs (file:// URIs) */
    selectedAssets?: string[];
}
export interface MediaAsset {
    /** file:// URI of the final file (compressed or original) */
    uri: string;
    /** "image" | "video" */
    type: string;
    /** MIME type, e.g. "image/jpeg", "video/mp4" */
    mimeType: string;
    /** Width in pixels */
    width: number;
    /** Height in pixels */
    height: number;
    /** Duration in milliseconds (0 for images) */
    duration: number;
    /** Original filename with extension */
    fileName: string;
    /** File size in bytes */
    fileSize: number;
    /** file:// URI after crop or edit. Undefined if no edit was applied */
    editedUri?: string;
    /** iOS: true if user tapped "Original" quality button */
    isOriginal?: boolean;
    /** Android: album/bucket name the file belongs to */
    bucketName?: string;
}
export interface HybridPictureSelector extends HybridObject<{
    ios: 'swift';
    android: 'kotlin';
}> {
    /**
     * Open the photo/video gallery picker.
     * Rejects with message "CANCELLED" when the user dismisses without selection.
     */
    openPicker(options: PictureSelectorOptions): Promise<MediaAsset[]>;
    /**
     * Open the device camera for capture.
     * Rejects with message "CANCELLED" when the user dismisses.
     */
    openCamera(options: PictureSelectorOptions): Promise<MediaAsset[]>;
}
//# sourceMappingURL=PictureSelector.nitro.d.ts.map