//
// NitroPictureSelectorOnLoad.mm
// Registers HybridPictureSelector with Nitro's HybridObjectRegistry.
//
// The +load ObjC method runs before main(), guaranteeing the factory is
// available when JS calls NitroModules.createHybridObject("PictureSelector").
//
// We bridge to Swift via @_cdecl("NitroPictureSelectorMakeHybrid") to avoid
// ambiguous Swift class constructor syntax from C++.
//

#import <Foundation/Foundation.h>
#import <NitroModules/HybridObjectRegistry.hpp>
#import "NitroPictureSelector-Swift-Cxx-Umbrella.hpp"
#import "HybridHybridPictureSelectorSpecSwift.hpp"

// Defined in HybridPictureSelector.swift via @_cdecl.
// Creates a HybridPictureSelector instance and returns a retained raw pointer
// to its HybridHybridPictureSelectorSpec_cxx wrapper.
extern "C" void* NitroPictureSelectorMakeHybrid() noexcept;

using namespace margelo::nitro;
using namespace margelo::nitro::pictureselector;
using namespace margelo::nitro::pictureselector::bridge::swift;

@interface NitroPictureSelectorOnLoad: NSObject
@end

@implementation NitroPictureSelectorOnLoad

+ (void)load {
  HybridObjectRegistry::registerHybridObjectConstructor(
    "PictureSelector",
    []() -> std::shared_ptr<HybridObject> {
      void* ptr = NitroPictureSelectorMakeHybrid();
      return create_std__shared_ptr_HybridHybridPictureSelectorSpec_(ptr);
    }
  );
}

@end
