package com.margelo.pictureselector

import android.content.Context
import android.widget.ImageView
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.luck.picture.lib.engine.ImageEngine
import com.luck.picture.lib.utils.ActivityCompatHelper

/**
 * Glide-based ImageEngine required by PictureSelector for displaying
 * thumbnails in the gallery grid and album cover.
 */
class GlideEngine private constructor() : ImageEngine {

  override fun loadImage(context: Context, url: String, imageView: ImageView) {
    if (!ActivityCompatHelper.assertValidRequest(context)) return
    Glide.with(context)
      .load(url)
      .override(180, 180)
      .centerCrop()
      .into(imageView)
  }

  override fun loadImage(
    context: Context,
    imageView: ImageView,
    url: String,
    maxWidth: Int,
    maxHeight: Int,
  ) {
    if (!ActivityCompatHelper.assertValidRequest(context)) return
    Glide.with(context)
      .load(url)
      .override(maxWidth, maxHeight)
      .centerCrop()
      .into(imageView)
  }

  override fun loadAlbumCover(context: Context, url: String, imageView: ImageView) {
    if (!ActivityCompatHelper.assertValidRequest(context)) return
    Glide.with(context)
      .asBitmap()
      .load(url)
      .override(180, 180)
      .centerCrop()
      .sizeMultiplier(0.5f)
      .diskCacheStrategy(DiskCacheStrategy.ALL)
      .into(imageView)
  }

  override fun loadGridImage(context: Context, url: String, imageView: ImageView) {
    if (!ActivityCompatHelper.assertValidRequest(context)) return
    Glide.with(context)
      .load(url)
      .override(200, 200)
      .centerCrop()
      .diskCacheStrategy(DiskCacheStrategy.ALL)
      .into(imageView)
  }

  override fun pauseRequests(context: Context) {
    Glide.with(context).pauseRequests()
  }

  override fun resumeRequests(context: Context) {
    Glide.with(context).resumeRequests()
  }

  companion object {
    @Volatile
    private var instance: GlideEngine? = null

    @JvmStatic
    fun createGlideEngine(): GlideEngine =
      instance ?: synchronized(this) {
        instance ?: GlideEngine().also { instance = it }
      }
  }
}
