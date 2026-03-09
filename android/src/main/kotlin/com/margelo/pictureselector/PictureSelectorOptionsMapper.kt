package com.margelo.pictureselector

import com.luck.picture.lib.config.SelectMimeType
import com.margelo.nitro.com.margelo.pictureselector.MediaType
import com.margelo.nitro.com.margelo.pictureselector.PictureSelectorOptions

/**
 * Maps the JS [PictureSelectorOptions] onto a PictureSelector v3
 * selection model.
 *
 * Note: [PictureSelectionModel] is the builder returned by
 * [PictureSelector.create(activity).openGallery()] /
 * [PictureSelector.create(activity).openCamera()].
 *
 * Video duration methods accept seconds in v3.11.2.
 */
object PictureSelectorOptionsMapper {

  /**
   * Apply gallery-specific options to the builder.
   * Called before .forResult().
   */
  @JvmStatic
  fun applyGallery(
    builder: com.luck.picture.lib.basic.PictureSelectionModel,
    options: PictureSelectorOptions,
  ) {
    applyCommon(builder, options)

    // Maximum items the user may select
    builder.setMaxSelectNum((options.maxCount ?: 1.0).toInt())

    // Show camera button inside gallery
    builder.isDisplayCamera(options.enableCamera ?: true)

    // Pre-selected assets: selectedAssets (file:// URIs) conversion to LocalMedia
    // is not yet implemented; skipped intentionally.
  }

  /**
   * Apply camera-specific options to the builder.
   */
  @JvmStatic
  fun applyCamera(
    builder: com.luck.picture.lib.basic.PictureSelectionCameraModel,
    options: PictureSelectorOptions,
  ) {
    applyCommonCamera(builder, options)
  }

  // ─── Shared options ──────────────────────────────────────────────────────

  private fun applyCommonCamera(
    builder: com.luck.picture.lib.basic.PictureSelectionCameraModel,
    options: PictureSelectorOptions,
  ) {
    options.maxVideoDuration?.let { sec ->
      builder.setSelectMaxDurationSecond(sec.toInt())
    }
    options.minVideoDuration?.let { sec ->
      builder.setSelectMinDurationSecond(sec.toInt())
    }

    val compress = options.compress
    if (compress != null && compress.enabled) {
      builder.setCompressEngine(LubanCompressEngine())
    }
  }

  private fun applyCommon(
    builder: com.luck.picture.lib.basic.PictureSelectionModel,
    options: PictureSelectorOptions,
  ) {
    // ── Video duration limits ─────────────────────────────────────────────
    options.maxVideoDuration?.let { sec ->
      builder.setSelectMaxDurationSecond(sec.toInt())
    }
    options.minVideoDuration?.let { sec ->
      builder.setSelectMinDurationSecond(sec.toInt())
    }

    // ── Crop engine ───────────────────────────────────────────────────────
    val crop = options.crop
    val maxCount = (options.maxCount ?: 1.0).toInt()
    if (crop != null && crop.enabled && maxCount == 1) {
      val freeStyle = crop.freeStyle ?: false
      val circular  = crop.circular  ?: false
      val ratioX    = (crop.ratioX   ?: 1.0).toFloat()
      val ratioY    = (crop.ratioY   ?: 1.0).toFloat()
      // Map 0–1 JS quality to 0–100 JPEG quality
      val quality   = (((options.compress?.quality ?: 0.8) * 100).toInt()).coerceIn(10, 100)

      builder.setCropEngine(UCropEngine(freeStyle, ratioX, ratioY, circular, quality))
    }

    // ── Compress engine ───────────────────────────────────────────────────
    val compress = options.compress
    if (compress != null && compress.enabled) {
      builder.setCompressEngine(LubanCompressEngine())
    }
  }

  /**
   * Convert a JS [MediaType] enum to the PictureSelector SelectMimeType constant.
   */
  @JvmStatic
  fun toSelectMimeType(mediaType: MediaType?): Int = when (mediaType) {
    MediaType.VIDEO -> SelectMimeType.ofVideo()
    MediaType.ALL   -> SelectMimeType.ofAll()
    else            -> SelectMimeType.ofImage()
  }
}
