///
/// cpp-adapter.cpp
/// Entry point for the NitroPictureSelector shared library.
///
/// Defines JNI_OnLoad so that when Kotlin calls
///   System.loadLibrary("NitroPictureSelector")
/// the JVM invokes this function with the JavaVM*, which:
///   1. Initialises fbjni (facebook::jni::initialize)
///   2. Calls registerAllNatives() — which registers JNI methods.
///   3. Registers "HybridPictureSelector" in Nitro's HybridObjectRegistry
///      so that NitroModules.createHybridObject("HybridPictureSelector")
///      resolves to the Kotlin HybridPictureSelector class.
///

#include <jni.h>
#include <fbjni/fbjni.h>
#include <NitroModules/HybridObjectRegistry.hpp>
#include "NitroPictureSelectorOnLoad.hpp"
#include "JHybridHybridPictureSelectorSpec.hpp"
#include "HybridHybridPictureSelectorSpec.hpp"

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
  return facebook::jni::initialize(vm, []() {
    // 1. Register JNI methods for all generated specs.
    margelo::nitro::pictureselector::registerAllNatives();

    // 2. Register the HybridObject factory in Nitro's HybridObjectRegistry.
    //    The autolinking block in the generated NitroPictureSelectorOnLoad.cpp
    //    is empty (nitrogen was run before autolinking was configured).
    //    Registration is done here manually using the TAG from the generated spec.
    margelo::nitro::HybridObjectRegistry::registerHybridObjectConstructor(
      "HybridPictureSelector",
      []() -> std::shared_ptr<margelo::nitro::HybridObject> {
        static const auto cls = facebook::jni::findClassStatic(
          "com/margelo/pictureselector/HybridPictureSelector"
        );
        static const auto ctor = cls->getConstructor<facebook::jni::JObject::javaobject()>();
        auto javaObject = cls->newObject(ctor);
        auto javaPart = facebook::jni::static_ref_cast<
          margelo::nitro::pictureselector::JHybridHybridPictureSelectorSpec::JavaPart
        >(javaObject);
        return std::make_shared<
          margelo::nitro::pictureselector::JHybridHybridPictureSelectorSpec
        >(javaPart);
      }
    );
  });
}
