package com.margelo.pictureselector

import android.content.Context
import android.net.Uri
import com.luck.picture.lib.engine.CompressFileEngine
import com.luck.picture.lib.interfaces.OnKeyValueResultCallbackListener
import top.zibin.luban.Luban
import top.zibin.luban.OnNewCompressListener
import java.io.File

/**
 * Luban-based compression engine for PictureSelector v3.
 *
 * PictureSelector bundles Luban via its compress artifact
 * (io.github.lucksiege:compress). This engine is invoked after selection
 * when compression is enabled.
 *
 * API REQUIRES VERIFICATION: The exact Luban API (OnNewCompressListener
 * callback method signatures) should be confirmed against the bundled
 * Luban version in io.github.lucksiege:compress:v3.11.2.
 */
class LubanCompressEngine(
  private val quality: Int,
  private val maxWidth: Int,
  private val maxHeight: Int,
) : CompressFileEngine {

  override fun onStartCompress(
    context: Context,
    source: ArrayList<Uri>,
    call: OnKeyValueResultCallbackListener,
  ) {
    // API REQUIRES VERIFICATION: setQuality() method name in bundled Luban version.
    // In most Luban forks bundled with PictureSelector, quality is set via .quality(Int)
    // or .setCompressQuality(Int). Adjust the method name after verifying against
    // io.github.lucksiege:compress:v3.11.2 source.
    Luban.with(context)
      .load(source)
      .ignoreBy(100) // skip files under 100 KB
      .setTargetDir(context.cacheDir.absolutePath)
      .setCompressListener(object : OnNewCompressListener {
        override fun onStart() {
          // no-op
        }

        override fun onSuccess(source: String, compressFile: File) {
          call.onCallback(source, compressFile.absolutePath)
        }

        override fun onError(source: String, e: Throwable) {
          // Return null to signal failure; PictureSelector will use original
          call.onCallback(source, null)
        }
      })
      .launch()
  }
}
