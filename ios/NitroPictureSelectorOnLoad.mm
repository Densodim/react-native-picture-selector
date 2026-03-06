//
// NitroPictureSelectorOnLoad.mm
// Registers HybridPictureSelector with Nitro's HybridObjectRegistry.
//
// The +load method runs automatically when the ObjC runtime loads this class,
// before main() — guaranteeing the factory is available when JS calls
// NitroModules.createHybridObject("PictureSelector").
//

#import <Foundation/Foundation.h>
#import <NitroModules/HybridObjectRegistry.hpp>
#import "NitroPictureSelector-Swift-Cxx-Umbrella.hpp"
#import "HybridHybridPictureSelectorSpecSwift.hpp"

using namespace margelo::nitro;
using namespace margelo::pictureselector;
using namespace margelo::pictureselector::bridge::swift;

@interface NitroPictureSelectorOnLoad: NSObject
@end

@implementation NitroPictureSelectorOnLoad

+ (void)load {
  HybridObjectRegistry::registerHybridObjectConstructor(
    "PictureSelector",
    []() -> std::shared_ptr<HybridObject> {
      auto swiftPart = NitroPictureSelector::HybridPictureSelector();
      return swiftPart.getCxxWrapper().getCxxPart();
    }
  );
}

@end
