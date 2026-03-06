package com.margelo.pictureselector

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager
import com.margelo.nitro.com.margelo.pictureselector.NitroPictureSelectorOnLoad

/**
 * React Native Package that registers the Nitro HybridObject.
 *
 * For new architecture (Turbo Modules / Nitro): this package is discovered
 * automatically via autolinking when the consumer runs
 * `react-native link` or Gradle sync.
 *
 * Manual registration (legacy / non-autolink):
 * ```kotlin
 * // MainApplication.kt
 * override fun getPackages() = PackageList(this).packages + NitroPictureSelectorPackage()
 * ```
 *
 * API REQUIRES VERIFICATION:
 * - NitroModules.addHybridObjectCreator is the actual registration API in
 *   react-native-nitro-modules for Android. Verify against the installed
 *   version of the library. The creator name ("PictureSelector") must
 *   exactly match the string passed to NitroModules.createHybridObject()
 *   on the JS side.
 */
class NitroPictureSelectorPackage : ReactPackage {

  override fun createNativeModules(
    reactContext: ReactApplicationContext,
  ): List<NativeModule> {
    NitroPictureSelectorOnLoad.initializeNative()
    return emptyList()
  }

  override fun createViewManagers(
    reactContext: ReactApplicationContext,
  ): List<ViewManager<*, *>> = emptyList()
}
