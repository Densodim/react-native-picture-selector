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
 * Luban handles compression quality internally using an adaptive algorithm
 * based on image dimensions. Direct JPEG quality control is not supported
 * by this bundled version. Use [ignoreBy] to skip already-small files.
 */
class LubanCompressEngine : CompressFileEngine {

  override fun onStartCompress(
    context: Context,
    source: ArrayList<Uri>,
    call: OnKeyValueResultCallbackListener,
  ) {
    Luban.with(context)
      .load(source)
      .ignoreBy(100) // skip files already under 100 KB
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
