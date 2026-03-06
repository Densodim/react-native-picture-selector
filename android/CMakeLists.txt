cmake_minimum_required(VERSION 3.22.1)
project(NitroPictureSelector)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Create empty shared library — sources are added by autolinking cmake below
add_library(${CMAKE_PROJECT_NAME} SHARED)

# Autolinking cmake handles: find_package, target_sources, target_link_libraries
include(${CMAKE_SOURCE_DIR}/../nitrogen/generated/android/NitroPictureSelector+autolinking.cmake)

# cpp-adapter.cpp defines JNI_OnLoad — the entry point called by the JVM when
# System.loadLibrary("NitroPictureSelector") is invoked from Kotlin.
# It calls facebook::jni::initialize(vm, ...) and then registerAllNatives(),
# which inserts "PictureSelector" into Nitro's HybridObjectRegistry.
# Without this file the library loads silently but nothing gets registered.
target_sources(${CMAKE_PROJECT_NAME} PRIVATE
  src/main/cpp/cpp-adapter.cpp
)

# Directly link libNitroModules.so from its stable cmake build output path.
# The prefab for react-native-nitro-modules is header-only at CMake configure
# time (fix-prefab.gradle updates it only after native build), so we link
# the .so directly to avoid undefined symbol errors on fresh builds.
#
# Use a generator expression so the correct variant (debug/release) is picked
# automatically — avoids breaking assembleRelease / EAS production builds.
string(TOLOWER "${CMAKE_BUILD_TYPE}" _build_type_lower)
if(_build_type_lower STREQUAL "release")
  set(NITRO_BUILD_VARIANT "release")
else()
  set(NITRO_BUILD_VARIANT "debug")
endif()

target_link_libraries(${CMAKE_PROJECT_NAME}
  ${CMAKE_SOURCE_DIR}/../../react-native-nitro-modules/android/build/intermediates/cmake/${NITRO_BUILD_VARIANT}/obj/${ANDROID_ABI}/libNitroModules.so
)
