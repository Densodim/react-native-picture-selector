package com.margelo.pictureselector

import android.net.Uri
import androidx.fragment.app.Fragment
import com.luck.picture.lib.engine.CropFileEngine
import com.yalantis.ucrop.UCrop

/**
 * uCrop integration for PictureSelector v3.
 *
 * PictureSelector calls [onStartCrop] when the user has selected an image
 * and crop is configured. We forward to UCrop and it calls back into
 * PictureSelector via the requestCode mechanism.
 */
class UCropEngine(
  private val freeStyle: Boolean,
  private val ratioX: Float,
  private val ratioY: Float,
  private val circular: Boolean,
  private val quality: Int,
) : CropFileEngine {

  override fun onStartCrop(
    fragment: Fragment,
    srcUri: Uri,
    destinationUri: Uri,
    dataSource: ArrayList<String>,
    requestCode: Int,
  ) {
    val options = UCrop.Options().apply {
      setCompressionQuality(quality)
      setHideBottomControls(false)
      setFreeStyleCropEnabled(freeStyle)
      if (circular) {
        setCircleDimmedLayer(true)
        setShowCropFrame(false)
        setShowCropGrid(false)
      }
    }

    val uCrop = UCrop.of<android.net.Uri>(srcUri, destinationUri)
      .withOptions(options)

    if (!freeStyle && !circular) {
      uCrop.withAspectRatio(ratioX, ratioY)
    }

    try {
      uCrop.start(fragment.requireContext(), fragment, requestCode)
    } catch (e: Exception) {
      throw PictureSelectorException(
        "UNKNOWN",
        "UCrop failed to start: ${e.message}"
      )
    }
  }
}
