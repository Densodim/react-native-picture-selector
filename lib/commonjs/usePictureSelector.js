"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.usePictureSelector = usePictureSelector;
var _react = require("react");
var _PictureSelector = require("./PictureSelector");
var _types = require("./types");
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
function usePictureSelector(defaultOptions) {
  const [state, setState] = (0, _react.useState)({
    assets: [],
    loading: false,
    error: null
  });

  // Stable ref to avoid re-creating callbacks when defaultOptions changes
  const defaultOptionsRef = (0, _react.useRef)(defaultOptions);
  defaultOptionsRef.current = defaultOptions;

  // ─── Shared runner ────────────────────────────────────────────────────────
  // Handles loading state, CANCELLED swallowing and error propagation for
  // both pick() and shoot() to avoid duplicating the try/catch/setState logic.
  const runPickerCall = (0, _react.useCallback)(async (nativeFn, options) => {
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
      const pickerErr = (0, _types.toPickerError)(err);
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
  const pick = (0, _react.useCallback)(options => runPickerCall(_PictureSelector.PictureSelector.openPicker, options), [runPickerCall]);
  const shoot = (0, _react.useCallback)(options => runPickerCall(_PictureSelector.PictureSelector.openCamera, options), [runPickerCall]);
  const clear = (0, _react.useCallback)(() => {
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