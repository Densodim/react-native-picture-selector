package com.margelo.pictureselector

import com.luck.picture.lib.entity.LocalMedia
import com.margelo.nitro.com.margelo.pictureselector.MediaAsset
import java.io.File

/**
 * Maps PictureSelector [LocalMedia] results to the Nitro bridge [MediaAsset].
 *
 * Priority for the final URI:
 * 1. Compressed file path  (isCompressed && compressPath != null)
 * 2. Cropped file path     (isCut && cutPath != null)
 * 3. Real file path        (realPath != null)
 * 4. Fallback              (path — may be content:// URI)
 *
 * Field mapping verified against PictureSelector v3.11.2:
 * - LocalMedia.size       — file size in bytes (Long)
 * - LocalMedia.duration   — duration in milliseconds (Long)
 * - LocalMedia.parentFolderName — album/bucket display name (String)
 */
object MediaAssetMapper {

  @JvmStatic
  fun map(results: ArrayList<LocalMedia>): Array<MediaAsset> {
    return results.map { media -> mapOne(media) }.toTypedArray()
  }

  private fun mapOne(media: LocalMedia): MediaAsset {
    val finalPath = resolveFilePath(media)
    val finalUri  = if (finalPath.startsWith("content://")) finalPath
                    else "file://$finalPath"

    val editedPath: String? = if (media.isCut) finalUri else null

    val type     = if (media.mimeType?.startsWith("video") == true) "video" else "image"
    val fileName = File(finalPath).name.takeIf { it.isNotEmpty() } ?: "unknown"

    return MediaAsset(
      uri        = finalUri,
      type       = type,
      mimeType   = media.mimeType        ?: "image/jpeg",
      width      = media.width.toDouble(),
      height     = media.height.toDouble(),
      duration   = media.duration.toDouble(), // milliseconds
      fileName   = fileName,
      fileSize   = media.size.toDouble(),
      editedUri  = editedPath,
      isOriginal = null,
      bucketName = media.parentFolderName,
    )
  }

  private fun resolveFilePath(media: LocalMedia): String {
    if (media.isCompressed && !media.compressPath.isNullOrEmpty()) {
      return media.compressPath!!
    }
    if (media.isCut && !media.cutPath.isNullOrEmpty()) {
      return media.cutPath!!
    }
    if (!media.realPath.isNullOrEmpty()) {
      return media.realPath!!
    }
    return media.path ?: ""
  }
}
