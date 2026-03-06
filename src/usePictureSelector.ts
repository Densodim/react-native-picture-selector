import { useState, useCallback, useRef } from 'react'
import { PictureSelector } from './PictureSelector'
import type { MediaAsset, PictureSelectorOptions, PickerError } from './types'

// ─────────────────────────────────────────────────────────────────────────────
// Hook state shape
// ─────────────────────────────────────────────────────────────────────────────

export interface PictureSelectorState {
  assets: MediaAsset[]
  loading: boolean
  error: PickerError | null
}

export interface PictureSelectorActions {
  /** Open gallery picker */
  pick: (options?: PictureSelectorOptions) => Promise<MediaAsset[]>
  /** Open camera */
  shoot: (options?: PictureSelectorOptions) => Promise<MediaAsset[]>
  /** Clear selected assets and error state */
  clear: () => void
}

export type UsePictureSelectorReturn = PictureSelectorState &
  PictureSelectorActions

// ─────────────────────────────────────────────────────────────────────────────
// Hook
// ─────────────────────────────────────────────────────────────────────────────

/**
 * React hook that manages picker state.
 *
 * @example
 * const { assets, loading, pick, shoot, clear } = usePictureSelector({ maxCount: 9 })
 *
 * <Button onPress={() => pick()} title="Pick Photos" />
 * {assets.map(a => <Image source={{ uri: a.uri }} />)}
 */
export function usePictureSelector(
  defaultOptions?: PictureSelectorOptions
): UsePictureSelectorReturn {
  const [state, setState] = useState<PictureSelectorState>({
    assets: [],
    loading: false,
    error: null,
  })

  // Stable ref to avoid re-creating callbacks when defaultOptions changes
  const defaultOptionsRef = useRef(defaultOptions)
  defaultOptionsRef.current = defaultOptions

  // ─── Shared runner ────────────────────────────────────────────────────────
  // Handles loading state, CANCELLED swallowing and error propagation for
  // both pick() and shoot() to avoid duplicating the try/catch/setState logic.
  const runPickerCall = useCallback(
    async (
      nativeFn: (opts: PictureSelectorOptions) => Promise<MediaAsset[]>,
      options?: PictureSelectorOptions
    ): Promise<MediaAsset[]> => {
      setState((s) => ({ ...s, loading: true, error: null }))
      try {
        const merged = { ...defaultOptionsRef.current, ...options }
        const results = await nativeFn(merged)
        setState({ assets: results, loading: false, error: null })
        return results
      } catch (err) {
        const pickerErr = err as PickerError
        // Do not surface CANCELLED as an error — just restore loading state
        if (pickerErr.code === 'CANCELLED') {
          setState((s) => ({ ...s, loading: false }))
          return []
        }
        setState((s) => ({ ...s, loading: false, error: pickerErr }))
        throw pickerErr
      }
    },
    []
  )

  const pick = useCallback(
    (options?: PictureSelectorOptions) =>
      runPickerCall(PictureSelector.openPicker, options),
    [runPickerCall]
  )

  const shoot = useCallback(
    (options?: PictureSelectorOptions) =>
      runPickerCall(PictureSelector.openCamera, options),
    [runPickerCall]
  )

  const clear = useCallback(() => {
    setState({ assets: [], loading: false, error: null })
  }, [])

  return { ...state, pick, shoot, clear }
}
