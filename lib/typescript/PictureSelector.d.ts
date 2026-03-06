import type { MediaAsset, PictureSelectorOptions } from './types';
export declare const PictureSelector: {
    /**
     * Open the gallery picker.
     *
     * @example
     * const assets = await PictureSelector.openPicker({ maxCount: 9 })
     *
     * @throws PickerError with code CANCELLED when the user dismisses
     * @throws PickerError with code PERMISSION_DENIED on permission failure
     */
    openPicker(options?: PictureSelectorOptions): Promise<MediaAsset[]>;
    /**
     * Open the camera for capture.
     *
     * @example
     * const [asset] = await PictureSelector.openCamera({ mediaType: MediaType.VIDEO })
     *
     * @throws PickerError with code CANCELLED when the user dismisses
     */
    openCamera(options?: PictureSelectorOptions): Promise<MediaAsset[]>;
};
//# sourceMappingURL=PictureSelector.d.ts.map