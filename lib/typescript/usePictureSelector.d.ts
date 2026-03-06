import type { MediaAsset, PictureSelectorOptions, PickerError } from './types';
export interface PictureSelectorState {
    assets: MediaAsset[];
    loading: boolean;
    error: PickerError | null;
}
export interface PictureSelectorActions {
    /** Open gallery picker */
    pick: (options?: PictureSelectorOptions) => Promise<MediaAsset[]>;
    /** Open camera */
    shoot: (options?: PictureSelectorOptions) => Promise<MediaAsset[]>;
    /** Clear selected assets and error state */
    clear: () => void;
}
export type UsePictureSelectorReturn = PictureSelectorState & PictureSelectorActions;
/**
 * React hook that manages picker state.
 *
 * @example
 * const { assets, loading, pick, shoot, clear } = usePictureSelector({ maxCount: 9 })
 *
 * <Button onPress={() => pick()} title="Pick Photos" />
 * {assets.map(a => <Image source={{ uri: a.uri }} />)}
 */
export declare function usePictureSelector(defaultOptions?: PictureSelectorOptions): UsePictureSelectorReturn;
//# sourceMappingURL=usePictureSelector.d.ts.map