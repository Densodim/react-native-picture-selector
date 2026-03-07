///
/// cpp-adapter.cpp
/// Entry point for the NitroPictureSelector shared library.
///
/// Defines JNI_OnLoad so that when Kotlin calls
///   System.loadLibrary("NitroPictureSelector")
/// the JVM invokes this function with the JavaVM*, which:
///   1. Initialises fbjni (facebook::jni::initialize)
///   2. Calls registerAllNatives() — which registers JNI methods and
///      inserts "PictureSelector" into Nitro's HybridObjectRegistry.
///
/// Without this entry point System.loadLibrary succeeds silently but
/// nothing ever gets registered, so every call to
///   NitroModules.createHybridObject("PictureSelector")
/// throws "It has not yet been registered in the HybridObjectRegistry".
///

#include <jni.h>
#include <fbjni/fbjni.h>
#include "NitroPictureSelectorOnLoad.hpp"

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
  return facebook::jni::initialize(vm, []() {
    margelo::nitro::pictureselector::registerAllNatives();
  });
}
