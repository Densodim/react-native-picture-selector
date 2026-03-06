"use strict";

import { useState, useCallback, useRef } from 'react';
import { PictureSelector } from './PictureSelector';
import { toPickerError } from './types';

// ─────────────────────────────────────────────────────────────────────────────
// Hook state shape
// ─────────────────────────────────────────────────────────────────────────────

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
export function usePictureSelector(defaultOptions) {
  const [state, setState] = useState({
    assets: [],
    loading: false,
    error: null
  });

  // Stable ref to avoid re-creating callbacks when defaultOptions changes
  const defaultOptionsRef = useRef(defaultOptions);
  defaultOptionsRef.current = defaultOptions;

  // ─── Shared runner ────────────────────────────────────────────────────────
  // Handles loading state, CANCELLED swallowing and error propagation for
  // both pick() and shoot() to avoid duplicating the try/catch/setState logic.
  const runPickerCall = useCallback(async (nativeFn, options) => {
    setState(s => ({
      ...s,
      loading: true,
      error: null
    }));
    try {
      const merged = {
        ...defaultOptionsRef.current,
        ...options
      };
      const results = await nativeFn(merged);
      setState({
        assets: results,
        loading: false,
        error: null
      });
      return results;
    } catch (err) {
      const pickerErr = toPickerError(err);
      // Do not surface CANCELLED as an error — just restore loading state
      if (pickerErr.code === 'CANCELLED') {
        setState(s => ({
          ...s,
          loading: false
        }));
        return [];
      }
      setState(s => ({
        ...s,
        loading: false,
        error: pickerErr
      }));
      throw pickerErr;
    }
  }, []);
  const pick = useCallback(options => runPickerCall(PictureSelector.openPicker, options), [runPickerCall]);
  const shoot = useCallback(options => runPickerCall(PictureSelector.openCamera, options), [runPickerCall]);
  const clear = useCallback(() => {
    setState({
      assets: [],
      loading: false,
      error: null
    });
  }, []);
  return {
    ...state,
    pick,
    shoot,
    clear
  };
}
//# sourceMappingURL=usePictureSelector.js.map